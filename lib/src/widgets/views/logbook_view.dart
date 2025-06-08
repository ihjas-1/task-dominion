// lib/src/widgets/views/logbook_view.dart
import 'package:flutter/material.dart';
import 'package:arcane/src/widgets/views/daily_summary_view.dart';

class LogbookView extends StatelessWidget {
  const LogbookView({super.key});

  @override
  Widget build(BuildContext context) {
    // The content is centered and constrained for readability on all screen sizes.
    // The FloatingActionButton is now handled by the parent screen (HomeScreen)
    // to ensure it's correctly placed within the main Scaffold.
    return  Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 900),
        child: DailySummaryView(),
      ),
    );
  }
}