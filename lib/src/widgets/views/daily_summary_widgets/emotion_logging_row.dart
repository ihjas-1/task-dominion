// lib/src/widgets/views/daily_summary_widgets/emotion_logging_row.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class EmotionLoggingRow extends StatefulWidget {
  final GameProvider gameProvider;
  final String date;
  final ThemeData theme;

  const EmotionLoggingRow({
    super.key,
    required this.gameProvider,
    required this.date,
    required this.theme,
  });

  @override
  State<EmotionLoggingRow> createState() => _EmotionLoggingRowState();
}

class _EmotionLoggingRowState extends State<EmotionLoggingRow> {
  int _hoveredPrimaryEmotion = 0;
  double _emotionIntensity = 0.5;

  IconData _getEmotionIcon(int rating) {
    switch (rating) {
      case 1: return MdiIcons.emoticonSadOutline;
      case 2: return MdiIcons.emoticonConfusedOutline;
      case 3: return MdiIcons.emoticonNeutralOutline;
      case 4: return MdiIcons.emoticonHappyOutline;
      case 5: return MdiIcons.emoticonExcitedOutline;
      default: return MdiIcons.emoticonOutline;
    }
  }

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
    return Column(
      children: [
        Text("Intensity: ${_emotionIntensity.toStringAsFixed(2)}", style: widget.theme.textTheme.labelMedium),
        Slider(
          value: _emotionIntensity,
          min: 0.0, max: 1.0, divisions: 100,
          label: _emotionIntensity.toStringAsFixed(2),
          activeColor: widget.gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue,
          inactiveColor: (widget.gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue).withAlpha((255 * 0.3).round()),
          onChanged: (double value) => setState(() => _emotionIntensity = value),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final primaryRating = index + 1;
            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredPrimaryEmotion = primaryRating),
              onExit: (_) => setState(() => _hoveredPrimaryEmotion = 0),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _hoveredPrimaryEmotion = primaryRating),
                onTapUp: (_) {
                  // Commit and reset for tap devices
                  double finalRating = (primaryRating.toDouble() + _emotionIntensity).clamp(1.0, 6.0);
                  widget.gameProvider.logEmotion(widget.date, finalRating);
                  setState(() => _hoveredPrimaryEmotion = 0);
                },
                onTapCancel: () => setState(() => _hoveredPrimaryEmotion = 0),
                onTap: () {
                  // This handles click for mouse devices
                  double finalRating = (primaryRating.toDouble() + _emotionIntensity).clamp(1.0, 6.0);
                  widget.gameProvider.logEmotion(widget.date, finalRating);
                },
                child: AnimatedScale(
                  scale: _hoveredPrimaryEmotion == primaryRating ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getEmotionIcon(primaryRating), size: 32, color: _hoveredPrimaryEmotion >= primaryRating ? _getEmotionColor(primaryRating, widget.theme) : AppTheme.fnTextDisabled),
                      const SizedBox(height: 4),
                      Text(_getEmotionLabel(primaryRating), style: widget.theme.textTheme.labelSmall?.copyWith(color: _hoveredPrimaryEmotion >= primaryRating ? _getEmotionColor(primaryRating, widget.theme) : AppTheme.fnTextDisabled, fontWeight: _hoveredPrimaryEmotion == primaryRating ? FontWeight.bold : FontWeight.normal))
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}