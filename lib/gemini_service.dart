import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'chat_message.dart';

class GeminiChatService {
  GenerativeModel? _modelLite;
  GenerativeModel? _modelFlash;
  final List<Content> _history = [];
  final int _maxHistory = 10; // Keep last 10 messages to stay under TPM limit

  GeminiChatService() {
    // Lazy initialization happens in sendMessage
  }

  void _initModel() {
    String? apiKey;
    try {
      apiKey = dotenv.env['GEMINI_API_KEY'];
    } catch (_) {
      apiKey = null;
    }

    if (apiKey == null || apiKey.isEmpty || apiKey == 'PLACEHOLDER') {
      _modelLite = null;
      _modelFlash = null;
      return;
    }
    
    final systemInstruction = Content.system('''
You are the "Sane Machine Technical Assistant", an expert in Industrial Washing Machine Maintenance and IoT Diagnostics.
Your goal is to help users manage their laundry machine fleet and interpret technical sensor data.

TECHNICAL KNOWLEDGE:
- STATUSES: Normal, Early Warning, Maintenance Required, Critical Failure, Scheduled.
- VIBRATION: Indicates bearing health. Thresholds: Warning > (MaxRPM/10 + 1500), Required > (MaxRPM/5 + 2000). Max limit 4095 is a mechanical lock.
- POWER: High wattage (>1900W) on non-heated models indicates motor winding failure or electrical leakage.
- AMPERAGE: >3000 units indicates motor overload or logic board short-circuit.

YOUR TONE: 
- Professional, technical yet clear for non-experts.
- If a user asks about a failure, explain the technical reason and recommend a specific action (e.g., "Schedule manual lubrication").
''');

    // Primary model: Fastest, most requests
    _modelLite = GenerativeModel(
      model: 'gemini-1.5-flash', 
      apiKey: apiKey,
      systemInstruction: systemInstruction,
    );
    
    // Secondary model: For failover
    _modelFlash = GenerativeModel(
      model: 'gemini-1.5-pro', 
      apiKey: apiKey,
      systemInstruction: systemInstruction,
    );
    
    // Attempting 2.5 flash if requested/available
    try {
      _modelLite = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: apiKey, systemInstruction: systemInstruction);
      _modelFlash = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey, systemInstruction: systemInstruction);
    } catch (_) {
      // Revert to stable 1.5 if 2.5 init fails
    }
  }

  Future<String> sendMessage(String message, {List<ChatAttachment> attachments = const []}) async {
    if (_modelLite == null) {
      _initModel();
      if (_modelLite == null) {
        return 'API Key not found. Please check your .env file.';
      }
    }

    // 1. Prepare Content
    final contentParts = <Part>[TextPart(message)];
    for (final attachment in attachments) {
      contentParts.add(DataPart(attachment.mimeType, attachment.bytes));
    }
    final userContent = Content.multi(contentParts);

    // 2. Add to History and Prune
    _history.add(userContent);
    if (_history.length > _maxHistory) {
      _history.removeRange(0, _history.length - _maxHistory);
    }

    // 3. Dual-Model Try Loop
    return await _trySendWithFailover(userContent);
  }

  Future<String> _trySendWithFailover(Content userContent) async {
    // Try Primary (Flash-Lite)
    try {
      final response = await _modelLite!.generateContent(_history);
      if (response.text != null) {
        _history.add(Content.model([TextPart(response.text!)]));
        return response.text!;
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      print("Primary Model (Lite) Error: $e");
      
      // If quota hit, failover to Secondary (Flash)
      if (errorStr.contains('quota') || errorStr.contains('429')) {
        return await _trySecondaryModel(userContent);
      }
      return 'Unexpected Error: $e';
    }
    return 'No response from AI.';
  }

  Future<String> _trySecondaryModel(Content userContent) async {
    try {
      final response = await _modelFlash!.generateContent(_history);
      if (response.text != null) {
        _history.add(Content.model([TextPart(response.text!)]));
        return response.text!;
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      print("Secondary Model (Flash) Error: $e");
      
      if (errorStr.contains('quota') || errorStr.contains('429')) {
        return 'Both models are currently busy. (Daily limit reached or wait 45s). Info: $e';
      }
      return 'Secondary Error: $e';
    }
    return 'No response from failover model.';
  }

  void clearHistory() {
    _history.clear();
  }
}