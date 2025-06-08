import 'package:flutter/material.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:provider/provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuthException

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _username = '';
  bool _isLogin = true;
  bool _isLoading = false;
  String _error = '';
  bool _obscurePassword = true;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isHovering = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (_isLogin) {
        await gameProvider.loginUser(_email, _password);
      } else {
        await gameProvider.signupUser(_email, _password, _username);
      }
      // Auth state change will handle navigation in MyApp or GameProvider listener
    } catch (e) {
      // print("[LoginScreen] Auth Error: $e"); // DEBUG
      setState(() {
        if (e is FirebaseAuthException) {
          _error =
              e.message ?? "An unknown Firebase authentication error occurred.";
        } else {
          _error = "An unexpected error occurred. Please try again.";
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.fnBgDark, // Use the new dark background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child:
              // Add a ConstrainedBox to limit the width for desktop
              ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 400), // Max width of 400 pixels
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: AppTheme.fnBgMedium, // Slightly lighter card background
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                      color: _isHovering ? AppTheme.fortnitePurple : AppTheme.fnBorderColor,
                      width: _isHovering ? 2.5 : 1.5), // Themed border
                  boxShadow: _isHovering
                      ? [
                          BoxShadow(
                            color: AppTheme.fortnitePurple.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(MdiIcons.shieldCrownOutline,
                            size: 56,
                            color: AppTheme.fortniteBlue), // Themed Icon
                        const SizedBox(height: 16),
                        Text(
                          'ARCANE',
                          style: theme.textTheme.displaySmall?.copyWith(
                            // Use displaySmall for prominent title
                            color: AppTheme.fortniteBlue,
                            fontFamily: 'BurbankBigCondensed',
                            fontWeight: FontWeight.bold
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin
                              ? 'Secure Login'
                              : 'Create Account', // Updated subtitle
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.fnTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        if (!_isLogin)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(MdiIcons.accountOutline,
                                    color: theme
                                        .inputDecorationTheme.labelStyle?.color,
                                    size: 20),
                              ),
                              style: const TextStyle(
                                  color: AppTheme.fnTextPrimary,
                                  fontFamily: AppTheme.fontBody),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a username.';
                                }
                                if (value.trim().length < 3) {
                                  return 'Username must be at least 3 characters.';
                                }
                                return null;
                              },
                              onSaved: (value) => _username = value!.trim(),
                            ),
                          ),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(MdiIcons.emailOutline,
                                color:
                                    theme.inputDecorationTheme.labelStyle?.color,
                                size: 20),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                              color: AppTheme.fnTextPrimary,
                              fontFamily: AppTheme.fontBody),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                !value.contains('@')) {
                              return 'Please enter a valid email.';
                            }
                            return null;
                          },
                          onSaved: (value) => _email = value!,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(MdiIcons.lockOutline,
                                color:
                                    theme.inputDecorationTheme.labelStyle?.color,
                                size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? MdiIcons.eyeOutline
                                    : MdiIcons.eyeOffOutline,
                                color:
                                    theme.inputDecorationTheme.labelStyle?.color,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                              color: AppTheme.fnTextPrimary,
                              fontFamily: AppTheme.fontBody),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.length < 6) {
                              return 'Password must be at least 6 characters long.';
                            }
                            return null;
                          },
                          onSaved: (value) => _password = value!,
                        ),
                        if (_error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _error,
                              style: const TextStyle(
                                  color: AppTheme.fnAccentRed,
                                  fontSize: 12,
                                  fontFamily: AppTheme.fontBody),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 32),
                        if (_isLoading)
                          const CircularProgressIndicator(
                              color: AppTheme.fortniteBlue)
                        else
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Text(_isLogin ? 'LOGIN' : 'SIGN UP'),
                          ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _error = '';
                              _formKey.currentState?.reset();
                              _usernameController.clear();
                              _emailController.clear();
                              _passwordController.clear();
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'Need an account? Sign Up'
                                : 'Already have an account? Login',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}