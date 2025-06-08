// lib/src/widgets/completed_task_card.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class CompletedTaskCard extends StatelessWidget {
  final Project project;
  final Task task;

  const CompletedTaskCard({
    super.key,
    required this.project,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    final theme = Theme.of(context);
    final completionDate = task.completedDate != null
        ? DateFormat('MMM d, yyyy').format(DateTime.parse(task.completedDate!))
        : 'N/A';

    return Card(
      color: AppTheme.fnBgMedium.withAlpha(150),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(MdiIcons.checkDecagram,
                color: AppTheme.fnAccentGreen.withAlpha(200)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: AppTheme.fnTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Completed: $completionDate',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.fnTextDisabled, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(MdiIcons.restore, size: 20),
              onPressed: () =>
                  gameProvider.duplicateCompletedTask(project.id, task.id),
              tooltip: 'Repeat Task',
              color: AppTheme.fnTextSecondary,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}