// lib/src/widgets/components/xp_history_graph.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class XpHistoryGraph extends StatelessWidget {
final String selectedSkillId;
final Color skillColor;

const XpHistoryGraph({
super.key,
required this.selectedSkillId,
required this.skillColor,
});

List<FlSpot> _getChartData(GameProvider gameProvider) {
List<Map<String, dynamic>> xpEvents = [];
final now = DateTime.now();
final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

final todayStr = DateFormat('yyyy-MM-dd').format(now);
final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

final relevantDates = [todayStr, yesterdayStr];

for (var dateStr in relevantDates) {
  final dayData = gameProvider.completedByDay[dateStr];
  if (dayData != null) {
    final checkpoints = dayData['checkpointsCompleted'] as List<dynamic>? ?? [];
    for (var cpLog in checkpoints) {
      final logMap = cpLog as Map<String, dynamic>;
      final timestamp = DateTime.tryParse(logMap['completionTimestamp'] as String? ?? '');
      if (timestamp != null && timestamp.isAfter(twentyFourHoursAgo)) {
        final double xpForSkill = (logMap['skillXp'] as Map<String, dynamic>?)?[selectedSkillId]?.toDouble() ?? 0.0;
        if (xpForSkill > 0) {
          xpEvents.add({'timestamp': timestamp, 'xp': xpForSkill});
        }
      }
    }
  }
}

if (xpEvents.isEmpty) {
  return [];
}

xpEvents.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));

List<FlSpot> spots = [];
double cumulativeXp = 0;
for (var event in xpEvents) {
  cumulativeXp += (event['xp'] as double);
  double hoursAgo = now.difference(event['timestamp'] as DateTime).inMinutes / 60.0;
  spots.add(FlSpot(24 - hoursAgo, cumulativeXp));
}

return spots;


}

@override
Widget build(BuildContext context) {
final gameProvider = context.watch<GameProvider>();
final List<FlSpot> spots = _getChartData(gameProvider);
final theme = Theme.of(context);

if (spots.isEmpty) {
  return Container(
    height: 150,
    padding: const EdgeInsets.all(16),
    child: Center(
      child: Text(
        'No XP gained for this skill in the last 24 hours. Complete checkpoints to see progress!',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.fnTextSecondary, fontStyle: FontStyle.italic),
      ),
    ),
  );
}

double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
maxY = (maxY * 1.2).ceilToDouble();
if (maxY < 10) {
  maxY = 10;
}

return SizedBox(
  height: 150,
  child: LineChart(
    LineChartData(
      minX: 0,
      maxX: 24,
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: (maxY / 4).clamp(1, 1000),
        verticalInterval: 6,
        getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.fnBorderColor.withAlpha((255 * 0.1).round()), strokeWidth: 0.8),
        getDrawingVerticalLine: (value) => FlLine(color: AppTheme.fnBorderColor.withAlpha((255 * 0.1).round()), strokeWidth: 0.8),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (maxY / 4).clamp(1, 1000),
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(value.toInt().toString(), style: const TextStyle(color: AppTheme.fnTextSecondary, fontSize: 10));
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 6,
            getTitlesWidget: (value, meta) {
              String text;
              if (value == 0) {
                text = '24h ago';
              } else if (value == 24) {
                text = 'Now';
              } else {
                text = '${(24 - value).toInt()}h ago';
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(text, style: const TextStyle(color: AppTheme.fnTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.fnBorderColor.withAlpha((255 * 0.2).round()))),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: skillColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: skillColor.withAlpha((255 * 0.2).round())),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppTheme.fnBgMedium,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
             return touchedSpots.map((spot) {
              return LineTooltipItem(
                '+${spot.y.toStringAsFixed(1)} XP',
                TextStyle(color: skillColor, fontWeight: FontWeight.bold),
              );
            }).toList();
          }
        )
      )
    ),
  ),
);

}
}