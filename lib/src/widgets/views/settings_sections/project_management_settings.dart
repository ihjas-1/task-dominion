// lib/src/widgets/views/settings_sections/project_management_settings.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/widgets/dialogs/project_edit_dialog.dart';
import 'package:arcane/src/widgets/views/settings_sections/settings_section_card.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class ProjectManagementSettings extends StatelessWidget {
  const ProjectManagementSettings({super.key});

  void _confirmAndDelete(BuildContext context, GameProvider gameProvider, Project project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Project?', style: TextStyle(color: AppTheme.fnAccentRed)),
        content: Text('Are you sure you want to delete "${project.name}"? This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              gameProvider.deleteProject(project.id);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fnAccentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        return SettingsSectionCard(
          icon: MdiIcons.formatListChecks,
          title: 'Project Configuration',
          children: [
            Text(
              'Manage your active projects. You can edit their details or remove them entirely.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.fnTextSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            if (gameProvider.projects.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('No projects to configure.', style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.fnTextSecondary)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gameProvider.projects.length,
                itemBuilder: (ctx, index) {
                  final project = gameProvider.projects[index];
                  return ListTile(
                    leading: Icon(MdiIcons.circle, color: project.color),
                    title: Text(project.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit Project',
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => ProjectEditDialog(project: project),
                          ),
                        ),
                        IconButton(
                          icon: Icon(MdiIcons.deleteOutline, size: 20),
                          tooltip: 'Delete Project',
                          color: AppTheme.fnAccentRed.withOpacity(0.8),
                          onPressed: () => _confirmAndDelete(context, gameProvider, project),
                        ),
                      ],
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                },
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(MdiIcons.plus, size: 18),
              label: const Text('ADD NEW PROJECT'),
              onPressed: () => showDialog(context: context, builder: (_) => const ProjectEditDialog()),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            )
          ],
        );
      },
    );
  }
}