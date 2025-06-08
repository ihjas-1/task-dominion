import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String getTodayDateString() {
  return DateFormat('yyyy-MM-dd').format(DateTime.now());
}

String colorToHex(Color color) => color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

String romanize(int num) {
  if (num.isNaN || num == 0) return "0";
  if (num > 3999 || num < 1) return num.toString(); // Simplified for typical game levels

  const List<String> rnOnes = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"];
  const List<String> rnTens = ["", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"];
  const List<String> rnHundreds = ["", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"];
  const List<String> rnThousands = ["", "M", "MM", "MMM"];

  String thousands = rnThousands[(num / 1000).floor()];
  String hundreds = rnHundreds[((num % 1000) / 100).floor()];
  String tens = rnTens[((num % 100) / 10).floor()];
  String ones = rnOnes[num % 10];

  return thousands + hundreds + tens + ones;
}

double xpForLevel(int level, double xpPerLevelBase, double xpLevelMultiplier) {
  if (level <= 1) return 0;
  double totalXp = 0;
  for (int i = 1; i < level; i++) {
    totalXp += (xpPerLevelBase * (xpLevelMultiplierPow(xpLevelMultiplier, i - 1))).floor();
  }
  return totalXp;
}

double xpToNext(int currentLevel, double xpPerLevelBase, double xpLevelMultiplier) {
  return (xpPerLevelBase * (xpLevelMultiplierPow(xpLevelMultiplier, currentLevel - 1))).floorToDouble();
}

// Custom power function to avoid dart:math for simple integer powers
// ignore_for_file: non_constant_identifier_names
double xpLevelMultiplierPow(double base, int exponent) {
  double result = 1.0;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}

// Skill level calculation constants
const double skillXpPerLevelBase = 100;
const double skillLevelMultiplier = 1.15;

double skillXpForLevel(int level) {
  if (level <= 1) return 0;
  double totalXp = 0;
  for (int i = 1; i < level; i++) {
    totalXp += (skillXpPerLevelBase * (xpLevelMultiplierPow(skillLevelMultiplier, i - 1))).floor();
  }
  return totalXp;
}

double skillXpToNext(int currentLevel) {
  return (skillXpPerLevelBase * (xpLevelMultiplierPow(skillLevelMultiplier, currentLevel - 1))).floorToDouble();
}

String formatTime(double totalSeconds) {
  int hours = (totalSeconds / 3600).floor();
  int minutes = ((totalSeconds % 3600) / 60).floor();
  int seconds = (totalSeconds % 60).floor();

  String paddedHours = hours.toString().padLeft(2, '0');
  String paddedMinutes = minutes.toString().padLeft(2, '0');
  String paddedSeconds = seconds.toString().padLeft(2, '0');

  if (hours > 0) {
    return "$paddedHours:$paddedMinutes:$paddedSeconds";
  }
  return "$paddedMinutes:$paddedSeconds";
}