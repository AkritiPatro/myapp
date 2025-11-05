import 'package:firebase_ai/firebase_ai.dart';

class GeminiChatService {
  final ChatSession _chat;

  GeminiChatService()
      : _chat = FirebaseAI.googleAI()
            .generativeModel(model: 'gemini-2.5-pro')
            .startChat();

  Future<String> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      return response.text ?? 'No response from model.';
    } catch (e) {
      return 'Error generating text: $e';
    }
  }

  void clearHistory() {
    // This is a placeholder. A true implementation would re-initialize the chat.
  }
}
