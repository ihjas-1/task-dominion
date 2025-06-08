import 'package:arcane/src/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:arcane/src/screens/home_screen.dart';
import 'package:arcane/src/screens/login_screen.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:provider/provider.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications
    
   NotificationService().init();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the GameProvider for changes.
    final gameProvider = context.watch<GameProvider>();

    // Determine the current accent color based on the selected project.
    final Color currentProjectColor =
        gameProvider.getSelectedProject()?.color ?? AppTheme.fortniteBlue;

    return MaterialApp(
      title: 'Arcane',
      theme: AppTheme.getThemeData(primaryAccent: currentProjectColor),
      debugShowCheckedModeBanner: false,
      home: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          // Show a loading indicator if authentication is in progress or
          // if a user is logged in but data is still loading.
          if (gameProvider.authLoading ||
              (gameProvider.currentUser != null &&
                  gameProvider.isDataLoadingAfterLogin)) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // If no user is logged in, show the LoginScreen.
          if (gameProvider.currentUser == null) {
            return const LoginScreen();
          }
          // Otherwise, show the HomeScreen for authenticated users.
          return const HomeScreen();
        },
      ),
    );
  }
}