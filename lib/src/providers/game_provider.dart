 
import 'package:arcane/src/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:arcane/src/services/firebase_service.dart' as fb_service;
import 'package:arcane/src/services/storage_service.dart';
import 'package:arcane/src/utils/constants.dart';
import 'package:arcane/src/utils/helpers.dart' as helper;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'dart:convert'; // For jsonEncode
import 'package:flutter/material.dart'; // For TimeOfDay

import 'package:arcane/src/models/game_models.dart';

import 'actions/task_actions.dart';
import 'actions/ai_generation_actions.dart';
import 'actions/timer_actions.dart';
import 'package:arcane/src/services/ai_service.dart'; // For chatbot AI service

class GameProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final AIService _aiService = AIService();
  final NotificationService _notificationService = NotificationService();
  Timer? _periodicUiTimer;
  Timer? _debounceSaveTimer;
  StreamSubscription? _gameStateSubscription;

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool _authLoading = true;
  bool get authLoading => _authLoading;
  bool _isDataLoadingAfterLogin = false;
  bool get isDataLoadingAfterLogin => _isDataLoadingAfterLogin;
  bool _isUsernameMissing = false;
  bool get isUsernameMissing => _isUsernameMissing;

  String? _lastLoginDate;
  double _coins = 100;
  double _xp = 0;
  int _playerLevel = 1;
  double _playerEnergy = baseMaxPlayerEnergy;
  List<Project> _projects =
      initialProjectTemplates.map((t) => Project.fromTemplate(t)).toList();
  Map<String, dynamic> _completedByDay = {};
  List<String> _gameLog = [];
  List<Skill> _skills = [];

  GameSettings _settings = GameSettings();
  String? _selectedProjectId =
      initialProjectTemplates.isNotEmpty ? initialProjectTemplates[0].id : null;
  int _apiKeyIndex = 0;
  Map<String, ActiveTimerInfo> _activeTimers = {};

  bool _isManuallySaving = false;
  bool get isManuallySaving => _isManuallySaving;
  bool _isManuallyLoading = false;
  bool get isManuallyLoading => _isManuallyLoading;
  DateTime? _lastSuccessfulSaveTimestamp;
  DateTime? get lastSuccessfulSaveTimestamp => _lastSuccessfulSaveTimestamp;

  bool _isGeneratingGlobalContent = false;
  bool get isGeneratingContent => _isGeneratingGlobalContent;
  bool _isGeneratingSubquestsForTask = false;
  bool get isGeneratingSubquests => _isGeneratingSubquestsForTask;

  double _aiGenerationProgress = 0.0;
  double get aiGenerationProgress => _aiGenerationProgress;
  String _aiGenerationStatusMessage = "";
  String get aiGenerationStatusMessage => _aiGenerationStatusMessage;

  String? get lastLoginDate => _lastLoginDate;
  double get coins => _coins;
  double get xp => _xp;
  int get playerLevel => _playerLevel;
  double get playerEnergy => _playerEnergy;
  List<Project> get projects => _projects;
  Map<String, dynamic> get completedByDay => _completedByDay;
  List<String> get gameLog => _gameLog;
  List<Skill> get skills => _skills;

  GameSettings get settings => _settings;
  String? get selectedProjectId => _selectedProjectId;
  int get apiKeyIndex => _apiKeyIndex;
  Map<String, ActiveTimerInfo> get activeTimers => _activeTimers;

  double get calculatedMaxEnergy =>
      baseMaxPlayerEnergy + (_playerLevel - 1) * playerEnergyPerLevelVitality;
  double get xpNeededForNextLevel =>
      helper.xpToNext(_playerLevel, xpPerLevelBase, xpLevelMultiplier);
  double get currentLevelXPStart =>
      helper.xpForLevel(_playerLevel, xpPerLevelBase, xpLevelMultiplier);
  double get currentLevelXPProgress => _xp - currentLevelXPStart;
  double get xpProgressPercent => xpNeededForNextLevel > 0
      ? (currentLevelXPProgress / xpNeededForNextLevel).clamp(0.0, 1.0) * 100
      : 0;

  TimeOfDay get wakeupTime =>
      TimeOfDay(hour: _settings.wakeupTimeHour, minute: _settings.wakeupTimeMinute);

  ChatbotMemory _chatbotMemory = ChatbotMemory();
  ChatbotMemory get chatbotMemory => _chatbotMemory;
  bool _isChatbotMemoryInitialized = false;

  DateTime? _breakEndTime;
  DateTime? get breakEndTime => _breakEndTime;
  Timer? _breakTimer;
  int? _breakOriginalDurationMinutes;
  int? get breakOriginalDurationMinutes => _breakOriginalDurationMinutes;

  late final TaskActions _taskActions;
  late final AIGenerationActions _aiGenerationActions;
  late final TimerActions _timerActions;

  GameProvider() {
    _taskActions = TaskActions(this);
    _aiGenerationActions = AIGenerationActions(this);
    _timerActions = TimerActions(this);
    _initialize();
  }

  @override
  void dispose() {
    _periodicUiTimer?.cancel();
    _debounceSaveTimer?.cancel();
    _gameStateSubscription?.cancel();
    _breakTimer?.cancel();
    super.dispose();
  }

  void _initialize() {
    fb_service.authStateChanges.listen(_onAuthStateChanged);
    _periodicUiTimer?.cancel();
    _periodicUiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeTimers.values.any((info) => info.isRunning)) {
        notifyListeners();
      }
    });
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _authLoading = true;
    notifyListeners();

    _gameStateSubscription?.cancel();

    if (user != null) {
      _currentUser = user;
      _isDataLoadingAfterLogin = true;
      notifyListeners();

      _gameStateSubscription =
          _storageService.getUserDataStream(user.uid).listen((snapshot) {
        if (snapshot.metadata.hasPendingWrites) {
          return;
        }

        if (snapshot.exists) {
          _loadStateFromMap(snapshot.data()!);
          _handleDailyReset();
          _isChatbotMemoryInitialized = false;
          initializeChatbotMemory();
        } else {
          _resetToInitialState().then((_) async {
            _lastLoginDate = helper.getTodayDateString();
            await _performActualSave();
            _handleDailyReset();
            _isChatbotMemoryInitialized = false;
            initializeChatbotMemory();
          });
        }
        
        _isDataLoadingAfterLogin = false;
        _isUsernameMissing = (_currentUser?.displayName == null || _currentUser!.displayName!.trim().isEmpty);
        notifyListeners();
      }, onError: (error) {
         _isDataLoadingAfterLogin = false;
      });
    } else {
      _currentUser = null;
      await _resetToInitialState();
      _isDataLoadingAfterLogin = false;
      _isChatbotMemoryInitialized = false;
    }

    _authLoading = false;
    notifyListeners();
  }

  Map<String, dynamic> _gameStateToMap() {
    return {
      'lastLoginDate': _lastLoginDate,
      'coins': _coins,
      'xp': _xp,
      'playerLevel': _playerLevel,
      'playerEnergy': _playerEnergy,
      'projects': _projects.map((p) => p.toJson()).toList(),
      'completedByDay': _completedByDay,
      'gameLog': _gameLog,
      'skills': _skills.map((s) => s.toJson()).toList(),
      'settings': settings.toJson(),
      'selectedProjectId': _selectedProjectId,
      'apiKeyIndex': _apiKeyIndex,
      'activeTimers':
          _activeTimers.map((key, value) => MapEntry(key, value.toJson())),
      'lastSuccessfulSaveTimestamp':
          _lastSuccessfulSaveTimestamp?.toIso8601String(),
      'chatbotMemory': _chatbotMemory.toJson(),
    };
  }

  void _loadStateFromMap(Map<String, dynamic> data) {
    _lastLoginDate = data['lastLoginDate'] as String?;
    _coins = (data['coins'] as num? ?? 100).toDouble();
    _xp = (data['xp'] as num? ?? 0).toDouble();
    _playerLevel = data['playerLevel'] as int? ?? 1;
    _playerEnergy = (data['playerEnergy'] as num? ?? baseMaxPlayerEnergy).toDouble();

    // Legacy support for 'mainTasks'
    final projectsData = data['projects'] ?? data['mainTasks'];
    _projects = (projectsData as List<dynamic>?)
            ?.map((pJson) => Project.fromJson(pJson as Map<String, dynamic>))
            .toList() ??
        initialProjectTemplates.map((t) => Project.fromTemplate(t)).toList();

    _completedByDay = data['completedByDay'] as Map<String, dynamic>? ?? {};
    _gameLog = (data['gameLog'] as List<dynamic>?)?.map((entry) => entry as String).toList() ?? [];
    _skills = (data['skills'] as List<dynamic>?)?.map((sJson) => Skill.fromJson(sJson as Map<String, dynamic>)).toList() ?? [];
    _settings = data['settings'] != null ? GameSettings.fromJson(data['settings'] as Map<String, dynamic>) : GameSettings();

    // Legacy support for 'selectedTaskId'
    _selectedProjectId = data['selectedProjectId'] as String? ?? data['selectedTaskId'] as String? ?? (_projects.isNotEmpty ? _projects[0].id : null);
    _apiKeyIndex = data['apiKeyIndex'] as int? ?? 0;
    _activeTimers = (data['activeTimers'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, ActiveTimerInfo.fromJson(value as Map<String, dynamic>))) ?? {};

    final timestampString = data['lastSuccessfulSaveTimestamp'] as String?;
    _lastSuccessfulSaveTimestamp = timestampString != null ? DateTime.tryParse(timestampString) : null;
    _chatbotMemory = data['chatbotMemory'] != null ? ChatbotMemory.fromJson(data['chatbotMemory'] as Map<String, dynamic>) : ChatbotMemory();
    _isChatbotMemoryInitialized = true;

    _ensureSkillsList();
    _recalculatePlayerLevel();
  }

  Future<void> _resetToInitialState() async {
    _lastLoginDate = null;
    _coins = 100;
    _xp = 0;
    _playerLevel = 1;
    _playerEnergy = baseMaxPlayerEnergy;
    _projects = initialProjectTemplates.map((t) => Project.fromTemplate(t)).toList();
    _completedByDay = {};
    _gameLog = [];
    _skills = [];
    _settings = GameSettings();
    _selectedProjectId = _projects.isNotEmpty ? _projects[0].id : null;
    _apiKeyIndex = 0;
    _activeTimers = {};
    _isUsernameMissing = false;
    _lastSuccessfulSaveTimestamp = null;
    _chatbotMemory = ChatbotMemory();
    _isChatbotMemoryInitialized = true;
    _ensureSkillsList();
    _scheduleSave();
  }

  void _scheduleSave({bool immediate = false}) {
    if (_debounceSaveTimer?.isActive ?? false) _debounceSaveTimer!.cancel();
    final saveDuration = immediate ? Duration.zero : const Duration(milliseconds: 750);
    _debounceSaveTimer = Timer(saveDuration, _performActualSave);
  }

  Future<void> _performActualSave() async {
    if (_currentUser != null && !_isManuallySaving) {
      final success = await _storageService.setUserData(_currentUser!.uid, _gameStateToMap());
      if (success) {
        _lastSuccessfulSaveTimestamp = DateTime.now();
        notifyListeners();
      } else {
        setProviderState(
            gameLog: [
              ..._gameLog,
              "<span style=\"color:${helper.colorToHex(AppTheme.fnAccentRed)}\">Error: Failed to save to cloud!</span>"
            ],
            doNotify: true);
      }
    }
  }

  Future<void> manuallySaveToCloud() async {
    if (_currentUser == null) throw Exception("Not logged in.");
    _isManuallySaving = true;
    notifyListeners();
    try {
      await _performActualSave();
    } finally {
      _isManuallySaving = false;
      notifyListeners();
    }
  }

  Future<void> manuallyLoadFromCloud() async {
    if (_currentUser == null) throw Exception("Not logged in.");
    _isManuallyLoading = true;
    notifyListeners();
    try {
      final data = await _storageService.getUserData(_currentUser!.uid);
      if (data != null) {
        _loadStateFromMap(data);
        _handleDailyReset();
        _isUsernameMissing = (_currentUser?.displayName == null || _currentUser!.displayName!.trim().isEmpty);
        _isChatbotMemoryInitialized = false;
        initializeChatbotMemory();
      } else {
        throw Exception("No data found on cloud.");
      }
    } finally {
      _isManuallyLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginUser(String email, String password) async {
    await fb_service.signInWithEmail(email, password);
  }

  Future<void> signupUser(String email, String password, String username) async {
    _authLoading = true;
    notifyListeners();
    try {
      UserCredential userCredential = await fb_service.firebaseAuthInstance.createUserWithEmailAndPassword(email: email, password: password);
      _currentUser = userCredential.user;
      if (_currentUser != null) {
        await _currentUser!.updateDisplayName(username);
        await _currentUser!.reload();
        _currentUser = fb_service.firebaseAuthInstance.currentUser;
        await _resetToInitialState();
      } else {
        throw Exception("Signup successful but user object is null.");
      }
    } catch (e) {
      _currentUser = null;
      rethrow;
    } finally {
      _authLoading = false;
      notifyListeners();
    }
  }

  Future<void> logoutUser() async {
    await _performActualSave();
    await fb_service.signOut();
  }

  Future<void> changePasswordHandler(String newPassword) async {
    if (_currentUser != null) {
      await fb_service.changePassword(newPassword);
      _scheduleSave();
    } else {
      throw Exception("No user is currently signed in.");
    }
  }

  Future<void> updateUserDisplayName(String newUsername) async {
    if (_currentUser != null) {
      await _currentUser!.updateDisplayName(newUsername);
      await _currentUser!.reload();
      _currentUser = fb_service.firebaseAuthInstance.currentUser;
      _isUsernameMissing = false;
      _scheduleSave();
      notifyListeners();
    }
  }

  void setSelectedProjectId(String? projectId, {bool immediateSave = false}) {
    if (_selectedProjectId != projectId) {
      _selectedProjectId = projectId;
      _scheduleSave(immediate: immediateSave);
      notifyListeners();
    }
  }

  void setSettings(GameSettings newSettings) {
    _settings = newSettings;
    _scheduleSave();
    notifyListeners();
  }

  void completeTutorial() {
    _settings.tutorialShown = true;
    setSettings(_settings);
  }

  Project? getSelectedProject() {
    if (_selectedProjectId == null) return _projects.firstOrNull;
    return _projects.firstWhereOrNull((p) => p.id == _selectedProjectId) ?? _projects.firstOrNull;
  }

  void _recalculatePlayerLevel() {
    int newLevel = 1;
    double xpAtStartOfLvl = 0;
    while (true) {
      final double xpNeeded = helper.xpToNext(newLevel, xpPerLevelBase, xpLevelMultiplier);
      if (_xp >= xpAtStartOfLvl + xpNeeded) {
        xpAtStartOfLvl += xpNeeded;
        newLevel++;
      } else {
        break;
      }
    }
    if (_playerLevel != newLevel) {
      final oldLevel = _playerLevel;
      _playerLevel = newLevel;
      if (_playerLevel > oldLevel) {
        _handleLevelUpEffect();
      } else {
        _scheduleSave();
        notifyListeners();
      }
    }
  }

  void _handleLevelUpEffect() {
    if (_currentUser == null) return;
    _playerEnergy = calculatedMaxEnergy;
    _gameLog = [
      ..._gameLog,
      "<span style=\"color:#${helper.colorToHex(getSelectedProject()?.color ?? AppTheme.fortniteBlue)}\">Level up to $_playerLevel!</span>"
    ];
    _notificationService.showNotification('Level Up!', 'Congratulations! You reached level $_playerLevel.');
    _scheduleSave();
    notifyListeners();
  }

  String _generateSummaryForOlderDays() {
    if (_completedByDay.isEmpty) return "No activity logged before the last 7 days.";
    List<String> olderDaysSummaryLines = ["Summary of activity older than 7 days:"];
    int olderDaysActivityCount = 0;
    DateTime today = DateTime.now();
    List<String> sortedDates = _completedByDay.keys.toList()..sort();

    for (String dateString in sortedDates) {
      DateTime date = DateTime.parse(dateString);
      if (today.difference(date).inDays >= 7) {
        final dayData = _completedByDay[dateString] as Map<String, dynamic>;
        final taskTimes = dayData['taskTimes'] as Map<String, dynamic>? ?? {};
        int dailyTotalMinutes = taskTimes.values.fold<int>(0, (prev, time) => prev + (time as int));
        int dailySubtasks = (dayData['subtasksCompleted'] as List?)?.length ?? 0;
        int dailyCheckpoints = (dayData['checkpointsCompleted'] as List?)?.length ?? 0;
        int dailyEmotions = (dayData['emotionLogs'] as List?)?.length ?? 0;
        if (dailyTotalMinutes > 0 || dailySubtasks > 0 || dailyCheckpoints > 0 || dailyEmotions > 0) {
          olderDaysActivityCount++;
          String activityLine = "On $dateString: ${dailyTotalMinutes}m logged";
          if (dailySubtasks > 0) activityLine += ", $dailySubtasks tasks completed";
          if (dailyCheckpoints > 0) activityLine += ", $dailyCheckpoints checkpoints cleared";
          if (dailyEmotions > 0) activityLine += ", $dailyEmotions emotion logs";
          olderDaysSummaryLines.add("$activityLine.");
        }
      }
    }
    if (olderDaysActivityCount == 0) return "No significant activity logged before the last 7 days.";
    if (olderDaysSummaryLines.length > 21) return "${olderDaysSummaryLines.sublist(0, 21).join("\n")}\n... (older entries truncated)";
    return olderDaysSummaryLines.join("\n");
  }

  Future<void> _handleDailyReset() async {
    if (_currentUser == null) return;
    final today = helper.getTodayDateString();
    if (_lastLoginDate != today) {
      _projects = _projects.map((project) {
        int newStreak = project.streak;
        if (_lastLoginDate != null) {
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
          if (project.dailyTimeSpent < dailyTaskGoalMinutes &&
              project.lastWorkedDate != null &&
              project.lastWorkedDate != today &&
              project.lastWorkedDate != yesterdayStr) {
            newStreak = 0;
          }
        }
        project.dailyTimeSpent = 0;
        project.streak = newStreak;
        return project;
      }).toList();
      _playerEnergy = calculatedMaxEnergy;
      _lastLoginDate = today;
      _scheduleSave();
      scheduleEmotionReminders();
      notifyListeners();
    }
  }

  Future<void> clearAllGameData() async {
    if (_currentUser == null) return;
    await _storageService.deleteUserData(_currentUser!.uid);
    await _resetToInitialState();
    await _performActualSave();
    notifyListeners();
  }

  Future<void> resetPlayerLevelAndProgress() async {
    if (_currentUser == null) return;
    _playerLevel = 1;
    _xp = 0;
    _playerEnergy = calculatedMaxEnergy;
    _gameLog = [..._gameLog, "<span style=\"color:${helper.colorToHex(AppTheme.fnAccentOrange)}\">Player level and progress have been reset.</span>"];
    setProviderState(doNotify: true);
  }

  Future<void> resetAllSkills() async {
    if (_currentUser == null) return;
    final newSkills = _skills.map((skill) => Skill(
        id: skill.id, name: skill.name, description: skill.description,
        iconName: skill.iconName, xp: 0, level: 1)).toList();
    setProviderState(
      skills: newSkills,
      gameLog: [..._gameLog, "<span style=\"color:${helper.colorToHex(AppTheme.fnAccentOrange)}\">All skill progress has been reset.</span>"],
      doNotify: true,
    );
  }

  Future<void> editSkill(String skillId, {String? newName, String? newIconName}) async {
    final newSkills = _skills.map((skill) {
      if (skill.id == skillId) {
        return Skill(
          id: skill.id,
          name: newName ?? skill.name,
          iconName: newIconName ?? skill.iconName,
          xp: skill.xp,
          level: skill.level,
          description: skill.description,
        );
      }
      return skill;
    }).toList();
    setProviderState(
      skills: newSkills,
      gameLog: [..._gameLog, "<span style='color:${helper.colorToHex(AppTheme.fnAccentGreen)}'>Skill '${newName ?? '...'}' updated.</span>"],
      doNotify: true,
    );
  }

  Future<void> resetAndRecalculateSkillsFromLog() async {
    final Map<String, double> recalculatedXp = {};
    _completedByDay.forEach((date, dayData) {
      final List<dynamic> logs = [
        ...(dayData['subtasksCompleted'] as List<dynamic>? ?? []),
        ...(dayData['checkpointsCompleted'] as List<dynamic>? ?? []),
      ];
      for (var log in logs) {
        if (log is Map<String, dynamic> && log.containsKey('skillXp')) {
          final skillXpMap = log['skillXp'] as Map<String, dynamic>? ?? {};
          skillXpMap.forEach((skillId, xpValue) {
            if (xpValue is num) {
              recalculatedXp[skillId] = (recalculatedXp[skillId] ?? 0) + xpValue;
            }
          });
        }
      }
    });

    final List<Skill> newSkills = [];
    final existingThemes = _projects.map((p) => p.theme).toSet();

    for (String theme in existingThemes) {
      final double totalXp = recalculatedXp[theme] ?? 0.0;
      int newLevel = 1;
      while (totalXp >= helper.skillXpForLevel(newLevel + 1)) {
        newLevel++;
      }
      newSkills.add(Skill(
        id: theme,
        name: theme.replaceAll('_', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
        description: "Skill related to $theme.", iconName: themeToIconName[theme] ?? 'default',
        xp: totalXp, level: newLevel,
      ));
    }
    
    setProviderState(
      skills: newSkills,
      gameLog: [..._gameLog, "<span style=\"color:${helper.colorToHex(AppTheme.fnAccentGreen)}\">Skills recalculated from historical logs.</span>"],
      doNotify: true,
    );
  }

  List<EmotionLog> getEmotionLogsForDate(String date) {
    final dayData = _completedByDay[date] as Map<String, dynamic>?;
    if (dayData == null || dayData['emotionLogs'] == null) return [];
    return (dayData['emotionLogs'] as List<dynamic>).map((logJson) => EmotionLog.fromJson(logJson as Map<String, dynamic>)).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  void logEmotion(String date, double rating, [DateTime? customTimestamp]) {
    final timestamp = customTimestamp ?? DateTime.now();
    final emotionLog = EmotionLog(timestamp: timestamp, rating: rating);
    final newCompletedByDay = Map<String, dynamic>.from(_completedByDay);
    final dayData = Map<String, dynamic>.from(newCompletedByDay[date] ?? {'taskTimes': <String, int>{}, 'subtasksCompleted': <Map<String, dynamic>>[], 'checkpointsCompleted': <Map<String, dynamic>>[], 'emotionLogs': <Map<String, dynamic>>[]});
    final emotionLogsList = List<Map<String, dynamic>>.from(dayData['emotionLogs'] as List? ?? []);
    emotionLogsList.add(emotionLog.toJson());
    emotionLogsList.sort((a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String));
    dayData['emotionLogs'] = emotionLogsList;
    newCompletedByDay[date] = dayData;
    setProviderState(
        completedByDay: newCompletedByDay,
        gameLog: [..._gameLog, "<span style='color:${helper.colorToHex(AppTheme.fortnitePurple)}'>Emotion logged: ${rating.toStringAsFixed(1)}/5 for $date.</span>"],
        doNotify: true);
  }

  void deleteLatestEmotionLog(String date) {
    final currentLogs = getEmotionLogsForDate(date);
    if (currentLogs.isEmpty) return;
    final newCompletedByDay = Map<String, dynamic>.from(_completedByDay);
    final dayData = Map<String, dynamic>.from(newCompletedByDay[date] ?? {});
    final emotionLogsList = List<Map<String, dynamic>>.from(dayData['emotionLogs'] as List? ?? []);
    if (emotionLogsList.isNotEmpty) emotionLogsList.removeLast();
    dayData['emotionLogs'] = emotionLogsList;
    newCompletedByDay[date] = dayData;
    setProviderState(
        completedByDay: newCompletedByDay,
        gameLog: [..._gameLog, "<span style='color:${helper.colorToHex(AppTheme.fnAccentOrange)}'>Latest emotion log for $date deleted.</span>"],
        doNotify: true);
  }

  void setWakeupTime(TimeOfDay newTime) {
    _settings.wakeupTimeHour = newTime.hour;
    _settings.wakeupTimeMinute = newTime.minute;
    setSettings(_settings);
    scheduleEmotionReminders();
  }

  List<DateTime> calculateNotificationTimes() {
    final now = DateTime.now();
    final wakeupDateTime = DateTime(now.year, now.month, now.day, wakeupTime.hour, wakeupTime.minute);
    const int loggingDurationMinutes = 16 * 60, numberOfLogs = 10;
    final int intervalMinutes = (loggingDurationMinutes / (numberOfLogs - 1)).floor();
    List<DateTime> times = [];
    DateTime currentTime = wakeupDateTime;
    for (int i = 0; i < numberOfLogs; i++) {
      times.add(currentTime);
      currentTime = currentTime.add(Duration(minutes: intervalMinutes));
    }
    if (now.day == wakeupDateTime.day) return times.where((t) => t.isAfter(now)).toList();
    return times;
  }

  void scheduleEmotionReminders() {
    if (kDebugMode) {
      print("[GameProvider] Conceptual: Would schedule notifications for: ${calculateNotificationTimes().map((t) => DateFormat('HH:mm').format(t)).join(', ')}");
    }
  }

  void initializeChatbotMemory() {
    if (_isChatbotMemoryInitialized) return;
    if (_chatbotMemory.conversationHistory.isEmpty) {
      _chatbotMemory.conversationHistory.add(ChatbotMessage(
          id: 'init_${DateTime.now().millisecondsSinceEpoch}', text: "Hello! I am Arcane Advisor. How can I assist you?",
          sender: MessageSender.bot, timestamp: DateTime.now()));
    }
    _isChatbotMemoryInitialized = true;
    notifyListeners();
  }

  Future<void> sendMessageToChatbot(String userMessageText) async {
    if (!_isChatbotMemoryInitialized) initializeChatbotMemory();
    final userMessage = ChatbotMessage(id: 'user_${DateTime.now().millisecondsSinceEpoch}', text: userMessageText, sender: MessageSender.user, timestamp: DateTime.now());
    _chatbotMemory.conversationHistory.add(userMessage);
    if (_chatbotMemory.conversationHistory.length > 20) {
      _chatbotMemory.conversationHistory.removeAt(0);
    }
    if (userMessageText.toLowerCase().startsWith("remember:")) {
      final itemToRemember = userMessageText.substring("remember:".length).trim();
      if (itemToRemember.isNotEmpty) {
        _chatbotMemory.userRememberedItems.add(itemToRemember);
        if (_chatbotMemory.userRememberedItems.length > 10) {
          _chatbotMemory.userRememberedItems.removeAt(0);
        }
        final botResponse = ChatbotMessage(id: 'bot_${DateTime.now().millisecondsSinceEpoch}', text: "Okay, I will remember: \"$itemToRemember\"", sender: MessageSender.bot, timestamp: DateTime.now());
        _chatbotMemory.conversationHistory.add(botResponse);
        setProviderState(chatbotMemory: _chatbotMemory);
        return;
      }
    }
    if (userMessageText.toLowerCase().startsWith("forget last") || userMessageText.toLowerCase().startsWith("forget everything")) {
      bool forgetEverything = userMessageText.toLowerCase().startsWith("forget everything");
      String responseText;
      if (forgetEverything) {
        _chatbotMemory.userRememberedItems.clear();
        responseText = "Okay, I've cleared all remembered items.";
      } else if (_chatbotMemory.userRememberedItems.isNotEmpty) {
        String forgottenItem = _chatbotMemory.userRememberedItems.removeLast();
        responseText = "Okay, I've forgotten: \"$forgottenItem\"";
      } else {
        responseText = "I don't have any items to forget.";
      }
      final botResponse = ChatbotMessage(id: 'bot_${DateTime.now().millisecondsSinceEpoch}', text: responseText, sender: MessageSender.bot, timestamp: DateTime.now());
      _chatbotMemory.conversationHistory.add(botResponse);
      setProviderState(chatbotMemory: _chatbotMemory);
      return;
    }
    notifyListeners();
    Map<String, dynamic> completedByDayLast7DaysData = {};
    DateTime today = DateTime.now();
    _completedByDay.forEach((dateString, data) {
      DateTime date = DateTime.parse(dateString);
      if (today.difference(date).inDays < 7) {
        completedByDayLast7DaysData[dateString] = data;
      }
    });
    String completedByDayJsonForAI = jsonEncode(completedByDayLast7DaysData);
    String olderDaysSummaryForAI = _generateSummaryForOlderDays();
    try {
      final botResponseText = await _aiService.getChatbotResponse(memory: _chatbotMemory, userMessage: userMessageText,
        completedByDayJsonLast7Days: completedByDayJsonForAI, olderDaysSummary: olderDaysSummaryForAI,
        currentApiKeyIndex: _apiKeyIndex, onNewApiKeyIndex: (newIndex) => _apiKeyIndex = newIndex, onLog: (logMsg) => _gameLog.add(logMsg));
      final botMessage = ChatbotMessage(id: 'bot_${DateTime.now().millisecondsSinceEpoch}', text: botResponseText, sender: MessageSender.bot, timestamp: DateTime.now());
      _chatbotMemory.conversationHistory.add(botMessage);
    } catch (e) {
      final errorMessage = ChatbotMessage(id: 'error_${DateTime.now().millisecondsSinceEpoch}', text: "I'm having trouble connecting. Please try again later.", sender: MessageSender.bot, timestamp: DateTime.now());
      _chatbotMemory.conversationHistory.add(errorMessage);
    }
    setProviderState(chatbotMemory: _chatbotMemory);
  }

  Future<void> triggerAIEnhanceTask(Project project, Task taskToEnhance, String userInput) =>
    _aiGenerationActions.triggerAIEnhanceTask(project, taskToEnhance, userInput);

  Future<void> triggerAIGenerateTasks(Project project, String userInput) =>
    _aiGenerationActions.triggerAIGenerateTasks(project, userInput);

  void addProject({required String name, required String description, required String theme, required String colorHex}) =>
      _taskActions.addProject(name: name, description: description, theme: theme, colorHex: colorHex);
  void editProject(String projectId, {required String name, required String description, required String theme, required String colorHex}) =>
      _taskActions.editProject(projectId, name: name, description: description, theme: theme, colorHex: colorHex);
  void deleteProject(String projectId) => _taskActions.deleteProject(projectId);
  void logToDailySummary(String type, Map<String, dynamic> data) =>
      _taskActions.logToDailySummary(type, data);
  String addTask(String projectId, Map<String, dynamic> taskData) => _taskActions.addTask(projectId, taskData);
  void updateTask(String projectId, String taskId, Map<String, dynamic> updates) => _taskActions.updateTask(projectId, taskId, updates);
  void replaceTask(String projectId, String oldTaskId, Task newTask) => _taskActions.replaceTask(projectId, oldTaskId, newTask);
  bool completeTask(String projectId, String taskId) => _taskActions.completeTask(projectId, taskId);
  void deleteTask(String projectId, String taskId) => _taskActions.deleteTask(projectId, taskId);
  void duplicateCompletedTask(String projectId, String taskId) => _taskActions.duplicateCompletedTask(projectId, taskId);
  void addCheckpoint(String projectId, String parentTaskId, Map<String, dynamic> checkpointData) =>
      _taskActions.addCheckpoint(projectId, parentTaskId, checkpointData);
  void duplicateCheckpoint(String projectId, String parentTaskId, String checkpointId) =>
      _taskActions.duplicateCheckpoint(projectId, parentTaskId, checkpointId);
  void updateCheckpoint(String projectId, String parentTaskId, String checkpointId, Map<String, dynamic> updates) =>
      _taskActions.updateCheckpoint(projectId, parentTaskId, checkpointId, updates);
  void completeCheckpoint(String projectId, String parentTaskId, String checkpointId) =>
      _taskActions.completeCheckpoint(projectId, parentTaskId, checkpointId);
  void deleteCheckpoint(String projectId, String parentTaskId, String checkpointId) =>
      _taskActions.deleteCheckpoint(projectId, parentTaskId, checkpointId);

  void startTimer(String id, String type, String projectId) => _timerActions.startTimer(id, type, projectId);
  void pauseTimer(String id) => _timerActions.pauseTimer(id);
  void logTimerAndReset(String id) => _timerActions.logTimerAndReset(id);

  void _ensureSkillsList() {
    for (var project in _projects) {
      if (!_skills.any((s) => s.id == project.theme)) {
        _skills.add(Skill(
          id: project.theme,
          name: project.theme.replaceAll('_', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
          description: "Skill related to ${project.name}.",
          iconName: themeToIconName[project.theme] ?? 'default',
        ));
      }
    }
  }

  void addSkillXp(String skillId, double amount) {
    Skill? skill = _skills.firstWhereOrNull((s) => s.id == skillId);
    if (skill != null) {
      skill.xp += amount;
      int newLevel = 1;
      while (skill.xp >= helper.skillXpForLevel(newLevel + 1)) {
        newLevel++;
      }
      skill.level = newLevel;
      setProviderState(skills: _skills);
    }
  }
  
  void takeBreak(int minutes) {
    double energyCost = minutes.toDouble();
    if (_playerEnergy >= energyCost) {
      _playerEnergy -= energyCost;
      _breakOriginalDurationMinutes = minutes;
      _breakEndTime = DateTime.now().add(Duration(minutes: minutes));
      _breakTimer?.cancel();
      _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_breakEndTime == null || DateTime.now().isAfter(_breakEndTime!)) {
          _breakTimer?.cancel();
          _breakEndTime = null;
          _breakOriginalDurationMinutes = null;
          _notificationService.showNotification('Break Over!', 'Time to get back to the mission.');
           setProviderState(gameLog: [..._gameLog, "<span style='color:${helper.colorToHex(AppTheme.fnAccentGreen)}'>Break finished. Time to get back to the mission.</span>"], doNotify: true);
        } else {
          notifyListeners();
        }
      });
      setProviderState(
        playerEnergy: _playerEnergy,
        gameLog: [..._gameLog, "<span style='color:${helper.colorToHex(AppTheme.fortnitePurple)}'>Took a $minutes minute break.</span>"],
        doNotify: true,
      );
    } else {
        setProviderState(gameLog: [..._gameLog, "<span style='color:${helper.colorToHex(AppTheme.fnAccentOrange)}'>Not enough energy for a $minutes minute break.</span>"]);
    }
  }

  void cancelBreak() {
    if (_breakEndTime == null || _breakOriginalDurationMinutes == null) return;
    final double energyCost = _breakOriginalDurationMinutes!.toDouble();
    final double energyRefund = energyCost / 2;
    _breakTimer?.cancel();
    _breakEndTime = null;
    _breakOriginalDurationMinutes = null;
    setProviderState(
      playerEnergy: (_playerEnergy + energyRefund).clamp(0, calculatedMaxEnergy),
      gameLog: [..._gameLog, "<span style='color:${helper.colorToHex(AppTheme.fnAccentOrange)}'>Break cancelled. Regained ${energyRefund.toStringAsFixed(0)} energy.</span>"],
      doNotify: true,
    );
  }

  void refillEnergyWithCoins(int energyAmount) {
    double totalCost = energyAmount * coinsPerEnergy;
    if (_coins >= totalCost) {
      setProviderState(
        coins: _coins - totalCost,
        playerEnergy: (_playerEnergy + energyAmount).clamp(0, calculatedMaxEnergy),
        gameLog: [..._gameLog, "<span style='color:${helper.colorToHex(AppTheme.fnAccentGreen)}'>Purchased $energyAmount energy for ${totalCost.toStringAsFixed(0)} coins.</span>"],
      );
    } else {
       setProviderState(gameLog: [..._gameLog, "<span style='color:${helper.colorToHex(AppTheme.fnAccentOrange)}'>Not enough coins to purchase $energyAmount energy.</span>"]);
    }
  }

  void setProviderState({
    String? lastLoginDate, double? coins, double? xp, double? playerEnergy,
    List<Project>? projects, Map<String, dynamic>? completedByDay, List<String>? gameLog,
    List<Skill>? skills, Map<String, ActiveTimerInfo>? activeTimers,
    DateTime? lastSuccessfulSaveTimestamp, bool? isUsernameMissing, ChatbotMemory? chatbotMemory,
    bool doNotify = true, bool immediateSave = false,
  }) {
    bool changed = false;
    if (lastLoginDate != null && _lastLoginDate != lastLoginDate) { _lastLoginDate = lastLoginDate; changed = true; }
    if (coins != null && _coins != coins) { _coins = coins; changed = true; }
    if (xp != null && _xp != xp) { _xp = xp; _recalculatePlayerLevel(); changed = true; }
    if (playerEnergy != null && _playerEnergy != playerEnergy) { _playerEnergy = playerEnergy.clamp(0, calculatedMaxEnergy); changed = true; }
    if (projects != null && !listEquals(_projects, projects)) { _projects = List.from(projects); _ensureSkillsList(); changed = true; }
    if (completedByDay != null && !mapEquals(_completedByDay, completedByDay)) { _completedByDay = Map.from(completedByDay); changed = true; }
    if (gameLog != null && !listEquals(_gameLog, gameLog)) { _gameLog = List.from(gameLog); changed = true; }
    if (skills != null && !listEquals(_skills, skills)) { _skills = List.from(skills); changed = true; }
    if (activeTimers != null && !mapEquals(_activeTimers, activeTimers)) { _activeTimers = Map.from(activeTimers); changed = true; }
    if (lastSuccessfulSaveTimestamp != null && _lastSuccessfulSaveTimestamp != lastSuccessfulSaveTimestamp) { _lastSuccessfulSaveTimestamp = lastSuccessfulSaveTimestamp; changed = true; }
    if (isUsernameMissing != null && _isUsernameMissing != isUsernameMissing) { _isUsernameMissing = isUsernameMissing; changed = true; }
    if (chatbotMemory != null && _chatbotMemory != chatbotMemory) { _chatbotMemory = chatbotMemory; changed = true; }
    if (changed) {
      _scheduleSave(immediate: immediateSave);
      if (doNotify) notifyListeners();
    }
  }

  void setProviderAIGlobalLoading(bool isLoading, {double progress = 0.0, String statusMessage = ""}) {
    bool changed = false;
    if (_isGeneratingGlobalContent != isLoading) { _isGeneratingGlobalContent = isLoading; changed = true; }
    if (_aiGenerationProgress != progress) { _aiGenerationProgress = progress; changed = true; }
    if (_aiGenerationStatusMessage != statusMessage) { _aiGenerationStatusMessage = statusMessage; changed = true; }
    if (changed) notifyListeners();
  }

  void setProviderAISubquestLoading(bool isLoading) {
    if (_isGeneratingSubquestsForTask != isLoading) {
      _isGeneratingSubquestsForTask = isLoading;
      notifyListeners();
    }
  }

  void setProviderApiKeyIndex(int index) {
    if (_apiKeyIndex != index) {
      _apiKeyIndex = index;
    }
  }
}
 