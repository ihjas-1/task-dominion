 
// lib/src/widgets/components/checkpoint_list.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/widgets/ui/rhombus_checkbox.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class CheckpointList extends StatelessWidget {
  final Project project;
  final Task task;
  final Map<String, TextEditingController> localCountControllers;

  const CheckpointList({
    super.key,
    required this.project,
    required this.task,
    required this.localCountControllers,
  });

  void _handleCheckboxChange(BuildContext context, GameProvider gp,
      Project project, Task parentTask, Checkpoint checkpoint) {
    if (checkpoint.isCountable) {
      final currentCount = int.tryParse(
              localCountControllers[checkpoint.id]?.text ?? '0') ??
          checkpoint.currentCount;
      if (currentCount < checkpoint.targetCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Please complete the target count (${checkpoint.targetCount}) for this step before marking as done.'),
              backgroundColor: AppTheme.fnAccentRed),
        );
        return;
      }
    }
    gp.completeCheckpoint(project.id, parentTask.id, checkpoint.id);
  }

  void _handleCountBlur(BuildContext context, GameProvider gp, Project project,
      Task parentTask, Checkpoint checkpoint) {
    if (checkpoint.isCountable) {
      final newCount = int.tryParse(
              localCountControllers[checkpoint.id]?.text ?? '0') ??
          checkpoint.currentCount;
      if (newCount != checkpoint.currentCount) {
        gp.updateCheckpoint(project.id, parentTask.id, checkpoint.id,
            {'currentCount': newCount.clamp(0, checkpoint.targetCount)});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameProvider = context.read<GameProvider>();
    final completedCheckpoints =
        task.checkpoints.where((cp) => cp.completed).length;
    final totalCheckpoints = task.checkpoints.length;
    final checkpointProgress = totalCheckpoints > 0
        ? (completedCheckpoints / totalCheckpoints)
        : 0.0;
        
    final sortedCheckpoints = List<Checkpoint>.from(task.checkpoints)
      ..sort((a,b) => a.completed == b.completed ? 0 : (a.completed ? 1 : -1));


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Checkpoints:',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.fnTextSecondary.withAlpha((255 * 0.8).round()),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: checkpointProgress,
                    backgroundColor: AppTheme.fnBorderColor.withAlpha((255 * 0.3).round()),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.fortnitePurple),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedCheckpoints.length,
            itemBuilder: (sctx, sIndex) {
              final cp = sortedCheckpoints[sIndex];
              final skillXpChips = cp.skillXp.entries.map((entry) {
                final skillId = entry.key;
                final skill = gameProvider.skills.firstWhereOrNull((s) => s.id == skillId) ?? Skill(id: '', name: entry.key);
                final projectForColor = gameProvider.projects.firstWhere(
                  (p) => p.theme == skillId,
                  orElse: () => Project(id: '', name: '', description: '', theme: '', colorHex: 'FF00BFFF')
                );
                final skillColor = projectForColor.color;

                return Chip(
                  label: Text(
                      '+${entry.value.toStringAsFixed(1)} ${skill.name} XP'),
                  avatar: Icon(MdiIcons.starFourPointsOutline,
                      size: 10, color: skillColor),
                  backgroundColor: skillColor.withAlpha((255 * 0.1).round()),
                  labelStyle: TextStyle(
                      fontSize: 9, color: skillColor.withAlpha((255 * 0.9).round())),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  visualDensity: VisualDensity.compact,
                );
              }).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0, left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                            width: 20,
                            height: 20,
                            child: RhombusCheckbox(
                              checked: cp.completed,
                              onChanged: cp.completed
                                  ? null
                                  : (bool? val) => _handleCheckboxChange(
                                      context, gameProvider, project, task, cp),
                              disabled: cp.completed,
                              size: CheckboxSize.small,
                            )),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                '${cp.name}${cp.isCountable && !cp.completed ? ' (${localCountControllers[cp.id]?.text ?? cp.currentCount}/${cp.targetCount})' : (cp.isCountable && cp.completed ? ' (${cp.currentCount}/${cp.targetCount})' : '')}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  decoration: cp.completed
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: cp.completed
                                      ? AppTheme.fnTextSecondary
                                          .withAlpha((255 * 0.6).round())
                                      : AppTheme.fnTextSecondary,
                                ))),
                        if (cp.isCountable && !cp.completed)
                          SizedBox(
                            width: 35,
                            height: 22,
                            child: TextField(
                              controller: localCountControllers[cp.id],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: AppTheme.fnTextPrimary),
                              decoration: const InputDecoration(
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 1),
                                  border: InputBorder.none,
                                  filled: false),
                              onEditingComplete: () => _handleCountBlur(context,
                                  gameProvider, project, task, cp),
                              onTapOutside: (_) => _handleCountBlur(
                                  context, gameProvider, project, task, cp),
                            ),
                          ),
                        if (cp.completed)
                          IconButton(
                            icon: Icon(MdiIcons.restore, color: AppTheme.fnTextSecondary.withAlpha(179), size: 16),
                            tooltip: 'Repeat Checkpoint',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => gameProvider.duplicateCheckpoint(project.id, task.id, cp.id),
                          )
                        else
                          IconButton(
                              icon: Icon(MdiIcons.deleteOutline,
                                  color: AppTheme.fnAccentRed.withAlpha((255 * 0.7).round()),
                                  size: 16),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => gameProvider.deleteCheckpoint(
                                  project.id, task.id, cp.id)),
                      ],
                    ),
                    if (skillXpChips.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 28.0, top: 4),
                        child: Wrap(
                            spacing: 4, runSpacing: 4, children: skillXpChips),
                      ),
                    ]
                  ],
                ),
              );
            }),
      ],
    );
  }
}
 