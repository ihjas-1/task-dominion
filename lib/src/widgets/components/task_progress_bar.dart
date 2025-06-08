 
// lib/src/widgets/components/task_progress_bar.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:flutter/material.dart';

class TaskProgressBar extends StatelessWidget {
  final Task task;

  const TaskProgressBar({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double progressPercent = 0.0;
    String progressText = '';

    if (task.checkpoints.isNotEmpty) {
      final completed = task.checkpoints.where((cp) => cp.completed).length;
      final total = task.checkpoints.length;
      progressPercent = total > 0 ? (completed / total) : 0.0;
      progressText = '$completed / $total Checkpoints';
    } else if (task.isCountable && task.targetCount > 0) {
      progressPercent = (task.currentCount / task.targetCount).clamp(0.0, 1.0);
      progressText = '${task.currentCount} / ${task.targetCount} Reps';
    }

    if (progressText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progressPercent,
              backgroundColor: AppTheme.fnBorderColor.withAlpha((255 * 0.2).round()),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.fortnitePurple),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(progressText,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontSize: 10, color: AppTheme.fnTextSecondary)),
        const SizedBox(height: 12),
      ],
    );
  }
}
 