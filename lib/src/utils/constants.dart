// lib/src/utils/constants.dart
import 'package:arcane/src/models/game_models.dart';

// Initial Project Templates
List<ProjectTemplate> initialProjectTemplates = [
  ProjectTemplate(
      id: "build_routine",
      name: "Routine & Reflection",
      description: "Establish routines, track progress, reflect.",
      theme: "order",
      colorHex: "FF4CAF50") // Green
];

// Game constants
// ignore_for_file: constant_identifier_names
const double xpPerLevelBase = 150;
const double xpLevelMultiplier = 1.22;
const double baseMaxPlayerEnergy = 100;
const double playerEnergyPerLevelVitality = 5;
const double energyRegenPerMinuteTasked = 2;
const double coinsPerEnergy = 2.5;

const double subtaskCompletionXpBase = 5;
const double subtaskCompletionCoinBase = 2;

const double xpPerMinuteSubtask = 0.2;
const double coinsPerMinuteSubtask = 0.05;
const double xpPerCountUnitSubtask = 0.5;
const double coinsPerCountUnitSubtask = 0.1;

const double subSubtaskCompletionXpBase = 1;
const double subSubtaskCompletionCoinBase = 0.5;

const double xpPerCountUnitSubSubtask = 0.1;
const double coinsPerCountUnitSubSubtask = 0.02;

const int dailyTaskGoalMinutes = 15;
const double streakBonusCoins = 10;
const double streakBonusXp = 20;

// Mapping of task themes to skill icon names
const Map<String, String> themeToIconName = {
  'tech': 'memory',
  'knowledge': 'bookOpenPageVariantOutline',
  'learning': 'schoolOutline',
  'discipline': 'karate',
  'order': 'playlistCheck',
  'health': 'heartPulse',
  'finance': 'cashMultiple',
  'creative': 'paletteOutline',
  'exploration': 'mapSearchOutline',
  'social': 'accountGroupOutline',
  'nature': 'treeOutline',
  'general': 'targetAccount',
  'default': 'starShootingOutline',
};