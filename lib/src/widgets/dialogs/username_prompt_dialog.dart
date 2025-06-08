// lib/src/widgets/dialogs/username_prompt_dialog.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UsernamePromptDialog extends StatefulWidget {
  const UsernamePromptDialog({super.key});

  @override
  State<UsernamePromptDialog> createState() => _UsernamePromptDialogState();
}

class _UsernamePromptDialogState extends State<UsernamePromptDialog> {
  final _usernameController = TextEditingController();
  final _dialogFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    final Color currentAccentColor =
        gameProvider.getSelectedProject()?.color ?? Theme.of(context).colorScheme.secondary;

    return AlertDialog(
      title: Text('Set Your Callsign', style: TextStyle(color: currentAccentColor)),
      content: Form(
        key: _dialogFormKey,
        child: TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(hintText: "Enter callsign"),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Callsign cannot be empty.';
            if (value.trim().length < 3) return 'Must be at least 3 characters.';
            return null;
          },
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: currentAccentColor),
          child: Text(
            'CONFIRM',
            style: TextStyle(
              color: ThemeData.estimateBrightnessForColor(currentAccentColor) == Brightness.dark
                  ? AppTheme.fnTextPrimary
                  : AppTheme.fnBgDark,
            ),
          ),
          onPressed: () async {
            if (_dialogFormKey.currentState!.validate()) {
              String newUsername = _usernameController.text.trim();
              Navigator.of(context).pop();
              await gameProvider.updateUserDisplayName(newUsername);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Callsign updated!'),
                    backgroundColor: AppTheme.fnAccentGreen,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }
}