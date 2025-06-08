// lib/src/widgets/views/skills_view.dart
import 'package:arcane/src/widgets/components/xp_history_graph.dart';
import 'package:flutter/material.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/utils/helpers.dart' as helper;
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:collection/collection.dart';

class SkillsView extends StatefulWidget {
  const SkillsView({super.key});

  @override
  State<SkillsView> createState() => _SkillsViewState();
}

class _SkillsViewState extends State<SkillsView> {
  String? _selectedSkillIdForGraph;

  @override
  void initState() {
    super.initState();
    final skills = Provider.of<GameProvider>(context, listen: false).skills;
    if (skills.isNotEmpty) {
      _selectedSkillIdForGraph = skills.first.id;
    }
  }

  IconData _getIconData(String? iconName) {
    return MdiIcons.fromString(iconName ?? 'star-shooting-outline') ?? MdiIcons.starShootingOutline;
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final skills = gameProvider.skills;

    if (_selectedSkillIdForGraph == null && skills.isNotEmpty) {
      _selectedSkillIdForGraph = skills.first.id;
    } else if (_selectedSkillIdForGraph != null && !skills.any((s) => s.id == _selectedSkillIdForGraph)) {
      _selectedSkillIdForGraph = skills.isNotEmpty ? skills.first.id : null;
    }
    
    final selectedSkill = _selectedSkillIdForGraph != null 
      ? skills.firstWhereOrNull((s) => s.id == _selectedSkillIdForGraph)
      : null;

    final skillColor = selectedSkill != null
        ? gameProvider.projects.firstWhere(
            (project) => project.theme == selectedSkill.id,
            orElse: () => Project(id: '', name: '', description: '', theme: '', colorHex: 'FF8A2BE2'),
          ).color
        : AppTheme.fortnitePurple;


    return skills.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No skills acquired yet. Complete tasks to develop new skills.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.fnTextSecondary,
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text("Last 24h XP Gain: ${selectedSkill?.name ?? '...'}",
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                     if (_selectedSkillIdForGraph != null)
                      XpHistoryGraph(
                          selectedSkillId: _selectedSkillIdForGraph!,
                          skillColor: skillColor
                      )
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: skills.length,
                  itemBuilder: (context, index) {
                    final skill = skills[index];
                    return _buildSkillCard(context, theme, skill);
                  },
                ),
              ),
            ],
          );
  }

  Widget _buildSkillCard(BuildContext context, ThemeData theme, Skill skill) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    final projectForColor = gameProvider.projects.firstWhere(
      (project) => project.theme == skill.id,
      orElse: () => Project(id: '', name: '', description: '', theme: '', colorHex: 'FF8A2BE2'),
    );
    final skillColor = projectForColor.color;

    final double currentLevelXpStart = helper.skillXpForLevel(skill.level);
    final double xpNeededForNext = helper.skillXpToNext(skill.level);
    final double currentLevelProgress = skill.xp - currentLevelXpStart;
    final double progressPercent = xpNeededForNext > 0 ? (currentLevelProgress / xpNeededForNext).clamp(0.0, 1.0) : 0.0;
    
    final bool isSelected = _selectedSkillIdForGraph == skill.id;

    return Card(
      color: isSelected ? skillColor.withAlpha((255 * 0.15).round()) : AppTheme.fnBgMedium,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected ? BorderSide(color: skillColor, width: 1.5) : BorderSide(color: AppTheme.fnBorderColor.withAlpha((255 * 0.5).round()), width: 1)
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedSkillIdForGraph = skill.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getIconData(skill.iconName), color: skillColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(skill.name, style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.fnTextPrimary, fontWeight: FontWeight.bold, fontSize: 16))),
                  Text('LVL ${skill.level}', style: theme.textTheme.titleMedium?.copyWith(fontFamily: AppTheme.fontDisplay, color: skillColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: AppTheme.fnBorderColor.withAlpha((255 * 0.2).round()),
                    valueColor: AlwaysStoppedAnimation<Color>(skillColor.withAlpha((255 * 0.8).round())),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('XP: ${currentLevelProgress.toStringAsFixed(1)} / ${xpNeededForNext.toStringAsFixed(1)}', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fnTextSecondary, fontSize: 11)),
                  Text('Total: ${skill.xp.toStringAsFixed(1)} XP', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fnTextSecondary.withAlpha((255 * 0.7).round()), fontSize: 10)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}