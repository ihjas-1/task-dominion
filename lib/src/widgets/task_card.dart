 
// lib/src/widgets/task_card.dart
import 'dart:async';

import 'package:arcane/src/widgets/components/checkpoint_list.dart';
import 'package:arcane/src/widgets/components/task_progress_bar.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/utils/helpers.dart' as helper;

class TaskCard extends StatefulWidget {
  final Project project;
  final Task task;

  const TaskCard({
    super.key,
    required this.project,
    required this.task,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  late GameProvider gameProvider;
  Timer? _timerDisplayUpdater;
  final _newCheckpointNameController = TextEditingController();
  bool _isEditingTime = false;
  late TextEditingController _timeController;
  final FocusNode _timeFocusNode = FocusNode();
  late Map<String, TextEditingController> _checkpointCountControllers;


  @override
  void initState() {
    super.initState();
    gameProvider = Provider.of<GameProvider>(context, listen: false);
    _timeController = TextEditingController(text: widget.task.currentTimeSpent.toString());
    _checkpointCountControllers = {
      for (var cp in widget.task.checkpoints)
        cp.id: TextEditingController(text: cp.currentCount.toString())
    };
    _startTimerDisplayUpdater();
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.id != oldWidget.task.id) {
      // Task has completely changed, reset all controllers
      _timeController.text = widget.task.currentTimeSpent.toString();
      _checkpointCountControllers.values.forEach((controller) => controller.dispose());
      _checkpointCountControllers = {
        for (var cp in widget.task.checkpoints)
          cp.id: TextEditingController(text: cp.currentCount.toString())
      };
    } else {
      // Task is the same, just updating its properties
      if (widget.task.currentTimeSpent.toString() != _timeController.text && !_timeFocusNode.hasFocus) {
        _timeController.text = widget.task.currentTimeSpent.toString();
      }

      // Sync checkpoint controllers
      final newCheckpointIds = widget.task.checkpoints.map((cp) => cp.id).toSet();
      
      // Remove controllers for deleted checkpoints
      final oldCheckpointIds = _checkpointCountControllers.keys.toList();
      for (final oldId in oldCheckpointIds) {
          if (!newCheckpointIds.contains(oldId)) {
              _checkpointCountControllers[oldId]?.dispose();
              _checkpointCountControllers.remove(oldId);
          }
      }

      // Add new or update existing controllers
      for (var cp in widget.task.checkpoints) {
        if (_checkpointCountControllers.containsKey(cp.id)) {
          final controller = _checkpointCountControllers[cp.id]!;
          if (controller.text != cp.currentCount.toString() && !controller.selection.isValid) {
            controller.text = cp.currentCount.toString();
          }
        } else {
          _checkpointCountControllers[cp.id] = TextEditingController(text: cp.currentCount.toString());
        }
      }
    }
    
    _timerDisplayUpdater?.cancel();
    _startTimerDisplayUpdater();
  }

  @override
  void dispose() {
    _newCheckpointNameController.dispose();
    _timeController.dispose();
    _timeFocusNode.dispose();
    _checkpointCountControllers.values.forEach((controller) => controller.dispose());
    _timerDisplayUpdater?.cancel();
    super.dispose();
  }

  void _startTimerDisplayUpdater() {
    final timerState = gameProvider.activeTimers[widget.task.id];
    if (timerState != null && timerState.isRunning) {
      _timerDisplayUpdater = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (mounted) {
          setState(() {});
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _showAIEnhanceDialog(BuildContext context, GameProvider gameProvider,
      Project project, Task task) {
    final aiInputController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.fnBgMedium,
          title:  Row(children: [
            Icon(MdiIcons.autoFix, color: AppTheme.fortnitePurple),
            const SizedBox(width: 8),
            const Text("Enhance Task", style: TextStyle(color: AppTheme.fortnitePurple)),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    "AI will analyze '${task.name}' and generate smaller, actionable checkpoints for it.",
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: aiInputController,
                  decoration: const InputDecoration(
                    labelText: 'Instructions (Optional)',
                    hintText: 'e.g., "Focus on research steps"',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              icon: gameProvider.isGeneratingSubquests ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) :  Icon(MdiIcons.creation, size: 16),
              label: const Text("Enhance"),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fortnitePurple),
              onPressed: gameProvider.isGeneratingSubquests ? null : () {
                gameProvider.triggerAIEnhanceTask(project, task, aiInputController.text);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleAddCheckpoint() {
    final name = _newCheckpointNameController.text.trim();
    if (name.isNotEmpty) {
      gameProvider.addCheckpoint(widget.project.id, widget.task.id, {'name': name});
      _newCheckpointNameController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _handlePlayPauseTimer() {
    final timerState = gameProvider.activeTimers[widget.task.id];
    if (timerState?.isRunning ?? false) {
      gameProvider.pauseTimer(widget.task.id);
      gameProvider.logTimerAndReset(widget.task.id);
      _timerDisplayUpdater?.cancel();
    } else {
      gameProvider.startTimer(widget.task.id, 'task', widget.project.id);
      _startTimerDisplayUpdater();
    }
    setState(() {});
  }
  
  void _handleSaveTime() {
    if (_isEditingTime) {
      final newTime = int.tryParse(_timeController.text);
      if (newTime != null && newTime != widget.task.currentTimeSpent) {
        gameProvider.updateTask(widget.project.id, widget.task.id, {'currentTimeSpent': newTime});
      }
    }
    if(mounted) {
      setState(() => _isEditingTime = false);
      FocusScope.of(context).unfocus();
    }
  }

  void _toggleTimeEdit() {
    if (_isEditingTime) {
      _handleSaveTime();
    } else {
      if (mounted) {
        setState(() {
          _isEditingTime = true;
          _timeFocusNode.requestFocus();
        });
      }
    }
  }

  void _handleCompleteTask() {
    final success = gameProvider.completeTask(widget.project.id, widget.task.id);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Cannot complete. Ensure countable tasks are at target and any sub-checkpoints are done.'),
            backgroundColor: AppTheme.fnAccentRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = widget.task;
    final timerState = gameProvider.activeTimers[task.id];
    final isTimerRunning = timerState?.isRunning ?? false;

    double currentSessionSeconds = 0;
    if (timerState != null) {
      currentSessionSeconds = timerState.accumulatedDisplayTime;
      if (isTimerRunning) {
        currentSessionSeconds += DateTime.now().difference(timerState.startTime).inSeconds;
      }
    }

    final skillChips = task.skillXp.entries.map((entry) {
      final skillId = entry.key;
      final skill = gameProvider.skills.firstWhereOrNull((s) => s.id == skillId) ?? Skill(id: '', name: entry.key);
      final projectForColor = gameProvider.projects.firstWhere(
        (p) => p.theme == skillId,
        orElse: () => Project(id: '', name: '', description: '', theme: '', colorHex: 'FF00BFFF')
      );
      final skillColor = projectForColor.color;

      return Chip(
        avatar: Icon(MdiIcons.starFourPointsOutline, color: skillColor, size: 14),
        label: Text('+${entry.value.toStringAsFixed(1)} ${skill.name} XP'),
        backgroundColor: skillColor.withAlpha((255 * 0.15).round()),
        labelStyle: TextStyle(color: skillColor, fontSize: 11, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(task.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600))),
                IconButton(
                  icon:  Icon(MdiIcons.checkCircleOutline, size: 18),
                  onPressed: _handleCompleteTask,
                  tooltip: "Complete Task",
                  style: IconButton.styleFrom(backgroundColor: AppTheme.fnAccentGreen.withAlpha((255 * 0.2).round()), foregroundColor: AppTheme.fnAccentGreen, fixedSize: const Size(32,32)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon:  Icon(MdiIcons.autoFix, size: 18),
                  onPressed: () => _showAIEnhanceDialog(context, gameProvider, widget.project, task),
                  tooltip: "Enhance with AI",
                  style: IconButton.styleFrom(backgroundColor: AppTheme.fortnitePurple.withAlpha((255 * 0.2).round()), foregroundColor: AppTheme.fortnitePurple, fixedSize: const Size(32,32)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => gameProvider.deleteTask(widget.project.id, task.id),
                  tooltip: "Delete Task",
                  style: IconButton.styleFrom(backgroundColor: AppTheme.fnAccentRed.withAlpha((255 * 0.2).round()), foregroundColor: AppTheme.fnAccentRed, fixedSize: const Size(32,32)),
                ),
              ],
            ),
            TaskProgressBar(task: task),
            const SizedBox(height: 16),
            if (skillChips.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: skillChips),
            if (skillChips.isNotEmpty) const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.fnBgMedium.withAlpha((255 * 0.5).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.fnBorderColor.withAlpha((255 * 0.5).round()))
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text("Logged (m):", style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.fnTextSecondary)),
                      const SizedBox(width: 12),
                       if (_isEditingTime)
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50, height: 32,
                                child: TextField(
                                  controller: _timeController, focusNode: _timeFocusNode,
                                  keyboardType: TextInputType.number, textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.fnTextPrimary),
                                  decoration: const InputDecoration(contentPadding: EdgeInsets.zero, border: OutlineInputBorder()),
                                  onEditingComplete: _handleSaveTime,
                                  onTapOutside: (_) => _handleSaveTime(),
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.check, size: 20), onPressed: _handleSaveTime, color: AppTheme.fnAccentGreen),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: Row(
                            children: [
                              Text(widget.task.currentTimeSpent.toString(), style: theme.textTheme.bodyLarge),
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: _toggleTimeEdit, color: AppTheme.fnTextSecondary),
                            ],
                          ),
                        ),
                    ],
                  ),
                   const SizedBox(height: 8),
                  Divider(color: AppTheme.fnBorderColor.withAlpha((255 * 0.2).round())),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                       Text("Session:", style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.fnTextSecondary)),
                       const Spacer(),
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.fnBgDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: widget.project.color.withAlpha(isTimerRunning ? (255 * 0.5).round() : (255 * 0.2).round()))
                        ),
                        child: Text(
                          helper.formatTime(currentSessionSeconds),
                          style: theme.textTheme.bodyLarge?.copyWith(fontFamily: 'Courier New', fontWeight: FontWeight.bold, color: widget.project.color)
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(isTimerRunning ? Icons.pause : Icons.play_arrow, size: 24),
                        onPressed: _handlePlayPauseTimer,
                        style: IconButton.styleFrom(backgroundColor: widget.project.color, foregroundColor: ThemeData.estimateBrightnessForColor(widget.project.color) == Brightness.dark ? Colors.white : AppTheme.fnBgDark, fixedSize: const Size(40,40), shape: const CircleBorder()),
                      )
                    ],
                  )
                ],
              )
            ),
            const SizedBox(height: 24),
            
            CheckpointList(
              project: widget.project,
              task: task,
              localCountControllers: _checkpointCountControllers,
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newCheckpointNameController,
                      decoration: const InputDecoration(hintText: 'Add a checkpoint...'),
                      onSubmitted: (_) => _handleAddCheckpoint(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.add_circle_outline, size: 24), onPressed: _handleAddCheckpoint, color: widget.project.color)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
 