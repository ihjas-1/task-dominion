// lib/src/widgets/header_widget.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/screens/logbook_screen.dart';
import 'package:arcane/src/screens/settings_screen.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:arcane/src/utils/helpers.dart' as helper;
import 'package:arcane/src/utils/constants.dart';

class HeaderWidget extends StatefulWidget {
  final String currentViewLabel;
  final bool isMobile;
  const HeaderWidget({super.key, required this.currentViewLabel, this.isMobile = false});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
    void _showRefillEnergyDialog(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    double energyToRefill = 0;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final double maxRefillable = gameProvider.calculatedMaxEnergy - gameProvider.playerEnergy;
            final double maxAffordable = gameProvider.coins / coinsPerEnergy;
            final double maxCanRefill = (maxRefillable < maxAffordable) ? maxRefillable : maxAffordable;
            final double cost = energyToRefill * coinsPerEnergy;

            return AlertDialog(
              title: Text('Refill Energy', style: TextStyle(color: (gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Current Energy: ${gameProvider.playerEnergy.toStringAsFixed(0)} / ${gameProvider.calculatedMaxEnergy.toStringAsFixed(0)}'),
                  const SizedBox(height: 24),
                  if (maxCanRefill <= 0)
                    Text(
                      gameProvider.playerEnergy >= gameProvider.calculatedMaxEnergy ? 'Energy is already full!' : 'Not enough coins to refill energy.',
                      style: const TextStyle(color: AppTheme.fnAccentOrange),
                    )
                  else ...[
                    Text('Refill by: ${energyToRefill.toStringAsFixed(0)} (Cost: ${cost.toStringAsFixed(1)} coins)', style: Theme.of(context).textTheme.bodyLarge),
                    Slider(
                      value: energyToRefill,
                      min: 0,
                      max: maxCanRefill.floorToDouble(),
                      divisions: maxCanRefill.floor() > 0 ? maxCanRefill.floor() : 1,
                      label: energyToRefill.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() {
                          energyToRefill = value;
                        });
                      },
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: (energyToRefill > 0) ? () {
                    gameProvider.refillEnergyWithCoins(energyToRefill.toInt());
                    Navigator.of(ctx).pop();
                  } : null,
                  child: const Text('Purchase'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final Color currentAccentColor =
        gameProvider.getSelectedProject()?.color ??
            theme.colorScheme.secondary;

    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: kToolbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: <Widget>[
                if (widget.isMobile)
                  IconButton(
                    icon: Icon(MdiIcons.formatListChecks, color: AppTheme.fnTextSecondary),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Scaffold.of(context).openDrawer();
                    },
                    tooltip: 'Projects',
                  ),
                if (!widget.isMobile)
                  Icon(MdiIcons.shieldCrownOutline, color: currentAccentColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: gameProvider.isGeneratingContent ? 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: currentAccentColor)),
                      SizedBox(width: 8),
                      Text("AI is working...", style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.fnTextSecondary),)
                    ],
                  ) :
                  Text(
                    widget.currentViewLabel,
                    style: theme.textTheme.headlineSmall?.copyWith(color: AppTheme.fnTextPrimary, letterSpacing: 1.0),
                    textAlign: widget.isMobile ? TextAlign.center : TextAlign.center,
                  ),
                ),
                if (!widget.isMobile) ...[
                  IconButton(
                    icon: Icon(MdiIcons.atom, color: AppTheme.fnTextSecondary),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Scaffold.of(context).openEndDrawer();
                    },
                    tooltip: 'Skills',
                  ),
                  IconButton(
                    icon: Icon(MdiIcons.bookOpenVariant, color: AppTheme.fnTextSecondary),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LogbookScreen()));
                    },
                    tooltip: 'Logbook',
                  ),
                ],
                IconButton(
                  icon: Icon(MdiIcons.cogOutline, color: AppTheme.fnTextSecondary),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  },
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            decoration: BoxDecoration(
                color: AppTheme.fnBgDark.withAlpha((255 * 0.5).round()),
                border: Border(bottom: BorderSide(color: AppTheme.fnBorderColor.withAlpha((255 * 0.3).round()), width: 1))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip(theme, icon: MdiIcons.circleMultipleOutline, value: gameProvider.coins.toStringAsFixed(0), color: AppTheme.fnAccentOrange),
                const SizedBox(width: 20),
                InkWell(
                  onTap: () => _showRefillEnergyDialog(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: _buildStatChip(
                      theme,
                      icon: MdiIcons.flashOutline,
                      value: '${gameProvider.playerEnergy.toStringAsFixed(0)}/${gameProvider.calculatedMaxEnergy.toStringAsFixed(0)}',
                      color: gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                _buildStatChip(theme, icon: MdiIcons.starShootingOutline, value: 'Lvl ${helper.romanize(gameProvider.playerLevel)}', color: currentAccentColor),
                const SizedBox(width: 4),
                Expanded(
                  child: SizedBox(
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (gameProvider.xpProgressPercent / 100).clamp(0.0, 1.0),
                        backgroundColor: AppTheme.fnBorderColor.withAlpha((255 * 0.2).round()),
                        valueColor: AlwaysStoppedAnimation<Color>(currentAccentColor.withAlpha((255 * 0.7).round())),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(ThemeData theme, {required IconData icon, required String value, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.fnTextPrimary, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}