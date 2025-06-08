// lib/src/widgets/views/settings_sections/user_access_settings.dart
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/widgets/views/settings_sections/settings_section_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class UserAccessSettings extends StatefulWidget {
  const UserAccessSettings({super.key});

  @override
  State<UserAccessSettings> createState() => _UserAccessSettingsState();
}

class _UserAccessSettingsState extends State<UserAccessSettings> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _newUsernameController = TextEditingController();
  bool _passwordChangeLoading = false;
  String _passwordChangeError = '';
  String _passwordChangeSuccess = '';
  bool _usernameChangeLoading = false;
  String _usernameChangeError = '';
  String _usernameChangeSuccess = '';
  bool _logoutLoading = false;

  @override
  void initState() {
    super.initState();
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    _newUsernameController.text = gameProvider.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newUsernameController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword(GameProvider gameProvider) async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _passwordChangeError = "Passwords do not match.");
      return;
    }
    if (_newPasswordController.text.length < 6) {
      setState(() => _passwordChangeError = "Password should be at least 6 characters long.");
      return;
    }
    setState(() { _passwordChangeLoading = true; _passwordChangeError = ''; _passwordChangeSuccess = ''; });
    try {
      await gameProvider.changePasswordHandler(_newPasswordController.text);
      if (!mounted) return;
      setState(() { _passwordChangeSuccess = "Password changed successfully!"; _newPasswordController.clear(); _confirmPasswordController.clear(); });
    } catch (e) {
      if (!mounted) return;
      if (e is FirebaseAuthException) {
        setState(() => _passwordChangeError = e.message ?? "Failed to change password.");
      } else {
        setState(() => _passwordChangeError = "An unexpected error occurred while changing password.");
      }
    } finally {
      if (mounted) setState(() => _passwordChangeLoading = false);
    }
  }

  Future<void> _handleChangeUsername(GameProvider gameProvider) async {
    if (_newUsernameController.text.trim().isEmpty) {
      setState(() => _usernameChangeError = "Username cannot be empty.");
      return;
    }
    if (_newUsernameController.text.trim().length < 3) {
      setState(() => _usernameChangeError = "Username must be at least 3 characters.");
      return;
    }
    setState(() { _usernameChangeLoading = true; _usernameChangeError = ''; _usernameChangeSuccess = ''; });
    try {
      await gameProvider.updateUserDisplayName(_newUsernameController.text.trim());
      if (!mounted) return;
      setState(() => _usernameChangeSuccess = "Username updated successfully!");
    } catch (e) {
      if (!mounted) return;
      if (e is FirebaseAuthException) {
        setState(() => _usernameChangeError = e.message ?? "Failed to update username.");
      } else {
        setState(() => _usernameChangeError = "An unexpected error occurred while updating username.");
      }
    } finally {
      if (mounted) setState(() => _usernameChangeLoading = false);
    }
  }

  Future<void> _handleLogout(GameProvider gameProvider) async {
    setState(() => _logoutLoading = true);
    try {
      await gameProvider.logoutUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: ${e.toString()}'), backgroundColor: AppTheme.fnAccentRed));
    } finally {
      if (mounted) setState(() => _logoutLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        if (gameProvider.currentUser == null) return const SizedBox.shrink();

        return SettingsSectionCard(
          icon: MdiIcons.shieldAccountOutline,
          title: 'User Access',
          children: [
            TextField(controller: _newUsernameController, decoration:  InputDecoration(labelText: 'Display Name', prefixIcon: Icon(MdiIcons.accountBadgeOutline, size: 20))),
            if (_usernameChangeError.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(_usernameChangeError, style: const TextStyle(color: AppTheme.fnAccentRed, fontSize: 12))),
            if (_usernameChangeSuccess.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(_usernameChangeSuccess, style: const TextStyle(color: AppTheme.fnAccentGreen, fontSize: 12))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: _usernameChangeLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.fnTextPrimary)) :  Icon(MdiIcons.contentSaveOutline, size: 18),
              label: const Text('UPDATE DISPLAY NAME'),
              onPressed: _usernameChangeLoading ? null : () => _handleChangeUsername(gameProvider),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            ),
            const SizedBox(height: 24),
            TextField(controller: _newPasswordController, decoration:  InputDecoration(labelText: 'New Passcode', prefixIcon: Icon(MdiIcons.formTextboxPassword, size: 20)), obscureText: true),
            const SizedBox(height: 12),
            TextField(controller: _confirmPasswordController, decoration:  InputDecoration(labelText: 'Confirm Passcode', prefixIcon: Icon(MdiIcons.formTextboxPassword, size: 20)), obscureText: true),
            if (_passwordChangeError.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10.0), child: Text(_passwordChangeError, style: const TextStyle(color: AppTheme.fnAccentRed, fontSize: 12))),
            if (_passwordChangeSuccess.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10.0), child: Text(_passwordChangeSuccess, style: const TextStyle(color: AppTheme.fnAccentGreen, fontSize: 12))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: _passwordChangeLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.fnTextPrimary)) :  Icon(MdiIcons.keyChange, size: 18),
              label: const Text('UPDATE PASSCODE'),
              onPressed: _passwordChangeLoading ? null : () => _handleChangePassword(gameProvider),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: _logoutLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.fnAccentOrange)) :  Icon(MdiIcons.logoutVariant, size: 18),
              label: const Text('SIGN OUT'),
              onPressed: _logoutLoading ? null : () => _handleLogout(gameProvider),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.fnAccentOrange, side: const BorderSide(color: AppTheme.fnAccentOrange, width: 1.5), minimumSize: const Size(double.infinity, 44)),
            ),
          ],
        );
      },
    );
  }
}