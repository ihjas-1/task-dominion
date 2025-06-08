// lib/src/widgets/dialogs/ai_task_generation_dialog.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class AITaskGenerationDialog extends StatefulWidget {
  final Project project;
  const AITaskGenerationDialog({super.key, required this.project});

  @override
  State<AITaskGenerationDialog> createState() => _AITaskGenerationDialogState();
}

class _AITaskGenerationDialogState extends State<AITaskGenerationDialog> {
  late final TextEditingController _aiInputController;
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _aiInputController = TextEditingController();
    _aiInputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _aiInputController.removeListener(_onInputChanged);
    _aiInputController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final hasText = _aiInputController.text.trim().isNotEmpty;
    if (hasText != _hasInput) {
      setState(() {
        _hasInput = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();

    return AlertDialog(
      backgroundColor: AppTheme.fnBgMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.fortnitePurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      title: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.fortnitePurple.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.fortnitePurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                MdiIcons.creation,
                color: AppTheme.fortnitePurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Generate Tasks with AI",
                    style: TextStyle(
                      color: AppTheme.fortnitePurple,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Project: ${widget.project.name}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.fortnitePurple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.fortnitePurple.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      MdiIcons.lightbulbOnOutline,
                      color: AppTheme.fortnitePurple.withOpacity(0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Provide a plan, outline, or table of contents. The AI will generate actionable tasks.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasInput 
                        ? AppTheme.fortnitePurple.withOpacity(0.5)
                        : Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _aiInputController,
                  decoration: InputDecoration(
                    labelText: 'Plan / Outline',
                    hintText: 'e.g., Chapter 1: Introduction\nChapter 2: Setup\nChapter 3: Implementation...',
                    alignLabelWithHint: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    labelStyle: TextStyle(
                      color: AppTheme.fortnitePurple.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 6,
                  minLines: 4,
                ),
              ),
              if (_hasInput) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        MdiIcons.checkCircleOutline,
                        color: Colors.green,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Ready to generate tasks",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: gameProvider.isGeneratingContent ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.7),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text("Cancel"),
        ),
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton.icon(
            icon: gameProvider.isGeneratingContent
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.8),
                      ),
                    ),
                  )
                : Icon(MdiIcons.headCogOutline, size: 16),
            label: Text(
              gameProvider.isGeneratingContent ? "Generating..." : "Generate Tasks",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasInput && !gameProvider.isGeneratingContent
                  ? AppTheme.fortnitePurple
                  : AppTheme.fortnitePurple.withOpacity(0.3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: _hasInput && !gameProvider.isGeneratingContent ? 2 : 0,
            ),
            onPressed: gameProvider.isGeneratingContent || !_hasInput
                ? null
                : () {
                    gameProvider.triggerAIGenerateTasks(
                      widget.project,
                      _aiInputController.text,
                    );
                    Navigator.of(context).pop();
                  },
          ),
        ),
      ],
    );
  }
}