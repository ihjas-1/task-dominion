// lib/src/widgets/components/project_color_picker.dart
import 'package:arcane/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ProjectColorPicker extends StatelessWidget {
final String selectedColorHex;
final ValueChanged<String> onColorSelected;

const ProjectColorPicker({
super.key,
required this.selectedColorHex,
required this.onColorSelected,
});

static final List<Color> _availableColors = [
AppTheme.fortniteBlue,
AppTheme.fortnitePurple,
AppTheme.fnAccentGreen,
AppTheme.fnAccentOrange,
AppTheme.fnAccentRed,
const Color(0xFF58D68D), // health
const Color(0xFFF1C40F), // finance
const Color(0xFFEC7063), // creative
const Color(0xFF5DADE2), // exploration
const Color(0xFFE59866), // social
const Color(0xFF2ECC71), // nature
const Color(0xFFF1948A), // Light Red
const Color(0xFF85C1E9), // Light Blue
const Color(0xFFD7BDE2), // Light Purple
const Color(0xFFFAD7A0), // Light Orange
];

String _colorToHex(Color color) {
return color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
}

@override
Widget build(BuildContext context) {
return Wrap(
spacing: 8.0,
runSpacing: 8.0,
children: _availableColors.map((color) {
final colorHex = _colorToHex(color);
final isSelectedColor = selectedColorHex == colorHex;
return GestureDetector(
onTap: () => onColorSelected(colorHex),
child: Container(
width: 32,
height: 32,
decoration: BoxDecoration(
color: color,
borderRadius: BorderRadius.circular(8),
border: isSelectedColor
? Border.all(color: Colors.white, width: 2.5)
: Border.all(color: Colors.white.withAlpha(77), width: 1),
boxShadow: isSelectedColor
? [
BoxShadow(
color: Colors.white.withOpacity(0.5),
blurRadius: 4,
spreadRadius: 1,
)
]
: [],
),
child: isSelectedColor
? Icon(
MdiIcons.check,
color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
? Colors.white
: Colors.black,
size: 18,
)
: null,
),
);
}).toList(),
);
}
}