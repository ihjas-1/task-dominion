// lib/src/widgets/break_timer_banner.dart
import 'dart:async';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class BreakTimerBanner extends StatefulWidget {
  const BreakTimerBanner({super.key});

  @override
  State<BreakTimerBanner> createState() => _BreakTimerBannerState();
}

class _BreakTimerBannerState extends State<BreakTimerBanner> {
  Timer? _uiTimer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gameProvider = Provider.of<GameProvider>(context);
    if (gameProvider.breakEndTime != null) {
      _updateRemainingTime();
      if (_uiTimer == null || !_uiTimer!.isActive) {
        _startTimer();
      }
    } else {
      _uiTimer?.cancel();
    }
  }
  
  void _startTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateRemainingTime();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateRemainingTime() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final endTime = gameProvider.breakEndTime;
    if (endTime != null) {
      final now = DateTime.now();
      if (now.isBefore(endTime)) {
        setState(() {
          _remainingTime = endTime.difference(now);
        });
      } else {
        setState(() {
           _remainingTime = Duration.zero;
        });
        _uiTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final Color dynamicColor = gameProvider.getSelectedProject()?.color ?? AppTheme.fortnitePurple;

    return Material(
      color: dynamicColor.withAlpha((255 * 0.15).round()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: dynamicColor.withAlpha((255 * 0.3).round()), width: 1))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(MdiIcons.coffeeOutline, color: dynamicColor, size: 20),
            const SizedBox(width: 12),
            Text(
              'Break Time:',
              style: theme.textTheme.titleMedium?.copyWith(color: dynamicColor),
            ),
            const SizedBox(width: 8),
            Text(
              formatTime(_remainingTime.inSeconds.toDouble()),
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: AppTheme.fontDisplay,
                fontWeight: FontWeight.bold,
                color: dynamicColor,
                letterSpacing: 1.1
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                gameProvider.cancelBreak();
              },
              icon: Icon(MdiIcons.cancel, size: 16, color: AppTheme.fnAccentRed.withAlpha((255 * 0.8).round())),
              label: Text(
                'Cancel',
                style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.fnAccentRed.withAlpha((255 * 0.8).round())),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                backgroundColor: AppTheme.fnAccentRed.withAlpha((255 * 0.1).round()),
              ),
            )
          ],
        ),
      ),
    );
  }
}