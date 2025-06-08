// lib/src/widgets/views/daily_summary_widgets/time_distribution_pie_chart.dart
import 'package:arcane/src/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TimeDistributionPieChart extends StatefulWidget {
  final List<PieChartSectionData> pieChartSections;
  final List<Widget> legendItems;

  const TimeDistributionPieChart({
    super.key,
    required this.pieChartSections,
    required this.legendItems,
  });

  @override
  State<TimeDistributionPieChart> createState() => _TimeDistributionPieChartState();
}

class _TimeDistributionPieChartState extends State<TimeDistributionPieChart> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.pieChartSections.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Create new sections with updated radius based on local state
    final List<PieChartSectionData> currentSections = [];
    for (int i = 0; i < widget.pieChartSections.length; i++) {
      final isTouched = i == _touchedPieIndex;
      final section = widget.pieChartSections[i];
      currentSections.add(section.copyWith(
        radius: isTouched ? 65.0 : 55.0,
        titleStyle: TextStyle(
          fontSize: isTouched ? 13.0 : 11.0, 
          fontWeight: FontWeight.bold, 
          color: AppTheme.fnBgDark, 
          fontFamily: AppTheme.fontDisplay, 
          shadows: const [Shadow(color: Colors.black38, blurRadius: 2)]
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Time Distribution:", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: currentSections,
                  ),
                ),
              ),
            ),
            if (widget.legendItems.isNotEmpty)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.legendItems,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}