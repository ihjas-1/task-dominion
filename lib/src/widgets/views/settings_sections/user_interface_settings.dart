// lib/src/widgets/views/settings_sections/user_interface_settings.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/widgets/views/settings_sections/settings_section_card.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class UserInterfaceSettings extends StatelessWidget {
  const UserInterfaceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        return SettingsSectionCard(
          icon: MdiIcons.eyeSettingsOutline,
          title: 'User Interface',
          children: [
            SwitchListTile.adaptive(
              title: const Text('Verbose Data Display'),
              subtitle: const Text('Show detailed descriptions for stats and items.'),
              value: gameProvider.settings.descriptionsVisible,
              onChanged: (value) => gameProvider.setSettings(gameProvider.settings..descriptionsVisible = value),
              activeColor: (gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        );
      },
    );
  }
}