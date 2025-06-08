// lib/src/widgets/views/settings_sections/danger_zone_settings.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/widgets/views/settings_sections/settings_section_card.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class DangerZoneSettings extends StatefulWidget {
  const DangerZoneSettings({super.key});

  @override
  State<DangerZoneSettings> createState() => _DangerZoneSettingsState();
}

class _DangerZoneSettingsState extends State<DangerZoneSettings> {
  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final theme = Theme.of(context);

    return SettingsSectionCard(
      icon: MdiIcons.databaseRemoveOutline,
      title: 'Data & System Reset',
      children: [
        ElevatedButton.icon(
          icon:  Icon(MdiIcons.undoVariant, size: 18),
          label: const Text('RESET PLAYER LEVEL'),
          onPressed: () => _showResetConfirmationDialog(
            context: context,
            title: 'Confirm',
            content: 'This will reset your player level to 1 and XP to 0. Your projects and coins will remain. Are you sure?',
            onConfirm: () {
              gameProvider.resetPlayerLevelAndProgress();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Player level and progress reset.'), backgroundColor: AppTheme.fnAccentGreen));
              }
            },
          ),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fnAccentOrange, foregroundColor: AppTheme.fnTextPrimary, minimumSize: const Size(double.infinity, 44)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon:  Icon(MdiIcons.schoolOutline, size: 18),
          label: const Text('RESET ALL SKILLS'),
          onPressed: () => _showResetConfirmationDialog(
            context: context,
            title: 'Confirm',
            content: 'This will reset all your skills to Level 1 with 0 XP. This action cannot be undone. Are you sure?',
            onConfirm: () async {
              await gameProvider.resetAllSkills();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All skills have been reset.'), backgroundColor: AppTheme.fnAccentGreen));
              }
            },
          ),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fnAccentOrange, foregroundColor: AppTheme.fnTextPrimary, minimumSize: const Size(double.infinity, 44)),
        ),
        const SizedBox(height: 16),
        Text(
          'WARNING: The "Purge All Data" protocol will erase all operational data. This action is irreversible and will reset the system to factory defaults.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fnTextSecondary, height: 1.5),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon:  Icon(MdiIcons.alertOctagonOutline, size: 18),
          label: const Text('PURGE ALL DATA'),
          onPressed: () => _showResetConfirmationDialog(
            context: context,
            title: 'Confirm',
            content: 'Are you absolutely certain you wish to erase all data? This operation cannot be undone and will result in total loss of progress.',
            onConfirm: () {
              gameProvider.clearAllGameData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All game data has been purged.'), backgroundColor: AppTheme.fnAccentGreen));
              }
            },
            isDestructive: true,
          ),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fnAccentRed, foregroundColor: AppTheme.fnTextPrimary, minimumSize: const Size(double.infinity, 44)),
        ),
      ],
    );
  }

  Future<void> _showResetConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(MdiIcons.alertOutline, color: isDestructive ? AppTheme.fnAccentRed : AppTheme.fnAccentOrange),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(color: isDestructive ? AppTheme.fnAccentRed : AppTheme.fnAccentOrange)),
        ]),
        content: Text(content),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: isDestructive ? AppTheme.fnAccentRed : AppTheme.fnAccentOrange),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      onConfirm();
    }
  }
}