// lib/src/widgets/views/daily_summary_widgets/weekly_activity_bar_chart.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyActivityBarChart extends StatelessWidget {
  final List<BarChartGroupData> weeklyBarGroups;
  final List<String> last7DaysFormatted;
  final GameProvider gameProvider;

  const WeeklyActivityBarChart({
    super.key,
    required this.weeklyBarGroups,
    required this.last7DaysFormatted,
    required this.gameProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyBarGroups.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final double maxYValue = weeklyBarGroups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Last 7 Days Activity (Total Minutes):", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        SizedBox(
          height: 280,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxYValue * 1.2 + 15,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (BarChartGroupData group) => AppTheme.fnBgMedium,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                    '${last7DaysFormatted[group.x]}\n',
                    const TextStyle(color: AppTheme.fnTextPrimary, fontWeight: FontWeight.bold, fontFamily: AppTheme.fontDisplay),
                    children: <TextSpan>[
                      TextSpan(
                        text: '${rod.toY.toStringAsFixed(0)} min',
                        style: TextStyle(color: rod.color ?? (gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue), fontWeight: FontWeight.w500, fontFamily: AppTheme.fontBody),
                      ),
                    ],
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) => SideTitleWidget(
                      meta: meta,
                      space: 10.0,
                      child: Text(
                        last7DaysFormatted[value.toInt()].substring(0, 3).toUpperCase(),
                        style: const TextStyle(color: AppTheme.fnTextSecondary, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: AppTheme.fontDisplay),
                      ),
                    ),
                    reservedSize: 38,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value == meta.max || (value == 0 && meta.max > 20)) return SideTitleWidget(meta: meta, child: Container());
                      return SideTitleWidget(meta: meta, child: Text('${value.toInt()}', style: const TextStyle(color: AppTheme.fnTextSecondary, fontSize: 11, fontFamily: AppTheme.fontBody)));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.fnBorderColor.withAlpha((255 * 0.2).round()), width: 1)),
              barGroups: weeklyBarGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                verticalInterval: 1,
                horizontalInterval: (maxYValue / 5).clamp(10, 1000),
                getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.fnBorderColor.withAlpha((255 * 0.1).round()), strokeWidth: 0.8),
                getDrawingVerticalLine: (value) => FlLine(color: AppTheme.fnBorderColor.withAlpha((255 * 0.1).round()), strokeWidth: 0.8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
