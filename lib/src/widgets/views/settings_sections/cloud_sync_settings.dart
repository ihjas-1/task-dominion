// lib/src/widgets/views/settings_sections/cloud_sync_settings.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/widgets/views/settings_sections/settings_section_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class CloudSyncSettings extends StatefulWidget {
  const CloudSyncSettings({super.key});

  @override
  State<CloudSyncSettings> createState() => _CloudSyncSettingsState();
}

class _CloudSyncSettingsState extends State<CloudSyncSettings> {
  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final theme = Theme.of(context);

    String lastSavedString = "Not synced yet.";
    if (gameProvider.lastSuccessfulSaveTimestamp != null) {
      lastSavedString =
          "Last synced: ${DateFormat('MMM d, yyyy, hh:mm:ss a').format(gameProvider.lastSuccessfulSaveTimestamp!.toLocal())}";
    }

    return SettingsSectionCard(
      icon: MdiIcons.cloudSyncOutline,
      title: 'Cloud Sync',
      children: [
        ElevatedButton.icon(
          icon: gameProvider.isManuallySaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.fnTextPrimary))
              :  Icon(MdiIcons.cloudUploadOutline, size: 18),
          label: const Text('SAVE TO CLOUD NOW'),
          onPressed: gameProvider.isManuallySaving || gameProvider.isManuallyLoading
              ? null
              : () async {
                  try {
                    await gameProvider.manuallySaveToCloud();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data saved to cloud.'), backgroundColor: AppTheme.fnAccentGreen));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cloud save failed: ${e.toString()}'), backgroundColor: AppTheme.fnAccentRed));
                  }
                },
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: gameProvider.isManuallyLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.fnTextPrimary))
              :  Icon(MdiIcons.cloudDownloadOutline, size: 18),
          label: const Text('LOAD FROM CLOUD'),
          onPressed: gameProvider.isManuallySaving || gameProvider.isManuallyLoading
              ? null
              : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Row(children:  [
                        Icon(MdiIcons.cloudQuestionOutline, color: AppTheme.fnAccentOrange),
                        SizedBox(width: 10),
                        Text('Confirm Load')
                      ]),
                      content: const Text('This will overwrite any local unsaved changes with data from the cloud. Are you sure?'),
                      actionsAlignment: MainAxisAlignment.spaceBetween,
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL')),
                        ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fnAccentOrange), child: const Text('CONFIRM LOAD')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await gameProvider.manuallyLoadFromCloud();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data loaded from cloud.'), backgroundColor: AppTheme.fnAccentGreen));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cloud load failed: ${e.toString()}'), backgroundColor: AppTheme.fnAccentRed));
                    }
                  }
                },
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            lastSavedString,
            style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.fnTextSecondary.withAlpha((255 * 0.8).round()), fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Note: Game progress is saved to the cloud in near real-time. Use these options for immediate manual sync or recovery.",
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fnTextSecondary.withAlpha((255 * 0.8).round()), fontSize: 10),
        ),
      ],
    );
  }
}