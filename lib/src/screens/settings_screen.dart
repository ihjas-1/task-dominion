import 'package:arcane/src/widgets/views/settings_sections/cloud_sync_settings.dart';
import 'package:arcane/src/widgets/views/settings_sections/danger_zone_settings.dart';
import 'package:arcane/src/widgets/views/settings_sections/energy_management_settings.dart';
import 'package:arcane/src/widgets/views/settings_sections/project_management_settings.dart';
import 'package:arcane/src/widgets/views/settings_sections/skill_management_settings.dart';
import 'package:arcane/src/widgets/views/settings_sections/user_access_settings.dart';
import 'package:arcane/src/widgets/views/settings_sections/user_interface_settings.dart';
import 'package:flutter/material.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Config'),
        backgroundColor: AppTheme.fnBgMedium,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: const SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CloudSyncSettings(),
                UserAccessSettings(),
                ProjectManagementSettings(),
                EnergyManagementSettings(),
                UserInterfaceSettings(),
                SkillManagementSettings(),
                DangerZoneSettings(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}