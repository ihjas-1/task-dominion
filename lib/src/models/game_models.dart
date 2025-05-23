// lib/src/models/game_models.dart
import 'package:myapp_flutter/src/utils/constants.dart'; // For basePlayerGameStats, playerEnergyPerLevel
import 'package:collection/collection.dart'; // For firstWhereOrNull

class MainTask {
  String id;
  String name;
  String description;
  String theme;
  int streak;
  int dailyTimeSpent;
  String? lastWorkedDate;
  List<SubTask> subTasks;

  MainTask({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    this.streak = 0,
    this.dailyTimeSpent = 0,
    this.lastWorkedDate,
    List<SubTask>? subTasks,
  }) : subTasks = subTasks ?? [];

  factory MainTask.fromTemplate(MainTaskTemplate template) {
    return MainTask(
      id: template.id,
      name: template.name,
      description: template.description,
      theme: template.theme,
    );
  }

  factory MainTask.fromJson(Map<String, dynamic> json) {
    return MainTask(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      theme: json['theme'] as String,
      streak: json['streak'] as int? ?? 0,
      dailyTimeSpent: json['dailyTimeSpent'] as int? ?? 0,
      lastWorkedDate: json['lastWorkedDate'] as String?,
      subTasks: (json['subTasks'] as List<dynamic>?)
              ?.map((stJson) => SubTask.fromJson(stJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'theme': theme,
      'streak': streak,
      'dailyTimeSpent': dailyTimeSpent,
      'lastWorkedDate': lastWorkedDate,
      'subTasks': subTasks.map((st) => st.toJson()).toList(),
    };
  }
}

class SubTask {
  String id;
  String name;
  bool completed;
  int currentTimeSpent; // Storing as minutes
  String? completedDate;
  bool isCountable;
  int targetCount;
  int currentCount;
  List<SubSubTask> subSubTasks;

  SubTask({
    required this.id,
    required this.name,
    this.completed = false,
    this.currentTimeSpent = 0,
    this.completedDate,
    this.isCountable = false,
    this.targetCount = 0,
    this.currentCount = 0,
    List<SubSubTask>? subSubTasks,
  }) : subSubTasks = subSubTasks ?? [];

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as String,
      name: json['name'] as String,
      completed: json['completed'] as bool? ?? false,
      currentTimeSpent: json['currentTimeSpent'] as int? ?? 0,
      completedDate: json['completedDate'] as String?,
      isCountable: json['isCountable'] as bool? ?? false,
      targetCount: json['targetCount'] as int? ?? 0,
      currentCount: json['currentCount'] as int? ?? 0,
      subSubTasks: (json['subSubTasks'] as List<dynamic>?)
              ?.map((sssJson) => SubSubTask.fromJson(sssJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'completed': completed,
      'currentTimeSpent': currentTimeSpent,
      'completedDate': completedDate,
      'isCountable': isCountable,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'subSubTasks': subSubTasks.map((sss) => sss.toJson()).toList(),
    };
  }
}

class SubSubTask {
  String id;
  String name;
  bool completed;
  bool isCountable;
  int targetCount;
  int currentCount;

  SubSubTask({
    required this.id,
    required this.name,
    this.completed = false,
    this.isCountable = false,
    this.targetCount = 0,
    this.currentCount = 0,
  });

  factory SubSubTask.fromJson(Map<String, dynamic> json) {
    return SubSubTask(
      id: json['id'] as String,
      name: json['name'] as String,
      completed: json['completed'] as bool? ?? false,
      isCountable: json['isCountable'] as bool? ?? false,
      targetCount: json['targetCount'] as int? ?? 0,
      currentCount: json['currentCount'] as int? ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'completed': completed,
      'isCountable': isCountable,
      'targetCount': targetCount,
      'currentCount': currentCount,
    };
  }
}

class OwnedArtifact {
  String uniqueId;
  String templateId;
  int currentLevel;
  int? uses;

  OwnedArtifact({
    required this.uniqueId,
    required this.templateId,
    required this.currentLevel,
    this.uses,
  });

  factory OwnedArtifact.fromJson(Map<String, dynamic> json) {
    return OwnedArtifact(
      uniqueId: json['uniqueId'] as String,
      templateId: json['templateId'] as String,
      currentLevel: json['currentLevel'] as int,
      uses: json['uses'] as int?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'uniqueId': uniqueId,
      'templateId': templateId,
      'currentLevel': currentLevel,
      'uses': uses,
    };
  }
}

class CurrentGame {
  EnemyTemplate? enemy;
  double playerCurrentHp;
  List<String> log;

  CurrentGame({
    this.enemy,
    required this.playerCurrentHp,
    List<String>? log,
  }) : log = log ?? [];

  factory CurrentGame.fromJson(Map<String, dynamic> json, List<EnemyTemplate> allEnemyTemplates) {
    EnemyTemplate? currentEnemy;
    if (json['enemy'] != null) {
      final enemyData = json['enemy'] as Map<String, dynamic>;
      currentEnemy = allEnemyTemplates.firstWhereOrNull((t) => t.id == enemyData['id']) ?? EnemyTemplate.fromJson(enemyData);
    }
    return CurrentGame(
      enemy: currentEnemy,
      playerCurrentHp: (json['playerCurrentHp'] as num).toDouble(),
      log: (json['log'] as List<dynamic>?)?.map((entry) => entry as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enemy': enemy?.toJson(),
      'playerCurrentHp': playerCurrentHp,
      'log': log,
    };
  }
}

class GameSettings {
  bool descriptionsVisible;
  bool autoGenerateContent;

  GameSettings({this.descriptionsVisible = true, this.autoGenerateContent = true});

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      descriptionsVisible: json['descriptionsVisible'] as bool? ?? true,
      autoGenerateContent: json['autoGenerateContent'] as bool? ?? true,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'descriptionsVisible': descriptionsVisible,
      'autoGenerateContent': autoGenerateContent,
    };
  }
}

class ActiveTimerInfo {
  DateTime startTime;
  double accumulatedDisplayTime; // In seconds
  bool isRunning;
  String type;
  String mainTaskId;

  ActiveTimerInfo({
    required this.startTime,
    this.accumulatedDisplayTime = 0,
    required this.isRunning,
    required this.type,
    required this.mainTaskId,
  });

  factory ActiveTimerInfo.fromJson(Map<String, dynamic> json) {
    return ActiveTimerInfo(
      startTime: DateTime.parse(json['startTime'] as String),
      accumulatedDisplayTime: (json['accumulatedDisplayTime'] as num? ?? 0).toDouble(),
      isRunning: json['isRunning'] as bool? ?? false,
      type: json['type'] as String? ?? 'subtask',
      mainTaskId: json['mainTaskId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'accumulatedDisplayTime': accumulatedDisplayTime,
      'isRunning': isRunning,
      'type': type,
      'mainTaskId': mainTaskId,
    };
  }
}

// Player Stat Data Class
class PlayerStat {
  final String name;
  final String description;
  final String icon; // Emoji icon
  double value;
  double base;

  PlayerStat({
    required this.name,
    required this.description,
    required this.icon,
    required this.value,
    required this.base,
  });

  factory PlayerStat.fromJson(Map<String, dynamic> json) {
    // Helper for parsing numbers, gracefully handling int, double, or String.
    double parseNumToDouble(dynamic val, double defaultValue, String fieldName) {
      if (val == null) {
        // print("[PlayerStat.fromJson] Warning: Field '$fieldName' is null. Using default: $defaultValue");
        return defaultValue;
      }
      if (val is num) return val.toDouble();
      if (val is String) {
        final parsed = double.tryParse(val);
        if (parsed != null) return parsed;
        // print("[PlayerStat.fromJson] Warning: Field '$fieldName' (String value: '$val') could not be parsed to double. Using default: $defaultValue");
        return defaultValue;
      }
      // print("[PlayerStat.fromJson] Warning: Field '$fieldName' (value: '$val', type ${val.runtimeType}) could not be parsed to double. Using default: $defaultValue.");
      return defaultValue;
    }

    String parseString(dynamic val, String defaultValue, String fieldName) {
      if (val == null) {
        // print("[PlayerStat.fromJson] Warning: Field '$fieldName' is null. Using default: '$defaultValue'");
        return defaultValue;
      }
      if (val is String) return val;
      // print("[PlayerStat.fromJson] Warning: Field '$fieldName' (value: '$val', type ${val.runtimeType}) is not a String. Using toString() or default: '$defaultValue'.");
      return val.toString(); // Fallback, or could be stricter
    }

    return PlayerStat(
      name: parseString(json['name'], 'Unknown Stat', 'name'),
      description: parseString(json['description'], 'No description.', 'description'),
      icon: parseString(json['icon'], '❓', 'icon'),
      value: parseNumToDouble(json['value'], 0.0, 'value'),
      base: parseNumToDouble(json['base'], 0.0, 'base'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'value': value,
      'base': base,
    };
  }
}

// Example Structure for ArtifactTemplate (used for AI generation and in GameProvider)
class ArtifactTemplate {
  final String id;
  final String name;
  final String type; // 'weapon', 'armor', 'talisman', 'powerup'
  final String? theme;
  final String description;
  final int cost;
  final String icon; // Emoji
  // Stats for equippable items
  final int? baseAtt;
  final int? baseRunic;
  final int? baseDef;
  final int? baseHealth;
  final int? baseLuck; // Percentage
  final int? baseCooldown; // Percentage
  final double? bonusXPMod; // Decimal, e.g., 0.05 for 5%
  final Map<String, int>? upgradeBonus; // e.g., {"att": 2, "luck": 1}
  final int? maxLevel;
  // For powerups
  final String? effectType; // 'direct_damage', 'heal_player'
  final int? effectValue;
  final int? uses;

  ArtifactTemplate({
    required this.id,
    required this.name,
    required this.type,
    this.theme,
    required this.description,
    required this.cost,
    required this.icon,
    this.baseAtt,
    this.baseRunic,
    this.baseDef,
    this.baseHealth,
    this.baseLuck,
    this.baseCooldown,
    this.bonusXPMod,
    this.upgradeBonus,
    this.maxLevel,
    this.effectType,
    this.effectValue,
    this.uses,
  });

  factory ArtifactTemplate.fromJson(Map<String, dynamic> json) {
    Map<String, int>? parsedUpgradeBonus;
    if (json['upgradeBonus'] != null && json['upgradeBonus'] is Map) {
      parsedUpgradeBonus = {};
      try {
        (json['upgradeBonus'] as Map<String, dynamic>).forEach((key, value) {
          if (value is num) {
            parsedUpgradeBonus![key] = value.toInt();
          } else if (value is String) {
            final parsedNum = int.tryParse(value);
            if (parsedNum != null) {
              parsedUpgradeBonus![key] = parsedNum;
            } else {
              // print("[ArtifactTemplate.fromJson] Warning: upgradeBonus string value for key '$key' is not a valid integer: '$value'. Skipping.");
            }
          } else {
            // print("[ArtifactTemplate.fromJson] Warning: upgradeBonus value for key '$key' is of unexpected type: ${value.runtimeType}. Value: '$value'. Skipping.");
          }
        });
      } catch (e) {
        // print("[ArtifactTemplate.fromJson] Error processing upgradeBonus: $e. Raw: ${json['upgradeBonus']}");
      }
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val);
      // print("[ArtifactTemplate.fromJson] Warning: Could not parse value '$val' to int.");
      return null;
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) return double.tryParse(val);
      // print("[ArtifactTemplate.fromJson] Warning: Could not parse value '$val' to double.");
      return null;
    }

    return ArtifactTemplate(
      id: json['id'] as String? ?? 'unknown_id_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Unknown Artifact',
      type: json['type'] as String? ?? 'unknown',
      theme: json['theme'] as String?,
      description: json['description'] as String? ?? 'No description.',
      cost: parseInt(json['cost']) ?? 0,
      icon: json['icon'] as String? ?? '❓',
      baseAtt: parseInt(json['baseAtt']),
      baseRunic: parseInt(json['baseRunic']),
      baseDef: parseInt(json['baseDef']),
      baseHealth: parseInt(json['baseHealth']),
      baseLuck: parseInt(json['baseLuck']),
      baseCooldown: parseInt(json['baseCooldown']),
      bonusXPMod: parseDouble(json['bonusXPMod']),
      upgradeBonus: parsedUpgradeBonus,
      maxLevel: parseInt(json['maxLevel']),
      effectType: json['effectType'] as String?,
      effectValue: parseInt(json['effectValue']),
      uses: parseInt(json['uses']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'theme': theme,
      'description': description,
      'cost': cost,
      'icon': icon,
      'baseAtt': baseAtt,
      'baseRunic': baseRunic,
      'baseDef': baseDef,
      'baseHealth': baseHealth,
      'baseLuck': baseLuck,
      'baseCooldown': baseCooldown,
      'bonusXPMod': bonusXPMod,
      'upgradeBonus': upgradeBonus,
      'maxLevel': maxLevel,
      'effectType': effectType,
      'effectValue': effectValue,
      'uses': uses,
    };
  }
}

// Example Structure for EnemyTemplate
class EnemyTemplate {
  final String id;
  final String name;
  final String? theme;
  final int minPlayerLevel;
  final int health; // Max health
  final int attack;
  final int defense;
  int hp; // Current health, mutable
  final int coinReward;
  final int xpReward;
  final String description;

  EnemyTemplate({
    required this.id,
    required this.name,
    this.theme,
    required this.minPlayerLevel,
    required this.health,
    required this.attack,
    required this.defense,
    int? hp, // Allow optional current hp for initialization
    required this.coinReward,
    required this.xpReward,
    required this.description,
  }) : hp = hp ?? health; // Default current hp to max health

  factory EnemyTemplate.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val);
      // print("[EnemyTemplate.fromJson] Warning: Could not parse value '$val' to int.");
      return null;
    }

    final maxHealth = parseInt(json['health']) ?? 10;
    return EnemyTemplate(
      id: json['id'] as String? ?? 'unknown_enemy_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Nameless Foe',
      theme: json['theme'] as String?,
      minPlayerLevel: parseInt(json['minPlayerLevel']) ?? 1,
      health: maxHealth,
      // If 'hp' is present in JSON (e.g. from saved game state), use it, otherwise default to maxHealth.
      // This is important for when loading a CurrentGame where an enemy might not be at full health.
      hp: parseInt(json['hp']) ?? maxHealth,
      attack: parseInt(json['attack']) ?? 1,
      defense: parseInt(json['defense']) ?? 0,
      coinReward: parseInt(json['coinReward']) ?? 0,
      xpReward: parseInt(json['xpReward']) ?? 0,
      description: json['description'] as String? ?? 'A mysterious enemy.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'theme': theme,
      'minPlayerLevel': minPlayerLevel,
      'health': health, // Max health
      'hp': hp, // Current health
      'attack': attack,
      'defense': defense,
      'coinReward': coinReward,
      'xpReward': xpReward,
      'description': description,
    };
  }
}