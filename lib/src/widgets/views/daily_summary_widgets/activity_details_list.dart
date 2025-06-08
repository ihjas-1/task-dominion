// lib/src/widgets/views/daily_summary_widgets/activity_details_list.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityDetailsList extends StatelessWidget {
  final GameProvider gameProvider;
  final Map<String, dynamic> summaryData;
  final List<EmotionLog> emotionLogs;
  final ThemeData theme;
  final String selectedDate;

  const ActivityDetailsList({
    super.key,
    required this.gameProvider,
    required this.summaryData,
    required this.emotionLogs,
    required this.theme,
    required this.selectedDate,
  });

  Color _getEmotionColor(int primaryRatingCategory, ThemeData theme) {
    if (primaryRatingCategory >= 5) return theme.colorScheme.primary;
    switch (primaryRatingCategory) {
      case 1: return AppTheme.fnAccentRed;
      case 2: return AppTheme.fnAccentOrange;
      case 3: return AppTheme.fnAccentOrange;
      case 4: return AppTheme.fnAccentGreen;
      default: return AppTheme.fnTextDisabled;
    }
  }

  String _getEmotionLabel(int primaryRatingCategory) {
    if (primaryRatingCategory >= 5) return "Great";
    switch (primaryRatingCategory) {
      case 1: return "Awful";
      case 2: return "Bad";
      case 3: return "Okay";
      case 4: return "Good";
      default: return "Okay";
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskTimes = summaryData['taskTimes'] as Map<String, dynamic>? ?? {};
    final tasksCompleted = summaryData['subtasksCompleted'] as List<dynamic>? ?? [];
    final checkpointsCompleted = summaryData['checkpointsCompleted'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity Details for ${DateFormat('MMMM d').format(DateTime.parse(selectedDate))}:', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          color: AppTheme.fnBgMedium,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (taskTimes.isEmpty && tasksCompleted.isEmpty && checkpointsCompleted.isEmpty && emotionLogs.isEmpty)
                  Text("No specific activity recorded for this day.", style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.fnTextSecondary, fontStyle: FontStyle.italic))
                else ...[
                  if (emotionLogs.isNotEmpty) ...[
                    Text('Emotion Logs:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ...emotionLogs.map((log) => Padding(padding: const EdgeInsets.only(left: 16.0, top: 3.0), child: Text('- Rated ${log.rating.toStringAsFixed(2)} (${_getEmotionLabel(log.rating.truncate())}) at ${DateFormat('HH:mm').format(log.timestamp.toLocal())}', style: theme.textTheme.bodySmall?.copyWith(color: _getEmotionColor(log.rating.truncate(), theme))))),
                    const SizedBox(height: 10),
                  ],
                  ...taskTimes.entries.map((entry) {
                    final project = gameProvider.projects.firstWhere((p) => p.id == entry.key, orElse: () => Project(id: '', name: 'Unknown', description: '', theme: '', colorHex: colorToHex(AppTheme.fnTextDisabled)));
                    return Padding(padding: const EdgeInsets.symmetric(vertical: 3.0), child: Text('${project.name}: ${entry.value}m', style: theme.textTheme.bodyMedium?.copyWith(color: project.color)));
                  }),
                  if (tasksCompleted.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Tasks Completed:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ...tasksCompleted.map((taskEntryMap) {
                      final taskEntry = taskEntryMap as Map<String, dynamic>;
                      final parentProject = gameProvider.projects.firstWhere((p) => p.id == taskEntry['projectId'], orElse: () => Project(id: '', name: 'Unknown', description: '', theme: ''));
                      return Padding(padding: const EdgeInsets.only(left: 16.0, top: 3.0), child: Text('- ${taskEntry['name']} (for ${parentProject.name}) - Logged: ${taskEntry['timeLogged']}m, Count: ${taskEntry['currentCount']}/${taskEntry['targetCount']}', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fnTextSecondary)));
                    }),
                  ],
                  if (checkpointsCompleted.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Checkpoints Completed:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ...checkpointsCompleted.map((cpEntryMap) {
                      final cpEntry = cpEntryMap as Map<String, dynamic>;
                      final String projectName = cpEntry['projectName'] as String? ?? 'N/A';
                      final String parentTaskName = cpEntry['parentTaskName'] as String? ?? 'N/A';
                      final String countableInfo = (cpEntry['isCountable'] as bool? ?? false) ? " (${cpEntry['currentCount']}/${cpEntry['targetCount']})" : "";
                      return Padding(padding: const EdgeInsets.only(left: 16.0, top: 3.0), child: Text('- ${cpEntry['name']}$countableInfo (Task: "$parentTaskName" in "$projectName")', style: theme.textTheme.bodySmall?.copyWith(color: (gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue).withAlpha((255 * 0.85).round()))));
                    }),
                  ]
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
