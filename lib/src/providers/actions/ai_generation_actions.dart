// lib/src/providers/actions/ai_generation_actions.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/services/ai_service.dart';
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:collection/collection.dart'; // For whereNotNull

class AIGenerationActions {
  final GameProvider _provider;
  final AIService _aiService = AIService();

  AIGenerationActions(this._provider);

  void _logToGame(String logMessage, {bool isError = false}) {
    final color = isError
        ? AppTheme.fnAccentRed.value.toRadixString(16).substring(2)
        : AppTheme.fnTextSecondary.value.toRadixString(16).substring(2);
    final finalMessage = "<span style=\"color:#$color;\">$logMessage</span>";

    if (kDebugMode) print("[AIActions]: $logMessage");
    _provider.setProviderState(
        gameLog: [..._provider.gameLog, finalMessage], doNotify: true);
  }

  Future<void> triggerAIGenerateTasks(
      Project project, String userInput) async {
    if (_provider.isGeneratingContent) return;

    _provider.setProviderAIGlobalLoading(true,
        statusMessage: 'Generating new tasks...');
    _logToGame("AI is generating new tasks for project '${project.name}'...");

    try {
      final List<Map<String, dynamic>> tasksData =
          await _aiService.generateTasksFromPlan(
        project: project,
        userInput: userInput,
        currentApiKeyIndex: _provider.apiKeyIndex,
        onNewApiKeyIndex: (newIndex) => _provider.setProviderApiKeyIndex(newIndex),
        onLog: (msg) => _logToGame(msg),
      );

      int tasksAdded = 0;
      for (final taskData in tasksData) {
        _provider.addTask(project.id, taskData);
        tasksAdded++;
      }

      _logToGame(
          "AI successfully generated $tasksAdded new tasks for '${project.name}'.",
          isError: false);
    } catch (e) {
      _logToGame("AI task generation failed: ${e.toString()}", isError: true);
    } finally {
      _provider.setProviderAIGlobalLoading(false);
    }
  }

  Future<void> triggerAIEnhanceTask(
    Project project,
    Task taskToEnhance,
    String userInput,
  ) async {
    if (_provider.isGeneratingSubquests) return;

    _provider.setProviderAISubquestLoading(true);
    _logToGame(
        "<span style=\"color:${(project.color).value.toRadixString(16).substring(2)};\">AI is enhancing task '${taskToEnhance.name}'...</span>");

    try {
      // The AI service now only returns the parts to be merged
      final Map<String, dynamic> enhancementData =
          await _aiService.enhanceTaskWithAI(
        project: project,
        task: taskToEnhance,
        userInput: userInput,
        currentApiKeyIndex: _provider.apiKeyIndex,
        onNewApiKeyIndex: (newIndex) => _provider.setProviderApiKeyIndex(newIndex),
        onLog: _logToGame,
      );

      final Map<String, double> newSkillXp =
          (enhancementData['skillXp'] as Map<String, dynamic>?)
                  ?.map((key, value) =>
                      MapEntry(key, (value as num).toDouble())) ??
              {};

      final List<Checkpoint> newCheckpoints =
          (enhancementData['checkpoints'] as List<dynamic>? ?? [])
              .map((cpData) => cpData is Map<String, dynamic>
                  ? Checkpoint.fromJson(cpData)
                  : null)
              .whereNotNull()
              .toList();

      // Merge the results with the existing task
      final enhancedTask = Task(
        id: taskToEnhance.id,
        name: taskToEnhance.name, // Name is preserved
        completed: taskToEnhance.completed,
        isCountable: taskToEnhance.isCountable, // Countability is preserved
        targetCount: taskToEnhance.targetCount,
        currentTimeSpent: taskToEnhance.currentTimeSpent,
        currentCount: taskToEnhance.currentCount,
        skillXp: newSkillXp, // Overwrite with new skill XP map
        checkpoints: newCheckpoints, // Overwrite with new checkpoints
      );

      _provider.replaceTask(project.id, taskToEnhance.id, enhancedTask);
      _logToGame(
          "<span style=\"color:${AppTheme.fnAccentGreen.value.toRadixString(16).substring(2)};\">Successfully enhanced task '${enhancedTask.name}'.</span>");
    } catch (e, stackTrace) {
      final errorMessage = e.toString();
      _logToGame(
          "<span style=\"color:${AppTheme.fnAccentRed.value.toRadixString(16).substring(2)};\">AI enhancement for '${taskToEnhance.name}' failed: $errorMessage</span>");
    } finally {
      _provider.setProviderAISubquestLoading(false);
    }
  }
}