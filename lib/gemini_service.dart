import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Data model for messages
enum ChatMessageType { user, bot }

class ChatMessage {
  final String text;
  final ChatMessageType type;
  ChatMessage({required this.text, required this.type});

  // Helper to convert to Gemini API format
  // Gemini expects roles to alternate "user" and "model".
  Map<String, dynamic> toGeminiContent() {
    return {
      "role": type == ChatMessageType.user ? "user" : "model",
      "parts": [
        {"text": text},
      ],
    };
  }
}

class GeminiChatService {
  // Retrieve API key from .env file that was loaded in main.dart
  final String _apiKey = dotenv.env['GEMINI_API_KEY']!;

  // Updated model name to gemini-2.5-flash based on documentation
  final String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

  // Stores the full conversation history for multi-turn conversations.
  final List<ChatMessage> _history = [];

  // Constructor
  GeminiChatService();

  // Sends a message to the Gemini API and returns the bot's response.
  Future<String> sendMessage(String message) async {
    // 1. Add the user's new message to the conversation history.
    _history.add(ChatMessage(text: message, type: ChatMessageType.user));

    // 2. Convert the entire conversation history into the format Gemini API expects.
    final List<Map<String, dynamic>> contents =
        _history.map((msg) => msg.toGeminiContent()).toList();

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl?key=$_apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": contents, // Payload containing history
          "generationConfig": {
            "temperature": 0.9,
            "topK": 1,
            "topP": 1,
            "maxOutputTokens": 2048,
          },
          "safetySettings": [
            {
              "category": "HARM_CATEGORY_HARASSMENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE",
            },
            {
              "category": "HARM_CATEGORY_HATE_SPEECH",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE",
            },
            {
              "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE",
            },
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_MEDIUM_AND_ABOVE",
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print("Gemini API Response (Status 200): $data");

        // Safely access the 'candidates' list
        final List<dynamic>? candidatesList = data['candidates'] as List<dynamic>?;

        if (candidatesList != null && candidatesList.isNotEmpty) {
          // **FIX APPLIED HERE**: Access the first element ([0]) of the list
          final Map<String, dynamic> firstCandidate = candidatesList[0] as Map<String, dynamic>;

          // Safely access 'content'
          final Map<String, dynamic>? contentData = firstCandidate['content'] as Map<String, dynamic>?;

          if (contentData != null) {
            // Safely access 'parts' list
            final List<dynamic>? partsList = contentData['parts'] as List<dynamic>?;

            if (partsList != null && partsList.isNotEmpty) {
              // Access the FIRST part Map (index 0)
              final Map<String, dynamic> firstPart = partsList[0] as Map<String, dynamic>;

              if (firstPart['text'] != null) {
                final String botResponse = firstPart['text'] as String;
                _history.add(ChatMessage(text: botResponse, type: ChatMessageType.bot));
                return botResponse;
              }
            }
          }
          
          // Check if the response was blocked by safety settings even if a candidate exists
          if (firstCandidate['finishReason'] != null && firstCandidate['finishReason'] != 'STOP') {
             return "I'm sorry, the AI response was blocked or incomplete (Reason: ${firstCandidate['finishReason']}).";
          }
          
          print("Gemini API Error: Incomplete candidate structure after successful API call. Raw data: $data");
          return "Error: Incomplete response from AI.";

        } else if (data['promptFeedback'] != null) {
          // If no candidates, check if content was blocked by safety settings
          print(
            "Gemini response blocked by safety settings: ${data['promptFeedback']}",
          );
          final String blockReason = data['promptFeedback']['blockReason'] ?? 'content violation';
          return "I'm sorry, your request was blocked due to $blockReason.";
        }
        
        print("Gemini API Error: No valid 'candidates' found after successful API call. Raw data: $data");
        return "Error: No valid response from Gemini (no candidates).";
      } else {
        // Log the full API error response for debugging
        print(
          "Gemini API Error: Status ${response.statusCode} - Body: ${response.body}",
        );
        return "Error from AI: Status ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      // Catch network errors, JSON parsing errors, etc.
      print("Network or parsing error when calling Gemini API: $e");
      return "Error connecting to AI: $e";
    }
  }

  // Method to clear the entire chat history for a new conversation
  void clearHistory() {
    _history.clear();
  }
}