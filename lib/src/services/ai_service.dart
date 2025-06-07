import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;
import 'package:arcane/src/config/api_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:arcane/src/models/game_models.dart';

class AIService {
  Future<Map<String, dynamic>> _makeAICall({
    required String prompt,
    required int currentApiKeyIndex,
    required Function(int) onNewApiKeyIndex,
    required Function(String) onLog,
  }) async {
    if (geminiApiKeys.isEmpty || geminiApiKeys.every((key) => key.startsWith('YOUR_GEMINI_API_KEY'))) {
      throw Exception("No valid Gemini API keys found.");
    }
    if (geminiModelName.isEmpty) {
      throw Exception("GEMINI_MODEL_NAME not configured.");
    }

    if (kDebugMode) print("[AIService] AI Prompt:\n$prompt");

    for (int i = 0; i < geminiApiKeys.length; i++) {
      final int keyAttemptIndex = (currentApiKeyIndex + i) % geminiApiKeys.length;
      final String apiKey = geminiApiKeys[keyAttemptIndex];
      if (apiKey.startsWith('YOUR_GEMINI_API_KEY')) continue;

      try {
        final model = genai.GenerativeModel(model: geminiModelName, apiKey: apiKey);
        final response = await model.generateContent([genai.Content.text(prompt)]);
        String? rawResponseText = response.text;

        if (rawResponseText == null || rawResponseText.trim().isEmpty) throw Exception("AI response was empty.");
        if (kDebugMode) print("[AIService] Raw AI Response (Key Index $keyAttemptIndex):\n$rawResponseText");
        
        String jsonString = rawResponseText.trim();
        int jsonStart = jsonString.indexOf('{');
        int jsonEnd = jsonString.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          jsonString = jsonString.substring(jsonStart, jsonEnd + 1);
        } else {
          throw Exception("Could not extract JSON from AI response.");
        }

        final Map<String, dynamic> generatedData = jsonDecode(jsonString);
        onNewApiKeyIndex(keyAttemptIndex);
        return generatedData;
      } catch (e) {
        String errorDetail = e.toString();
        if (kDebugMode) print("[AIService] Error with API key index $keyAttemptIndex: $errorDetail");
        if (i == geminiApiKeys.length - 1) throw Exception("All API keys failed. Last error: $errorDetail");
      }
    }
    throw Exception("All API keys failed or were invalid.");
  }

  Future<Map<String, dynamic>> enhanceTaskWithAI({
    required Project project,
    required Task task,
    required String userInput,
    required int currentApiKeyIndex,
    required Function(int) onNewApiKeyIndex,
    required Function(String) onLog,
  }) async {
    final existingCheckpointsString = task.checkpoints.map((cp) => "- ${cp.name}").join('\n');

    final String prompt = """
You are an assistant for a gamified task management app. Your task is to enhance an existing task by breaking it down into detailed, actionable checkpoints.

**Context:**
- Project: "${project.name}" (Theme/Skill: "${project.theme}")
- Task to Enhance: "${task.name}"
- Existing Checkpoints to be replaced: 
$existingCheckpointsString
- User's refinement instructions: "$userInput"
- The Task Name ("${task.name}") MUST NOT be changed.

**Your Goal:**
Generate a list of 2 to 5 specific, small, and concrete checkpoints for the task. Also, define the skill XP for completing the overall task.

**Output Requirements:**
Provide the output as a single, valid JSON object. The JSON object MUST have these keys:
- "skillXp": object (e.g., `{"${project.theme}": 10.0, "another_skill": 5.0}`). The key MUST be a valid skill theme from the app. You can assign XP to multiple skills.
- "checkpoints": array of checkpoint objects. Each checkpoint MUST have:
  - "id": string (Use a placeholder like "new_cp_1", "new_cp_2")
  - "name": string (A small, concrete action. e.g., "Read pages 1-10", "Draft outline", "Complete 3 practice problems")
  - "isCountable": boolean
  - "targetCount": number (if countable, otherwise 0)
  - "skillXp": object (e.g., `{"${project.theme}": 2.0}`). XP should be smaller than the parent task's XP.

**Example JSON Output:**
{
  "skillXp": {
    "tech": 15.0
  },
  "checkpoints": [
    {
      "id": "new_cp_1",
      "name": "Analyze website's landing page",
      "isCountable": false,
      "targetCount": 0,
      "skillXp": { "tech": 3.0 }
    },
    {
      "id": "new_cp_2",
      "name": "Review 5 recent social media posts",
      "isCountable": true,
      "targetCount": 5,
      "skillXp": { "tech": 5.0 }
    }
  ]
}

Return ONLY the JSON object. Do not include markdown, comments, or any extra text.
""";
    try {
      final Map<String, dynamic> enhancedData = await _makeAICall(
        prompt: prompt,
        currentApiKeyIndex: currentApiKeyIndex,
        onNewApiKeyIndex: onNewApiKeyIndex,
        onLog: onLog,
      );

      if (enhancedData['checkpoints'] is List) {
        return enhancedData;
      } else {
        throw Exception("AI response for enhancement was malformed.");
      }
    } catch (e) {
      onLog("<span style=\"color:var(--fh-accent-red);\">AI Call failed for enhanceTaskWithAI: ${e.toString()}</span>");
      rethrow;
    }
  }

  Future<String> getChatbotResponse({
    required ChatbotMemory memory,
    required String userMessage,
    required String completedByDayJsonLast7Days,
    required String olderDaysSummary,
    required int currentApiKeyIndex,
    required Function(int) onNewApiKeyIndex,
    required Function(String) onLog,
  }) async {
    final conversationHistoryString = memory.conversationHistory.map((msg) => "${msg.sender == MessageSender.user ? 'User' : 'Bot'}: ${msg.text}").join('\n');
    
    final String prompt = """
You are Arcane Advisor, a helpful AI assistant in a gamified productivity app.
Your knowledge includes:
1.  Conversation History:
$conversationHistoryString
2.  Logbook Data (Last 7 Days):
$completedByDayJsonLast7Days
3.  Older Logbook Summary:
$olderDaysSummary
4.  User's Remembered Items:
${memory.userRememberedItems.isNotEmpty ? memory.userRememberedItems.join('\n') : "None."}

User's message: "$userMessage"

Based on this, provide a concise, helpful, and encouraging response.
If asked to "Remember X", acknowledge it. If asked to "Forget", acknowledge it. The system handles the memory.
Analyze progress, summaries, emotion trends, or completions using the provided data.
Keep responses short and conversational. Do not use markdown.
"""
        .trim();

    try {
      if (geminiApiKeys.isEmpty || geminiApiKeys.every((key) => key.startsWith('YOUR_GEMINI_API_KEY'))) {
        throw Exception("No valid Gemini API keys found.");
      }
      if (geminiModelName.isEmpty) {
        throw Exception("GEMINI_MODEL_NAME not configured.");
      }
      
      if (kDebugMode) print("[AIService - Chatbot] Prompt:\n$prompt");

      for (int i = 0; i < geminiApiKeys.length; i++) {
        final int keyAttemptIndex = (currentApiKeyIndex + i) % geminiApiKeys.length;
        final String apiKey = geminiApiKeys[keyAttemptIndex];
        if (apiKey.startsWith('YOUR_GEMINI_API_KEY')) continue;

        try {
          final model = genai.GenerativeModel(model: 'gemini-2.0-flash-lite', apiKey: apiKey);
          final response = await model.generateContent([genai.Content.text(prompt)]);
          String? rawResponseText = response.text;
          if (rawResponseText == null || rawResponseText.trim().isEmpty) throw Exception("Chatbot AI response was empty.");
          
          if (kDebugMode) print("[AIService - Chatbot] Raw AI Response (Key Index $keyAttemptIndex):\n$rawResponseText");
          onNewApiKeyIndex(keyAttemptIndex);
          return rawResponseText.trim();
        } catch (e) {
          String errorDetail = e.toString();
          if (e is genai.GenerativeAIException && e.message.contains("USER_LOCATION_INVALID")) errorDetail = "Geographic location restriction.";
          else if (errorDetail.contains("API key not valid")) errorDetail = "Invalid API key.";
          else if (errorDetail.contains("quota")) errorDetail = "API quota exceeded.";
          else if (errorDetail.contains("Candidate was blocked due to SAFETY")) errorDetail = "Response blocked due to safety settings.";
          
          if (kDebugMode) print("[AIService - Chatbot] Error with API key index $keyAttemptIndex: $errorDetail");
          if (i == geminiApiKeys.length - 1) return "I'm having trouble connecting. Please try again later. (Error: $errorDetail)";
        }
      }
    } catch (e) {
       return "I'm currently unable to process requests due to a configuration issue.";
    }
    return "I seem to be experiencing technical difficulties. Please check back soon.";
  }
}