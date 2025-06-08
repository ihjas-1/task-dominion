// lib/src/widgets/views/settings_sections/energy_management_settings.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/utils/constants.dart';
import 'package:arcane/src/widgets/views/settings_sections/settings_section_card.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class EnergyManagementSettings extends StatefulWidget {
  const EnergyManagementSettings({super.key});

  @override
  State<EnergyManagementSettings> createState() => _EnergyManagementSettingsState();
}

class _EnergyManagementSettingsState extends State<EnergyManagementSettings> {
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
    return SettingsSectionCard(
      icon: MdiIcons.batteryHeartVariant,
      title: 'Energy Management',
      children: [
        ElevatedButton.icon(
            icon:  Icon(MdiIcons.cashPlus, size: 18),
            label: const Text('REFILL ENERGY WITH COINS'),
            onPressed: () => _showRefillEnergyDialog(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              backgroundColor: AppTheme.fnAccentGreen,
            )),
      ],
    );
  }
}