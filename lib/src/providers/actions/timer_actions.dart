// lib/src/providers/actions/timer_actions.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/models/game_models.dart';

class TimerActions {
  final GameProvider _provider;

  TimerActions(this._provider);

  void startTimer(String id, String type, String projectId) {
    Map<String, ActiveTimerInfo> updatedActiveTimers = Map.from(_provider.activeTimers);

    // Pause any other running timer
    for (var entry in updatedActiveTimers.entries) {
      final timerId = entry.key;
      final timerInfo = entry.value;
      if (timerInfo.isRunning && timerId != id) {
        final double elapsed = (DateTime.now().difference(timerInfo.startTime).inMilliseconds) / 1000.0;
        updatedActiveTimers[timerId] = ActiveTimerInfo(
          startTime: timerInfo.startTime,
          accumulatedDisplayTime: timerInfo.accumulatedDisplayTime + elapsed,
          isRunning: false,
          type: timerInfo.type,
          projectId: timerInfo.projectId,
        );
      }
    }

    // Start or resume the selected timer
    final existingTimer = updatedActiveTimers[id];
    updatedActiveTimers[id] = ActiveTimerInfo(
      startTime: DateTime.now(),
      accumulatedDisplayTime: existingTimer?.accumulatedDisplayTime ?? 0,
      isRunning: true,
      type: type,
      projectId: projectId,
    );
    _provider.setProviderState(activeTimers: updatedActiveTimers);
  }

  void pauseTimer(String id) {
    final timer = _provider.activeTimers[id];
    if (timer != null && timer.isRunning) {
      final double elapsed = (DateTime.now().difference(timer.startTime).inMilliseconds) / 1000.0;
      final newActiveTimers = Map<String, ActiveTimerInfo>.from(_provider.activeTimers);
      newActiveTimers[id] = ActiveTimerInfo(
        startTime: timer.startTime,
        accumulatedDisplayTime: timer.accumulatedDisplayTime + elapsed,
        isRunning: false,
        type: timer.type,
        projectId: timer.projectId,
      );
      _provider.setProviderState(activeTimers: newActiveTimers);
    }
  }

  void logTimerAndReset(String id) {
    final timer = _provider.activeTimers[id];
    if (timer != null) {
      double totalSecondsToLog = timer.accumulatedDisplayTime;
      if (timer.isRunning) {
        totalSecondsToLog += (DateTime.now().difference(timer.startTime).inMilliseconds) / 1000.0;
      }
      final int minutesToLog = (totalSecondsToLog / 60).round();

      if (minutesToLog > 0) {
        if (timer.type == 'task') {
          final Project? currentProject = _provider.projects.firstWhere((p) => p.id == timer.projectId, orElse: () => Project(id: '', name: '', description: '', theme: ''));
          if (currentProject != null && currentProject.id.isNotEmpty) {
            final Task? task = currentProject.tasks.firstWhere((t) => t.id == id, orElse: () => Task(id: '', name: ''));
            if (task != null && task.id.isNotEmpty) {
              _provider.updateTask(timer.projectId, id, {'currentTimeSpent': task.currentTimeSpent + minutesToLog});
            }
          }
        }
      }

      final newActiveTimers = Map<String, ActiveTimerInfo>.from(_provider.activeTimers)..remove(id);
      _provider.setProviderState(activeTimers: newActiveTimers);
    }
  }
}