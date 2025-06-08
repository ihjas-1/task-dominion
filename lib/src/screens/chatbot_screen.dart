// lib/src/screens/chatbot_screen.dart
import 'package:flutter/material.dart';
import 'package:arcane/src/widgets/views/chatbot_view.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:arcane/src/providers/game_provider.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // For dynamic accent
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    // Ensure chatbot memory is initialized when this screen is visited
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gameProvider.initializeChatbotMemory();
    });


    return Scaffold(
      appBar: AppBar(
        title: const Text('Arcane Advisor'),
        backgroundColor: AppTheme.fnBgMedium,
        // Use the dynamic accent color for the AppBar potentially
         flexibleSpace: Container( 
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.secondary.withOpacity(0.3),
                AppTheme.fnBgMedium,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: const ChatbotView(),
    );
  }
}