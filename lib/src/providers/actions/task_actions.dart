 
// lib/src/providers/actions/task_actions.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/utils/constants.dart';
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/utils/helpers.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

class TaskActions {
  final GameProvider _provider;

  TaskActions(this._provider);

  void addProject(
      {required String name,
      required String description,
      required String theme,
      required String colorHex}) {
    final newProject = Project(
      id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      theme: theme,
      colorHex: colorHex,
    );
    _provider.setProviderState(projects: [..._provider.projects, newProject]);
  }

  void editProject(String projectId,
      {required String name,
      required String description,
      required String theme,
      required String colorHex}) {
    final newProjects = _provider.projects.map((project) {
      if (project.id == projectId) {
        return Project(
          id: project.id,
          name: name,
          description: description,
          theme: theme,
          colorHex: colorHex,
          streak: project.streak,
          dailyTimeSpent: project.dailyTimeSpent,
          lastWorkedDate: project.lastWorkedDate,
          tasks: project.tasks,
        );
      }
      return project;
    }).toList();
    _provider.setProviderState(projects: newProjects);
  }
  
  void deleteProject(String projectId) {
    final newProjects = List<Project>.from(_provider.projects);
    final projectToDelete = newProjects.firstWhereOrNull((p) => p.id == projectId);
    if (projectToDelete == null) return;

    newProjects.removeWhere((p) => p.id == projectId);

    String? newSelectedId = _provider.selectedProjectId;
    if (_provider.selectedProjectId == projectId) {
      newSelectedId = newProjects.isNotEmpty ? newProjects.first.id : null;
    }
    
    final themeOfDeletedProject = projectToDelete.theme;
    final isThemeStillInUse = newProjects.any((p) => p.theme == themeOfDeletedProject);
    
    List<Skill> newSkills = List<Skill>.from(_provider.skills);
    if (!isThemeStillInUse) {
      newSkills.removeWhere((s) => s.id == themeOfDeletedProject);
    }
    
    _provider.setProviderState(
      projects: newProjects,
      skills: newSkills,
      immediateSave: true,
    );
    // setSelectedProjectId will trigger its own notify and save
    _provider.setSelectedProjectId(newSelectedId);
  }


  void logToDailySummary(String type, Map<String, dynamic> data) {
    final today = getTodayDateString();
    final newCompletedByDay = Map<String, dynamic>.from(_provider.completedByDay);
    final dayData = Map<String, dynamic>.from(newCompletedByDay[today] ??
        {'taskTimes': <String, int>{}, 'subtasksCompleted': <Map<String, dynamic>>[], 'checkpointsCompleted': <Map<String, dynamic>>[], 'emotionLogs': <Map<String, dynamic>>[]});

    if (type == 'taskTime') {
      final taskTimes = Map<String, int>.from(dayData['taskTimes'] as Map? ?? {});
      taskTimes[data['projectId'] as String] = (taskTimes[data['projectId'] as String] ?? 0) + (data['time'] as int);
      dayData['taskTimes'] = taskTimes;
    } else if (type == 'taskCompleted') {
      final tasksCompleted = List<Map<String, dynamic>>.from(dayData['subtasksCompleted'] as List? ?? []);
      tasksCompleted.add(data);
      dayData['subtasksCompleted'] = tasksCompleted;
    } else if (type == 'checkpointCompleted') {
      final checkpointsCompleted = List<Map<String, dynamic>>.from(dayData['checkpointsCompleted'] as List? ?? []);
      if (!data.containsKey('completionTimestamp')) {
          data['completionTimestamp'] = DateTime.now().toIso8601String();
      }
      checkpointsCompleted.add(data);
      dayData['checkpointsCompleted'] = checkpointsCompleted;
    }

    newCompletedByDay[today] = dayData;
    _provider.setProviderState(completedByDay: newCompletedByDay);
  }

  String addTask(String projectId, Map<String, dynamic> taskData) {
    final newTask = Task(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}_${(_provider.projects.fold<int>(0, (prev, p) => prev + p.tasks.length) + 1)}',
      name: taskData['name'] as String,
      isCountable: taskData['isCountable'] as bool? ?? false,
      targetCount: taskData['isCountable'] as bool? ?? false ? (taskData['targetCount'] as int? ?? 1) : 0,
      checkpoints: (taskData['checkpointsData'] as List<Map<String, dynamic>>?)?.map((cpData) => Checkpoint(
            id: 'cp_${DateTime.now().millisecondsSinceEpoch}_${(_provider.projects.fold<int>(0, (prev, p) => prev + p.tasks.fold<int>(0, (pSt, st) => pSt + st.checkpoints.length)) + 1)}_${cpData['name']?.hashCode ?? 0}',
            name: cpData['name'] as String,
            isCountable: cpData['isCountable'] as bool? ?? false,
            targetCount: cpData['isCountable'] as bool? ?? false ? (cpData['targetCount'] as int? ?? 1) : 0,
      )).toList() ?? [],
    );

    final newProjects = _provider.projects.map((project) {
      if (project.id == projectId) {
        project.tasks.add(newTask);
      }
      return project;
    }).toList();
    _provider.setProviderState(projects: newProjects);
    return newTask.id;
  }

  void updateTask(String projectId, String taskId, Map<String, dynamic> updates) {
    Project? projectToUpdate = _provider.projects.firstWhereOrNull((p) => p.id == projectId);
    if (projectToUpdate == null) return;
    Task? taskToUpdate = projectToUpdate.tasks.firstWhereOrNull((t) => t.id == taskId);
    if (taskToUpdate == null) return;

    final int oldTaskTime = taskToUpdate.currentTimeSpent;

    if (updates.containsKey('name')) taskToUpdate.name = updates['name'] as String;
    if (updates.containsKey('isCountable')) taskToUpdate.isCountable = updates['isCountable'] as bool;
    if (updates.containsKey('targetCount')) taskToUpdate.targetCount = updates['targetCount'] as int;
    if (updates.containsKey('currentCount')) taskToUpdate.currentCount = (updates['currentCount'] as int).clamp(0, taskToUpdate.targetCount);
    if (updates.containsKey('currentTimeSpent')) taskToUpdate.currentTimeSpent = updates['currentTimeSpent'] as int;

    int timeDifference = 0;
    if (updates.containsKey('currentTimeSpent')) timeDifference = taskToUpdate.currentTimeSpent - oldTaskTime;

    if (timeDifference != 0) {
      projectToUpdate.dailyTimeSpent = (projectToUpdate.dailyTimeSpent) + timeDifference;
      projectToUpdate.lastWorkedDate = getTodayDateString();
      logToDailySummary('taskTime', {'projectId': projectId, 'time': timeDifference});
      if (timeDifference > 0) {
        _provider.setProviderState(playerEnergy: (_provider.playerEnergy + timeDifference * energyRegenPerMinuteTasked).clamp(0, _provider.calculatedMaxEnergy));
      }
    }

    if (projectToUpdate.dailyTimeSpent - timeDifference < dailyTaskGoalMinutes && projectToUpdate.dailyTimeSpent >= dailyTaskGoalMinutes) {
      projectToUpdate.streak++;
    }

    final newProjects = _provider.projects.map((p) => p.id == projectId ? projectToUpdate : p).toList();
    _provider.setProviderState(projects: newProjects);
  }

  bool completeTask(String projectId, String taskId) {
    Project? project = _provider.projects.firstWhereOrNull((p) => p.id == projectId);
    if (project == null) return false;
    Task? task = project.tasks.firstWhereOrNull((t) => t.id == taskId);
    if (task == null || task.completed) return false;

    // Validation checks
    if (task.isCountable && task.currentCount < task.targetCount) {
      return false;
    }
    if (task.checkpoints.isNotEmpty && !task.checkpoints.every((cp) => cp.completed)) {
      return false;
    }

    ActiveTimerInfo? timerForTask = _provider.activeTimers[taskId];
    Task updatedTaskForRewards = task;

    if (timerForTask != null) {
      double totalSecondsToLog = timerForTask.accumulatedDisplayTime;
      if (timerForTask.isRunning) totalSecondsToLog += (DateTime.now().difference(timerForTask.startTime).inMilliseconds) / 1000;
      final int elapsedMinutes = (totalSecondsToLog / 60).round();
      if (elapsedMinutes > 0) {
        updateTask(projectId, taskId, {'currentTimeSpent': task.currentTimeSpent + elapsedMinutes});
        final Project? refetchedProject = _provider.projects.firstWhereOrNull((p) => p.id == projectId);
        if (refetchedProject != null) {
          updatedTaskForRewards = refetchedProject.tasks.firstWhereOrNull((t) => t.id == taskId) ?? task;
        }
      }
      final newActiveTimers = Map<String, ActiveTimerInfo>.from(_provider.activeTimers)..remove(taskId);
      _provider.setProviderState(activeTimers: newActiveTimers);
    }

    double proportionalXp = updatedTaskForRewards.isCountable ? updatedTaskForRewards.targetCount * xpPerCountUnitSubtask : updatedTaskForRewards.currentTimeSpent * xpPerMinuteSubtask;
    double proportionalCoins = updatedTaskForRewards.isCountable ? updatedTaskForRewards.targetCount * coinsPerCountUnitSubtask : updatedTaskForRewards.currentTimeSpent * coinsPerMinuteSubtask;
    final double baseCompletionXp = subtaskCompletionXpBase + _provider.playerLevel + project.streak;
    final double baseCompletionCoins = subtaskCompletionCoinBase + (_provider.playerLevel * 0.5) + (project.streak * 0.2);
    final int finalXpReward = (baseCompletionXp + proportionalXp).floor();
    final int finalCoinReward = (baseCompletionCoins + proportionalCoins).floor();

    final newProjects = _provider.projects.map((p) {
      if (p.id == projectId) {
        p.tasks = p.tasks.map((t) {
          if (t.id == taskId) {
            t.completed = true; 
            t.completedDate = getTodayDateString();
          }
          return t;
        }).toList();
      }
      return p;
    }).toList();

    _provider.setProviderState(projects: newProjects, xp: _provider.xp + finalXpReward, coins: _provider.coins + finalCoinReward);
    updatedTaskForRewards.skillXp.forEach((skillId, xpAmount) => _provider.addSkillXp(skillId, xpAmount));
    logToDailySummary('taskCompleted', {'projectId': project.id, 'name': updatedTaskForRewards.name, 'timeLogged': updatedTaskForRewards.currentTimeSpent,
      'isCountable': updatedTaskForRewards.isCountable, 'currentCount': updatedTaskForRewards.currentCount, 'targetCount': updatedTaskForRewards.targetCount, 'skillXp': updatedTaskForRewards.skillXp});
    return true;
  }

  void deleteTask(String projectId, String taskId) {
    final newProjects = _provider.projects.map((project) {
      if (project.id == projectId) {
        project.tasks.removeWhere((t) => t.id == taskId);
      }
      return project;
    }).toList();
    final newActiveTimers = Map<String, ActiveTimerInfo>.from(_provider.activeTimers)..remove(taskId);
    _provider.setProviderState(projects: newProjects, activeTimers: newActiveTimers, immediateSave: true);
  }

  void replaceTask(String projectId, String oldTaskId, Task newTask) {
    final newProjects = _provider.projects.map((project) {
      if (project.id == projectId) {
        final taskIndex = project.tasks.indexWhere((t) => t.id == oldTaskId);
        if (taskIndex != -1) project.tasks[taskIndex] = newTask;
      }
      return project;
    }).toList();
    _provider.setProviderState(projects: newProjects);
  }

  void duplicateCompletedTask(String projectId, String taskId) {
    Project? projectToUpdate = _provider.projects.firstWhereOrNull((p) => p.id == projectId);
    if (projectToUpdate == null) return;
    Task? taskToDuplicate = projectToUpdate.tasks.firstWhereOrNull((t) => t.id == taskId);
    if (taskToDuplicate == null || !taskToDuplicate.completed) return;

    final newTask = Task(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}_${(projectToUpdate.tasks.length + 1)}',
      name: taskToDuplicate.name, completed: false, currentTimeSpent: 0, completedDate: null,
      isCountable: taskToDuplicate.isCountable, targetCount: taskToDuplicate.targetCount, currentCount: 0,
      skillXp: taskToDuplicate.skillXp,
      checkpoints: taskToDuplicate.checkpoints.map((cp) => Checkpoint(
            id: 'cp_${DateTime.now().millisecondsSinceEpoch}_${(taskToDuplicate.checkpoints.length + 1)}_${cp.name.hashCode}',
            name: cp.name, completed: false, isCountable: cp.isCountable, targetCount: cp.targetCount,
            currentCount: 0, completionTimestamp: null, skillXp: cp.skillXp,
      )).toList(),
    );
    projectToUpdate.tasks.add(newTask);
    final newProjects = _provider.projects.map((p) => p.id == projectId ? projectToUpdate : p).toList();
    _provider.setProviderState(projects: newProjects);
  }

  void addCheckpoint(String projectId, String parentTaskId, Map<String, dynamic> checkpointData) {
    final newCheckpoint = Checkpoint(
      id: 'cp_${DateTime.now().millisecondsSinceEpoch}_${checkpointData['name']?.hashCode ?? 0}',
      name: checkpointData['name'] as String,
      isCountable: checkpointData['isCountable'] as bool? ?? false,
      targetCount: checkpointData['isCountable'] as bool? ?? false ? (checkpointData['targetCount'] as int? ?? 1) : 0,
    );

    final newProjects = _provider.projects.map((project) {
      if (project.id == projectId) {
        project.tasks.firstWhereOrNull((t) => t.id == parentTaskId)?.checkpoints.add(newCheckpoint);
      }
      return project;
    }).toList();
    _provider.setProviderState(projects: newProjects);
  }

  void updateCheckpoint(String projectId, String parentTaskId, String checkpointId, Map<String, dynamic> updates) {
    final newProjects = _provider.projects.map((project) {
      if (project.id == projectId) {
        project.tasks.firstWhereOrNull((t) => t.id == parentTaskId)?.checkpoints = project.tasks
            .firstWhere((t) => t.id == parentTaskId).checkpoints.map((cp) {
          if (cp.id == checkpointId) {
            cp.name = updates['name'] as String? ?? cp.name;
            cp.completed = updates['completed'] as bool? ?? cp.completed;
            cp.isCountable = updates['isCountable'] as bool? ?? cp.isCountable;
            cp.targetCount = updates['targetCount'] as int? ?? cp.targetCount;
            cp.currentCount = updates['currentCount'] as int? ?? cp.currentCount;
            cp.completionTimestamp = updates['completionTimestamp'] as String? ?? cp.completionTimestamp;
            cp.skillXp = (updates['skillXp'] as Map<String, double>?) ?? cp.skillXp;
            if (cp.isCountable) cp.currentCount = cp.currentCount.clamp(0, cp.targetCount);
          }
          return cp;
        }).toList();
      }
      return project;
    }).toList();
    _provider.setProviderState(projects: newProjects);
  }

  void completeCheckpoint(String projectId, String parentTaskId, String checkpointId) {
    double xpReward = 0; double coinReward = 0;
    bool checkpointCompletedSuccessfully = false;
    Checkpoint? completedCheckpointInstanceForLog;

    Project? project = _provider.projects.firstWhereOrNull((p) => p.id == projectId);
    Task? task = project?.tasks.firstWhereOrNull((t) => t.id == parentTaskId);
    Checkpoint? checkpoint = task?.checkpoints.firstWhereOrNull((cp) => cp.id == checkpointId);

    if (checkpoint == null || checkpoint.completed) return;
    if (checkpoint.isCountable && checkpoint.currentCount < checkpoint.targetCount) return;

    final double proportionalXp = checkpoint.isCountable ? checkpoint.targetCount * xpPerCountUnitSubSubtask : 0;
    final double proportionalCoins = checkpoint.isCountable ? checkpoint.targetCount * coinsPerCountUnitSubSubtask : 0;
    xpReward = (subSubtaskCompletionXpBase + proportionalXp).floorToDouble();
    coinReward = (subSubtaskCompletionCoinBase + proportionalCoins).floorToDouble();
    
    checkpoint.completed = true;
    checkpoint.completionTimestamp = DateTime.now().toIso8601String();
    completedCheckpointInstanceForLog = checkpoint;
    checkpointCompletedSuccessfully = true;

    final newProjects = _provider.projects.map((p) => p.id == projectId ? project! : p).toList();

    if (checkpointCompletedSuccessfully && completedCheckpointInstanceForLog != null) {
      _provider.setProviderState(projects: newProjects, xp: _provider.xp + xpReward, coins: _provider.coins + coinReward);
      completedCheckpointInstanceForLog.skillXp.forEach((skillId, xpAmount) => _provider.addSkillXp(skillId, xpAmount));
      logToDailySummary('checkpointCompleted', {
        'projectId': projectId, 'parentTaskId': parentTaskId, 'checkpointId': checkpointId, 'name': completedCheckpointInstanceForLog.name,
        'isCountable': completedCheckpointInstanceForLog.isCountable, 'currentCount': completedCheckpointInstanceForLog.currentCount, 'targetCount': completedCheckpointInstanceForLog.targetCount,
        'completionTimestamp': completedCheckpointInstanceForLog.completionTimestamp, 'skillXp': completedCheckpointInstanceForLog.skillXp,
        'parentTaskName': task?.name ?? 'N/A', 'projectName': project?.name ?? 'N/A'
      });
    }
  }

  void deleteCheckpoint(String projectId, String parentTaskId, String checkpointId) {
    final newProjects = _provider.projects.map((project) {
      if (project.id == projectId) {
        project.tasks.firstWhereOrNull((t) => t.id == parentTaskId)?.checkpoints.removeWhere((cp) => cp.id == checkpointId);
      }
      return project;
    }).toList();
    _provider.setProviderState(projects: newProjects, immediateSave: true);
  }

  void duplicateCheckpoint(String projectId, String parentTaskId, String checkpointId) {
    Project? project = _provider.projects.firstWhereOrNull((p) => p.id == projectId);
    if (project == null) return;
    Task? task = project.tasks.firstWhereOrNull((t) => t.id == parentTaskId);
    if (task == null) return;
    Checkpoint? checkpointToDuplicate = task.checkpoints.firstWhereOrNull((cp) => cp.id == checkpointId);
    if (checkpointToDuplicate == null) return;

    final newCheckpoint = Checkpoint(
      id: 'cp_${DateTime.now().millisecondsSinceEpoch}_${checkpointToDuplicate.name.hashCode}',
      name: checkpointToDuplicate.name,
      completed: false,
      isCountable: checkpointToDuplicate.isCountable,
      targetCount: checkpointToDuplicate.targetCount,
      currentCount: 0,
      completionTimestamp: null,
      skillXp: checkpointToDuplicate.skillXp,
    );

    final newProjects = _provider.projects.map((p) {
      if (p.id == projectId) {
        p.tasks.firstWhereOrNull((t) => t.id == parentTaskId)?.checkpoints.add(newCheckpoint);
      }
      return p;
    }).toList();
    _provider.setProviderState(projects: newProjects);
  }
}
 