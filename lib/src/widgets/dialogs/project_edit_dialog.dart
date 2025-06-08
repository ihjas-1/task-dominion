// lib/src/widgets/dialogs/project_edit_dialog.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/widgets/components/project_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class ProjectEditDialog extends StatefulWidget {
final Project? project;

const ProjectEditDialog({super.key, this.project});

bool get isEditMode => project != null;

@override
State<ProjectEditDialog> createState() => _ProjectEditDialogState();
}

class _ProjectEditDialogState extends State<ProjectEditDialog> {
final _formKey = GlobalKey<FormState>();
late TextEditingController _nameController;
late TextEditingController _descController;
late TextEditingController _themeController;
late String _selectedColorHex;

@override
void initState() {
super.initState();
_nameController = TextEditingController(text: widget.project?.name ?? '');
_descController = TextEditingController(text: widget.project?.description ?? '');
_themeController = TextEditingController(text: widget.project?.theme ?? '');
_selectedColorHex = widget.project?.colorHex ?? '00BFFF'; // Default to fortnite blue
}

@override
void dispose() {
_nameController.dispose();
_descController.dispose();
_themeController.dispose();
super.dispose();
}

void _handleSaveChanges() {
if (!_formKey.currentState!.validate()) {
return;
}

final gameProvider = Provider.of<GameProvider>(context, listen: false);
final themeText = _themeController.text.trim().toLowerCase().replaceAll(' ', '_');

if (widget.isEditMode) {
  gameProvider.editProject(
    widget.project!.id,
    name: _nameController.text,
    description: _descController.text,
    theme: themeText,
    colorHex: _selectedColorHex,
  );
} else {
  gameProvider.addProject(
    name: _nameController.text,
    description: _descController.text,
    theme: themeText.isNotEmpty ? themeText : 'general', // Default to general if empty
    colorHex: _selectedColorHex,
  );
}
Navigator.of(context).pop();

}

void _handleDelete() {
final gameProvider = Provider.of<GameProvider>(context, listen: false);
showDialog(
context: context,
builder: (ctx) => AlertDialog(
title: Text('Delete Project?', style: TextStyle(color: AppTheme.fnAccentRed)),
content: Text('Are you sure you want to delete "${widget.project!.name}"? This action cannot be undone.'),
actions: [
TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
ElevatedButton(
onPressed: () {
gameProvider.deleteProject(widget.project!.id);
Navigator.of(ctx).pop(); // Close confirmation dialog
Navigator.of(context).pop(); // Close edit dialog
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
return AlertDialog(
backgroundColor: AppTheme.fnBgMedium,
title: Text(widget.isEditMode ? 'Edit Project' : 'Add New Project'),
content: Form(
key: _formKey,
child: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
TextFormField(
controller: _nameController,
decoration: const InputDecoration(labelText: 'Project Name'),
validator: (value) => value!.trim().isEmpty ? 'Project name cannot be empty.' : null,
),
const SizedBox(height: 16),
TextFormField(
controller: _descController,
decoration: const InputDecoration(labelText: 'Description'),
maxLines: 2,
),
const SizedBox(height: 16),
TextFormField(
controller: _themeController,
decoration: const InputDecoration(
labelText: 'Theme / Skill Name',
hintText: 'e.g., fitness, programming, learning_spanish'
),
validator: (value) => value!.trim().isEmpty ? 'Theme cannot be empty.' : null,
),
const SizedBox(height: 24),
Text("Select Project Color:", style: Theme.of(context).textTheme.labelMedium),
const SizedBox(height: 12),
ProjectColorPicker(
selectedColorHex: _selectedColorHex,
onColorSelected: (newColorHex) {
setState(() {
_selectedColorHex = newColorHex;
});
},
),
],
),
),
),
actionsAlignment: MainAxisAlignment.spaceBetween,
actions: <Widget>[
if (widget.isEditMode)
IconButton(
icon: Icon(MdiIcons.deleteForeverOutline, color: AppTheme.fnAccentRed),
onPressed: _handleDelete,
tooltip: 'Delete Project',
),
Row(
mainAxisSize: MainAxisSize.min,
children: [
TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
const SizedBox(width: 8),
ElevatedButton(
child: Text(widget.isEditMode ? 'Save Changes' : 'Add Project'),
onPressed: _handleSaveChanges,
),
],
),
],
);
}
}