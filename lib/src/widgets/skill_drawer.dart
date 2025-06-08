// lib/src/widgets/skill_drawer.dart
import 'package:arcane/src/widgets/views/skills_view.dart';
import 'package:flutter/material.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SkillDrawer extends StatelessWidget {
  const SkillDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: AppTheme.fnBgDark,
      child: Column(
        children: [
          AppBar(
            title: Text('SKILLS',
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.fnTextPrimary, letterSpacing: 1)),
            leading: Icon(MdiIcons.atom, color: theme.colorScheme.primary),
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.fnBgMedium,
            elevation: 0,
          ),
          const Expanded(
            child: SkillsView(),
          ),
        ],
      ),
    );
  }
}