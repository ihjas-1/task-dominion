// lib/src/widgets/views/daily_summary_view.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/utils/helpers.dart';
import 'package:arcane/src/widgets/views/daily_summary_widgets/activity_details_list.dart';
import 'package:arcane/src/widgets/views/daily_summary_widgets/emotion_logging_row.dart';
import 'package:arcane/src/widgets/views/daily_summary_widgets/emotion_trend_chart.dart';
import 'package:arcane/src/widgets/views/daily_summary_widgets/time_distribution_pie_chart.dart';
import 'package:arcane/src/widgets/views/daily_summary_widgets/weekly_activity_bar_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class DailySummaryView extends StatefulWidget {
  const DailySummaryView({super.key});

  @override
  State<DailySummaryView> createState() => _DailySummaryViewState();
}

class _DailySummaryViewState extends State<DailySummaryView> {
  String? _selectedDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final availableDates = gameProvider.completedByDay.keys.toList();
    availableDates.sort((a, b) => b.compareTo(a));
    if (_selectedDate == null && availableDates.isNotEmpty) {
      _selectedDate = availableDates.first;
    } else if (_selectedDate != null && !availableDates.contains(_selectedDate)) {
      _selectedDate = availableDates.isNotEmpty ? availableDates.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final availableDates = gameProvider.completedByDay.keys.toList()..sort((a, b) => b.compareTo(a));

    if (_selectedDate == null && availableDates.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedDate = availableDates.first);
      });
    } else if (_selectedDate != null && !availableDates.contains(_selectedDate) && availableDates.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedDate = availableDates.first);
      });
    } else if (availableDates.isEmpty && _selectedDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedDate = null);
      });
    }

    final summaryData = _selectedDate != null ? gameProvider.completedByDay[_selectedDate!] : null;
    final taskTimes = summaryData?['taskTimes'] as Map<String, dynamic>? ?? {};
    final List<EmotionLog> emotionLogsForSelectedDate = _selectedDate != null ? gameProvider.getEmotionLogsForDate(_selectedDate!) : [];
    final double totalMinutesToday = taskTimes.values.fold(0.0, (sum, time) => sum + (time as num).toDouble());

    // Prepare data for Pie Chart
    final List<PieChartSectionData> pieChartSections = [];
    final List<Widget> legendItems = [];
    if (taskTimes.isNotEmpty) {
      taskTimes.forEach((projectId, time) {
        final project = gameProvider.projects.firstWhere((p) => p.id == projectId, orElse: () => Project(id: '', name: 'Unknown', description: '', theme: '', colorHex: colorToHex(AppTheme.fnTextDisabled)));
        if (project.id != '') {
          pieChartSections.add(PieChartSectionData(
            color: project.color,
            value: (time).toDouble(),
            title: '${(totalMinutesToday > 0 ? ((time as num).toDouble() / totalMinutesToday * 100) : 0.0).toStringAsFixed(0)}%',
            titlePositionPercentageOffset: 0.6,
          ));
          legendItems.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: project.color, border: Border.all(color: AppTheme.fnBorderColor.withAlpha((255 * 0.5).round()), width: 0.5))),
                const SizedBox(width: 8),
                Text(project.name.split(' ')[0], style: const TextStyle(fontSize: 12, color: AppTheme.fnTextSecondary, fontFamily: AppTheme.fontBody)),
              ],
            ),
          ));
        }
      });
    }

    // Prepare data for Bar Chart
    final List<BarChartGroupData> weeklyBarGroups = [];
    final today = DateTime.now();
    final List<String> last7DaysFormatted = [];
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      final dayData = gameProvider.completedByDay[dateStr];
      final Map<String, dynamic> dailyTaskTimes = dayData?['taskTimes'] as Map<String, dynamic>? ?? {};
      double dailyTotalMins = 0; String? dominantProjectId; int maxTime = 0;
      dailyTaskTimes.forEach((projectId, time) {
        final int currentTime = (time as num).toInt();
        dailyTotalMins += currentTime;
        if (currentTime > maxTime) { maxTime = currentTime; dominantProjectId = projectId; }
      });
      Color barColor = (gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue);
      if (dominantProjectId != null) {
        final dominantProject = gameProvider.projects.firstWhere((p) => p.id == dominantProjectId, orElse: () => Project(id: '', name: '', description: '', theme: '', colorHex: colorToHex(gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue)));
        barColor = dominantProject.color;
      }
      weeklyBarGroups.add(BarChartGroupData(x: 6 - i, barRods: [BarChartRodData(toY: dailyTotalMins, color: barColor.withAlpha((255 * 0.85).round()), width: 18, borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)))]));
      last7DaysFormatted.add(DateFormat('EEE, MMM d').format(d));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (availableDates.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 32.0), child: Text("No logs recorded yet.", style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.fnTextSecondary, fontStyle: FontStyle.italic))))
          else ...[
            DropdownButtonFormField<String>(
              value: _selectedDate,
              decoration: const InputDecoration(labelText: 'Select Date'),
              dropdownColor: AppTheme.fnBgMedium,
              items: availableDates.map((date) => DropdownMenuItem(value: date, child: Text(DateFormat('MMMM d, yyyy (EEEE)').format(DateTime.parse(date))))).toList(),
              onChanged: (value) => setState(() => _selectedDate = value),
            ),
            const SizedBox(height: 24),
            if (_selectedDate != null) ...[
              Card(color: AppTheme.fnBgMedium, child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Total Time Logged: ${totalMinutesToday.toStringAsFixed(0)}m', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.fnAccentGreen, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 12),
              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text("How are you feeling?", style: theme.textTheme.headlineSmall)),
              const SizedBox(height: 10),
              EmotionLoggingRow(gameProvider: gameProvider, date: _selectedDate!, theme: theme),
              const SizedBox(height: 8),
              if (emotionLogsForSelectedDate.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: Icon(MdiIcons.deleteSweepOutline, size: 16, color: AppTheme.fnAccentRed.withAlpha((255 * 0.7).round())),
                    label: Text("Delete Latest", style: TextStyle(color: AppTheme.fnAccentRed.withAlpha((255 * 0.7).round()), fontSize: 12)),
                    onPressed: () => gameProvider.deleteLatestEmotionLog(_selectedDate!),
                  ),
                ),
              const SizedBox(height: 16),
              if (emotionLogsForSelectedDate.isNotEmpty) ...[
                Text("Emotion Trend:", style: theme.textTheme.headlineSmall),
                const SizedBox(height: 16),
                EmotionTrendChart(logs: emotionLogsForSelectedDate, theme: theme, dynamicAccent: gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue),
                const SizedBox(height: 30),
              ],
            ],
            TimeDistributionPieChart(pieChartSections: pieChartSections, legendItems: legendItems),
            WeeklyActivityBarChart(weeklyBarGroups: weeklyBarGroups, last7DaysFormatted: last7DaysFormatted, gameProvider: gameProvider),
            if (_selectedDate != null && summaryData != null)
              ActivityDetailsList(
                gameProvider: gameProvider,
                summaryData: summaryData,
                emotionLogs: emotionLogsForSelectedDate,
                theme: theme,
                selectedDate: _selectedDate!,
              ),
          ],
        ],
      ),
    );
  }
}
