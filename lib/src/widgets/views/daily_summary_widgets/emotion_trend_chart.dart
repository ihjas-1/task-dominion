// lib/src/widgets/views/daily_summary_widgets/emotion_trend_chart.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EmotionTrendChart extends StatelessWidget {
final List<EmotionLog> logs;
final ThemeData theme;
final Color dynamicAccent;

const EmotionTrendChart({
super.key,
required this.logs,
required this.theme,
required this.dynamicAccent,
});

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
if (logs.length < 2) {
return SizedBox(
height: 200,
child: Center(child: Text("Need at least 2 logs for a trend line.", textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.fnTextSecondary, fontStyle: FontStyle.italic))),
);
}
List<FlSpot> spots = logs.map((log) {
final DateTime logDayMidnight = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
double xValue = log.timestamp.toLocal().difference(logDayMidnight).inMinutes / 60.0;
return FlSpot(xValue, log.rating.toDouble());
}).toList();

double dataMinX = spots.map((s) => s.x).reduce((a, b) => a < b ? a : b);
double dataMaxX = spots.map((s) => s.x).reduce((a, b) => a > b ? a : b);
double minX, maxX;

if (dataMaxX == dataMinX) {
  minX = (dataMinX - 1.0).clamp(0.0, 23.0);
  maxX = (dataMaxX + 1.0).clamp(minX + 0.1, 23.99);
} else {
  double range = dataMaxX - dataMinX;
  minX = (dataMinX - range * 0.05).clamp(0.0, 23.49);
  maxX = (dataMaxX + range * 0.05).clamp(minX + 0.1, 23.99);
}

if (maxX - minX < 0.2) {
  double midDataX = (dataMinX + dataMaxX) / 2.0;
  minX = (midDataX - 0.5).clamp(0.0, 23.0);
  maxX = (midDataX + 0.5).clamp(minX + 0.1, 23.99);
  if (maxX <= minX) { minX = 0.0; maxX = 23.99; }
}

return SizedBox(
  height: 200,
  child: LineChart(
    LineChartData(
      minX: minX, maxX: maxX, minY: 0.5, maxY: 6.5,
      gridData: FlGridData(
        show: true, drawVerticalLine: true,
        horizontalInterval: 1, verticalInterval: ((maxX - minX) / 5).clamp(0.2, 6.0),
        getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.fnBorderColor.withAlpha((255 * 0.1).round()), strokeWidth: 0.8),
        getDrawingVerticalLine: (value) => FlLine(color: AppTheme.fnBorderColor.withAlpha((255 * 0.1).round()), strokeWidth: 0.8),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, interval: 1, reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value >= 1 && value <= 6 && value == value.truncateToDouble()) return Text(value.toInt().toString(), style: const TextStyle(color: AppTheme.fnTextSecondary, fontSize: 10));
              return const Text('');
            },
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 30, interval: ((maxX - minX) / 4).ceilToDouble().clamp(0.5, 6.0),
            getTitlesWidget: (value, meta) {
              final hour = value.truncate().clamp(0, 23);
              final minute = ((value - hour) * 60).round().clamp(0, 59);
              return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(DateFormat('HH:mm').format(DateTime(2000, 1, 1, hour, minute)), style: const TextStyle(color: AppTheme.fnTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)));
            },
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.fnBorderColor.withAlpha((255 * 0.2).round()))),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.8, // Increased from 0.35 for smoother curves
          color: dynamicAccent,
          barWidth: 3,
          isStrokeCapRound: true,
          preventCurveOverShooting: true, // Prevents curve from going beyond data points
          dotData: FlDotData(
            show: true, 
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 5, // Slightly larger dots for better visibility on curves
              color: dynamicAccent.withAlpha((255 * 0.9).round()), 
              strokeWidth: 2, 
              strokeColor: AppTheme.fnBgMedium
            )
          ),
          belowBarData: BarAreaData(
            show: true, 
            color: dynamicAccent.withAlpha((255 * 0.15).round()) // Slightly more visible area
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppTheme.fnBgMedium,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
                  final logEntry = logs[spot.spotIndex];
                  return LineTooltipItem('${_getEmotionLabel(spot.y.truncate())} (${spot.y.toStringAsFixed(2)}) at ${DateFormat('HH:mm').format(logEntry.timestamp.toLocal())}', TextStyle(color: dynamicAccent, fontWeight: FontWeight.bold, fontFamily: AppTheme.fontDisplay));
                }).toList();
          },
        ),
      ),
    ),
  ),
);
}
}