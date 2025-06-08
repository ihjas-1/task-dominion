// lib/src/widgets/ui/rhombus_checkbox.dart
import 'package:flutter/material.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'dart:math' as math;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

enum CheckboxSize { small, medium }

class RhombusCheckbox extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool?>? onChanged;
  final bool disabled;
  final CheckboxSize size;

  const RhombusCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
    this.disabled = false,
    this.size = CheckboxSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final double dimension =
        size == CheckboxSize.small ? 18.0 : 22.0; // Overall tap target
    final double iconSize = size == CheckboxSize.small ? 12.0 : 14.0;
    final double visualDimension =
        size == CheckboxSize.small ? 15.0 : 18.0; // Visual size of rhombus
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    Color bgColor = checked
        ? (gameProvider.getSelectedProject()?.color ??
            AppTheme.fortniteBlue)
        : AppTheme.fnBgMedium;
    Color borderColor = disabled
        ? (checked
            ? (gameProvider.getSelectedProject()?.color ??
                    AppTheme.fortniteBlue)
                .withAlpha((255 * 0.5).round())
            : AppTheme.fnBorderColor.withAlpha((255 * 0.5).round()))
        : (checked
            ? (gameProvider.getSelectedProject()?.color ??
                AppTheme.fortniteBlue)
            : AppTheme.fnBorderColor);

    if (disabled && checked) {
      bgColor = (gameProvider.getSelectedProject()?.color ??
              AppTheme.fortniteBlue)
          .withAlpha((255 * 0.6).round());
    } else if (disabled && !checked) {
      bgColor = AppTheme.fnBgLight.withAlpha((255 * 0.4).round());
    }

    return InkWell(
      onTap: disabled ? null : () => onChanged?.call(!checked),
      borderRadius: BorderRadius.circular(
          dimension / 4), // Make tap effect slightly rounded
      child: SizedBox(
        width: dimension,
        height: dimension,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: math.pi / 4, // 45 degrees
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: visualDimension *
                    0.9, // Make it slightly smaller than container for padding
                width: visualDimension * 0.9,
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(
                    color: borderColor,
                    width: 1.5, // Slightly thicker border
                  ),
                ),
              ),
            ),
            if (checked)
              Icon(
                MdiIcons.checkBold, // Using MDI check for a bolder look
                size: iconSize,
                color: disabled
                    ? AppTheme.fnTextSecondary.withAlpha((255 * 0.7).round())
                    : AppTheme.fnBgDark, // Dark check on light teal
              ),
          ],
        ),
      ),
    );
  }
}