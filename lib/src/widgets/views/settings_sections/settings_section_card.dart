// lib/src/widgets/views/settings_sections/settings_section_card.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const SettingsSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: (gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue), size: 22),
                const SizedBox(width: 10),
                Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            Divider(height: 24, thickness: 1, color: AppTheme.fnBorderColor.withOpacity(0.5)),
            ...children,
          ],
        ),
      ),
    );
  }
}