// lib/src/widgets/project_navigation_drawer.dart
import 'package:arcane/src/widgets/dialogs/project_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/utils/constants.dart';

class ProjectNavigationDrawer extends StatelessWidget {
  const ProjectNavigationDrawer({super.key});

  IconData _getThemeIcon(String? themeName) {
    final iconString = themeToIconName[themeName] ?? 'targetAccount';
    return MdiIcons.fromString(iconString) ?? MdiIcons.targetAccount;
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: AppTheme.fnBgDark,
      child: Column(
        children: [
          AppBar(
            title: Text('PROJECTS',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: AppTheme.fnTextPrimary, letterSpacing: 1)),
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.fnBgMedium,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(MdiIcons.plusCircleOutline,
                    color: AppTheme.fortniteBlue),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => const ProjectEditDialog(),
                ),
                tooltip: 'Add New Project',
              ),
            ],
          ),
          Expanded(
            child: gameProvider.projects.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                          'No projects available. Add one to begin.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.fnTextSecondary,
                              fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: gameProvider.projects.length,
                    itemBuilder: (context, index) {
                      final project = gameProvider.projects[index];
                      final isSelected =
                          gameProvider.selectedProjectId == project.id;
                      final projectColor = project.color;

                      return Material(
                        color: isSelected
                            ? projectColor.withAlpha(64)
                            : Colors.transparent,
                        child: ListTile(
                          leading: Icon(
                              _getThemeIcon(project.theme),
                              color: isSelected
                                  ? projectColor
                                  : AppTheme.fnTextSecondary,
                              size: 22),
                          title: Text(project.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: isSelected
                                      ? projectColor
                                      : AppTheme.fnTextPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500),
                              overflow: TextOverflow.ellipsis),
                          trailing: Wrap(spacing: 0, children: [
                            if (project.streak > 0)
                              Chip(
                                avatar: Icon(MdiIcons.fire,
                                    color: AppTheme.fnAccentOrange, size: 14),
                                label: Text('${project.streak}',
                                    style: const TextStyle(
                                        color: AppTheme.fnAccentOrange,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                backgroundColor:
                                    const Color.fromARGB(55, 0, 0, 0),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 0),
                                visualDensity: VisualDensity.compact,
                              ),
                            IconButton(
                              icon: Icon(MdiIcons.pencilOutline,
                                  size: 18,
                                  color: AppTheme.fnTextSecondary
                                      .withAlpha(179)),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (ctx) =>
                                    ProjectEditDialog(project: project),
                              ),
                              tooltip: 'Edit Project',
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 6),
                              constraints: const BoxConstraints(),
                            ),
                          ]),
                          selected: isSelected,
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            gameProvider.setSelectedProjectId(project.id);
                            if (MediaQuery.of(context).size.width < 900) {
                              Navigator.pop(context);
                            }
                          },
                          selectedTileColor: projectColor.withAlpha(38),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}