// lib/src/widgets/components/task_timer_row.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/utils/helpers.dart' as helper;
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class TaskTimerRow extends StatelessWidget {
  final String subtaskId;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ActiveTimerInfo? timerState;
  final double displayTimeSeconds;
  final bool isEditing;
  final VoidCallback onPlayPause;
  final VoidCallback onEditToggle;
  final VoidCallback onBlur;

  const TaskTimerRow({
    super.key,
    required this.subtaskId,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.timerState,
    required this.displayTimeSeconds,
    required this.isEditing,
    required this.onPlayPause,
    required this.onEditToggle,
    required this.onBlur,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameProvider = context.read<GameProvider>();
    final taskColor =
        gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue;

    return Row(
      children: [
        Flexible(
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12, color: AppTheme.fnTextSecondary)),
              ),
              SizedBox(
                width: 45,
                height: 28,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  readOnly: !isEditing,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontSize: 12, color: AppTheme.fnTextPrimary),
                  decoration: InputDecoration(
                    contentPadding: isEditing
                        ? const EdgeInsets.symmetric(vertical: 2)
                        : EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: isEditing
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                                color: theme.focusColor.withAlpha((255 * 0.5).round()),
                                width: 1))
                        : InputBorder.none,
                    focusedBorder: isEditing
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                BorderSide(color: theme.primaryColor, width: 1.5))
                        : InputBorder.none,
                    filled: true,
                    fillColor: AppTheme.fnBgDark.withAlpha((255 * 0.4).round()),
                  ),
                  onEditingComplete: onBlur,
                  onTapOutside: (_) => onBlur(),
                ),
              ),
              IconButton(
                icon: Icon(
                  isEditing ? MdiIcons.check : MdiIcons.pencilOutline,
                  color: isEditing
                      ? AppTheme.fnAccentGreen
                      : AppTheme.fnTextSecondary.withAlpha((255 * 0.7).round()),
                  size: 18,
                ),
                onPressed: onEditToggle,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(
            timerState?.isRunning ?? false
                ? MdiIcons.pauseCircleOutline
                : MdiIcons.playCircleOutline,
            color: timerState?.isRunning ?? false
                ? AppTheme.fnAccentOrange
                : AppTheme.fnAccentGreen,
            size: 24,
          ),
          onPressed: onPlayPause,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 55,
          child: Text(
            helper.formatTime(displayTimeSeconds),
            style: theme.textTheme.labelMedium?.copyWith(
                fontFamily: AppTheme.fontBody,
                color: taskColor,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}