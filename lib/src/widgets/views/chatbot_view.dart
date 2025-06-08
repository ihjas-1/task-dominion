// lib/src/widgets/views/chatbot_view.dart
import 'package:flutter/material.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';


class ChatbotView extends StatefulWidget {
  const ChatbotView({super.key});

  @override
  State<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProvider>(context, listen: false).initializeChatbotMemory();
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(covariant ChatbotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final messageText = _messageController.text.trim();
    _messageController.clear();
    FocusScope.of(context).unfocus();

    setState(() => _isSending = true);

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    await gameProvider.sendMessageToChatbot(messageText);

    if (mounted) {
      setState(() => _isSending = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final chatbotMemory = gameProvider.chatbotMemory;
    final Color dynamicAccent = gameProvider.getSelectedProject()?.color ?? theme.colorScheme.secondary;


    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: Icon(MdiIcons.refresh, size: 16, color: AppTheme.fnTextSecondary),
                label: Text("Restart Session", style: TextStyle(color: AppTheme.fnTextSecondary, fontSize: 12)),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                            title: Text("Restart Chat?", style: TextStyle(color: dynamicAccent)),
                            content: const Text("This will clear the current conversation history, but remembered items and summaries will remain. Continue?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: ElevatedButton.styleFrom(backgroundColor: dynamicAccent),
                                child: Text("Restart", style: TextStyle(color: ThemeData.estimateBrightnessForColor(dynamicAccent) == Brightness.dark ? AppTheme.fnTextPrimary : AppTheme.fnBgDark)),
                              ),
                            ],
                          ));
                  if (confirm == true) {
                    gameProvider.chatbotMemory.conversationHistory.clear();
                    gameProvider.initializeChatbotMemory();
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: chatbotMemory.conversationHistory.isEmpty && !_isSending
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(MdiIcons.robotHappyOutline, size: 48, color: dynamicAccent.withAlpha((255 * 0.7).round())),
                      const SizedBox(height: 16),
                      Text("Arcane Advisor Online", style: theme.textTheme.headlineSmall?.copyWith(color: dynamicAccent)),
                       const SizedBox(height: 8),
                      Text(
                        "Ask about your past week's summary, completed goals, or tell me things to 'Remember'.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.fnTextSecondary),
                      ),
                    ],
                  ))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: chatbotMemory.conversationHistory.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                       if (_isSending && index == chatbotMemory.conversationHistory.length) {
                        return _buildMessageBubble(
                          ChatbotMessage(
                            id: 'typing', text: '...',
                            sender: MessageSender.bot, timestamp: DateTime.now(),
                          ),
                          theme, dynamicAccent, true 
                        );
                      }
                      final message = chatbotMemory.conversationHistory[index];
                      return _buildMessageBubble(message, theme, dynamicAccent, false);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Send a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: const BorderSide(color: AppTheme.fnBorderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(color: dynamicAccent, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    style: const TextStyle(color: AppTheme.fnTextPrimary, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: dynamicAccent))
                      : Icon(MdiIcons.sendCircleOutline, color: dynamicAccent),
                  onPressed: _isSending ? null : _sendMessage,
                  iconSize: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatbotMessage message, ThemeData theme, Color dynamicAccent, bool isTyping) {
    final bool isUser = message.sender == MessageSender.user;
    final Color bubbleColor = isUser ? dynamicAccent : AppTheme.fnBgMedium;
    final Color textColor = isUser 
        ? (ThemeData.estimateBrightnessForColor(dynamicAccent) == Brightness.dark ? AppTheme.fnTextPrimary : AppTheme.fnBgDark) 
        : AppTheme.fnTextPrimary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                border: Border.all(color: bubbleColor.withAlpha((255 * 0.5).round()), width: 0.5)
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontSize: 13.5, height: 1.4),
                  ),
                  if (!isTyping) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(message.timestamp.toLocal()),
                      style: theme.textTheme.labelSmall?.copyWith(color: textColor.withAlpha((255 * 0.7).round()), fontSize: 9),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


   @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}