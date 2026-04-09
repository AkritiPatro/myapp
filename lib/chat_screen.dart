import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'; // Add missing import
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import 'theme_provider.dart';
import 'gemini_service.dart';
import 'chat_message.dart';
import 'device_provider.dart';
import 'device_model.dart';

class ChatScreen extends StatefulWidget {
  final String? initialDeviceId;
  const ChatScreen({super.key, this.initialDeviceId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiChatService _geminiService = GeminiChatService();
  final List<ChatMessage> _messages = [];
  
  // Speech to Text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  double _soundLevel = 0.0;
  String _speechStatus = 'Idle';
  String _currentLocaleId = '';
  List<stt.LocaleName> _locales = [];
  Timer? _silenceTimer;
  
  bool _isLoading = false;
  List<ChatAttachment> _selectedAttachments = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    
    // Initial Greeting
    String greeting = "Hello! I am your Sane Machine AI assistant. How can I help you today?";
    if (widget.initialDeviceId != null) {
      greeting = "I see your ${widget.initialDeviceId} is currently selected. Type or say your question, and I'll analyze its diagnostic data for you.";
    }

    _addMessage(ChatMessage(
      text: greeting,
      type: ChatMessageType.bot,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        debugLogging: true, // Enable internal plugin logs
        onStatus: (status) {
          developer.log('Speech status: $status');
          setState(() => _speechStatus = status);
          // Update listening state based on system status
          if (status == 'listening') {
            setState(() => _isListening = true);
          } else if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          developer.log('Speech error: $error');
          setState(() {
            _speechStatus = 'Error: ${error.errorMsg}';
            _isListening = false;
          });
        },
      );
      if (available) {
        var systemLocales = await _speech.locales();
        var systemLocale = await _speech.systemLocale();
        
        // Define our comprehensive list of languages
        final List<stt.LocaleName> fallbackLocales = [
          stt.LocaleName('en_US', 'English (US)'),
          stt.LocaleName('en_GB', 'English (UK)'),
          stt.LocaleName('hi_IN', 'Hindi'),
          stt.LocaleName('bn_IN', 'Bengali'),
          stt.LocaleName('te_IN', 'Telugu'),
          stt.LocaleName('mr_IN', 'Marathi'),
          stt.LocaleName('ta_IN', 'Tamil'),
          stt.LocaleName('gu_IN', 'Gujarati'),
          stt.LocaleName('kn_IN', 'Kannada'),
          stt.LocaleName('or_IN', 'Odia'),
          stt.LocaleName('ml_IN', 'Malayalam'),
          stt.LocaleName('pa_IN', 'Punjabi'),
          stt.LocaleName('es_ES', 'Spanish'),
          stt.LocaleName('fr_FR', 'French'),
          stt.LocaleName('de_DE', 'German'),
          stt.LocaleName('zh_CN', 'Chinese (Simplified)'),
          stt.LocaleName('ja_JP', 'Japanese'),
          stt.LocaleName('ko_KR', 'Korean'),
          stt.LocaleName('ru_RU', 'Russian'),
          stt.LocaleName('ar_SA', 'Arabic'),
          stt.LocaleName('pt_PT', 'Portuguese'),
          stt.LocaleName('it_IT', 'Italian'),
        ];

        setState(() {
          // Merge system locales with our list, avoiding duplicates
          final Set<String> seenIds = fallbackLocales.map((l) => l.localeId).toSet();
          _locales = [...fallbackLocales];
          
          for (var sl in systemLocales) {
            if (!seenIds.contains(sl.localeId)) {
              _locales.add(sl);
              seenIds.add(sl.localeId);
            }
          }

          if (systemLocale != null) {
            _currentLocaleId = systemLocale.localeId;
          } else if (_locales.isNotEmpty) {
            _currentLocaleId = _locales.first.localeId;
          }
        });
      }
    } catch (e) {
      developer.log("Speech initialization error: $e");
    }
  }

  void _startListening() async {
    if (!_isListening) {
      // Ensure we have a valid locale before starting
      if (_currentLocaleId.isEmpty) {
        var systemLocale = await _speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? 'en_US';
      }

      // Re-check initialization state if necessary
      if (!_speech.isAvailable) {
        bool available = await _speech.initialize(
          onStatus: (status) => developer.log('Speech status: $status'),
          onError: (error) => developer.log('Speech error: $error'),
        );
        if (!available) return;
      }

      _silenceTimer?.cancel();
      _silenceTimer = Timer(const Duration(seconds: 5), () {
        if (_isListening) _stopListening();
      });

      try {
        _speech.listen(
          onResult: (result) {
            developer.log('Speech result: "${result.recognizedWords}" (final: ${result.finalResult})');
            _silenceTimer?.cancel();
            _silenceTimer = Timer(const Duration(seconds: 4), () {
              if (_isListening) _stopListening();
            });

            setState(() {
              _messageController.text = result.recognizedWords;
            });
          },
          onSoundLevelChange: (level) {
            setState(() => _soundLevel = level);
          },
          localeId: _currentLocaleId,
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            cancelOnError: false, 
            listenMode: stt.ListenMode.dictation,
            onDevice: false,
          ),
        );
        
        // Force UI update immediately
        setState(() {
          _isListening = true;
          _speechStatus = 'Listening...';
        });
      } catch (e) {
        developer.log("Error starting speech listener: $e");
        setState(() => _isListening = false);
      }
    }
  }

  void _stopListening() async {
    if (_isListening) {
      _silenceTimer?.cancel();
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (file.bytes != null) {
              _selectedAttachments.add(ChatAttachment(
                name: file.name,
                bytes: file.bytes!,
                mimeType: _getMimeType(file.name, file.extension),
              ));
            }
          }
        });
      }
    } catch (e) {
      developer.log("Error picking files: $e");
    }
  }

  String _getMimeType(String name, String? extension) {
    final ext = extension?.toLowerCase() ?? '';
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) return 'image/$ext';
    if (ext == 'pdf') return 'application/pdf';
    return 'text/plain'; // Default
  }

  void _removeAttachment(int index) {
    setState(() {
      _selectedAttachments.removeAt(index);
    });
  }

  Future<void> _sendMessage() async {
    if ((_messageController.text.trim().isEmpty && _selectedAttachments.isEmpty) || _isLoading) return;

    final userMessageText = _messageController.text.trim();
    final attachments = List<ChatAttachment>.from(_selectedAttachments);
    
    _messageController.clear();
    setState(() => _selectedAttachments = []);

    _addMessage(ChatMessage(
      text: userMessageText, 
      type: ChatMessageType.user,
      attachments: attachments,
    ));

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current language name for prompt context
      final langName = _locales.isNotEmpty 
          ? _locales.firstWhere((l) => l.localeId == _currentLocaleId, orElse: () => _locales.first).name 
          : "English";
      
      // GATHER DEVICE CONTEXT
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      String contextString = "USER DEVICE CONTEXT:\n";
      for (var device in deviceProvider.devices) {
        contextString += "- ${device.brand} ${device.modelName} (Status: ${device.status.displayName}, Vibration: ${device.vibrationLevel.toInt()}, Message: ${device.diagnosticMessage ?? 'N/A'})\n";
      }
      if (widget.initialDeviceId != null) {
        contextString += "USER IS CURRENTLY LOOKING AT: ${widget.initialDeviceId}\n";
      }

      final botResponseText = await _geminiService.sendMessage(
        "[CONTEXT]\n$contextString\n[USER REQUEST IN $langName]\n$userMessageText",
        attachments: attachments,
      );
      _addMessage(ChatMessage(text: botResponseText, type: ChatMessageType.bot));
    } catch (e) {
      developer.log("Error sending message to Gemini: $e");
      _addMessage(ChatMessage(
        text: "Error: I'm having trouble connecting. Please try again.",
        type: ChatMessageType.bot,
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _geminiService.clearHistory();
      _addMessage(ChatMessage(
        text: "Chat cleared. How can I help you now?",
        type: ChatMessageType.bot,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Define Adaptive Colors
    final primaryGradient = isDark
        ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)])
        : const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2DD4BF)]);



    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Gemini Assistant',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        leading: IconButton(
          icon: Icon(
            Icons.dashboard_rounded, // Changed to dashboard to better represent devices
            color: isDark ? Colors.tealAccent : Colors.deepPurple,
            size: 26,
          ),
          onPressed: () => context.go('/devices'),
          tooltip: 'Devices',
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded, 
              color: isDark ? Colors.white : Colors.black, // Use fully opaque colors
              size: 26,
            ),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.white : Colors.black, // Use fully opaque colors
              size: 26,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated Background
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                    ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message, isDark, primaryGradient);
                    },
                  ),
                ),
                if (_isLoading)
                  _buildThinkingIndicator(isDark),
                _buildAttachmentPreview(isDark),
                _buildInputArea(isDark, primaryGradient),
              ],
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark, Gradient gradient) {
    final isUser = message.type == ChatMessageType.user;
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                _buildAvatar(false, isDark),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    gradient: isUser ? gradient : null,
                    color: isUser ? null : (isDark ? Colors.grey[900] : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.attachments.isNotEmpty)
                        _buildMessageAttachments(message.attachments, isUser),
                      if (message.text.isNotEmpty)
                        isUser
                            ? Text(
                                message.text,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : MarkdownBody(
                                data: message.text,
                                styleSheet: MarkdownStyleSheet(
                                  p: GoogleFonts.inter(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                  ),
                                  code: GoogleFonts.firaCode(
                                    backgroundColor: isDark ? Colors.black26 : Colors.grey[200],
                                    color: isDark ? Colors.tealAccent : Colors.deepPurple,
                                    fontSize: 13,
                                  ),
                                  codeblockDecoration: BoxDecoration(
                                    color: isDark ? Colors.black38 : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                    ],
                  ),
                ),
              ),
              if (isUser)
                _buildAvatar(true, isDark, gradient: gradient),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 48, right: 48, bottom: 8),
            child: Text(
              timeStr,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildAvatar(bool isUser, bool isDark, {Gradient? gradient}) {
    // Current user message gradient
    final currentGradient = gradient ?? (isDark
        ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)])
        : const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2DD4BF)]));

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUser
            ? currentGradient
            : const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Widget _buildThinkingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 20,
            child: Lottie.network(
              'https://assets5.lottiefiles.com/packages/lf20_6Ryx7X.json', // Dots animation
              errorBuilder: (context, error, stackTrace) => const LinearProgressIndicator(minHeight: 2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Gemini is thinking...',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    ).animate().fade();
  }

  Widget _buildMessageAttachments(List<ChatAttachment> attachments, bool isUser) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((a) {
        if (a.isImage) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              a.bytes,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isUser ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description_rounded, size: 20, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    a.name,
                    style: GoogleFonts.inter(fontSize: 12, color: isUser ? Colors.white : Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }
      }).toList(),
    ).animate().scale();
  }

  Widget _buildAttachmentPreview(bool isDark) {
    if (_selectedAttachments.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedAttachments.length,
        itemBuilder: (context, index) {
          final a = _selectedAttachments[index];
          return Stack(
            children: [
              Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: a.isImage
                      ? Image.memory(a.bytes, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.insert_drive_file_rounded, size: 28, color: Colors.blueAccent),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                a.name,
                                style: GoogleFonts.inter(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              Positioned(
                top: 2,
                right: 14,
                child: GestureDetector(
                  onTap: () => _removeAttachment(index),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputArea(bool isDark, Gradient gradient) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                _buildAttachButton(isDark),
                _buildLanguageButton(isDark),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: _isListening ? "Listening... (Please Speak)" : "Message Gemini...",
                      hintStyle: GoogleFonts.inter(
                        color: _isListening 
                            ? (isDark ? Colors.tealAccent : Colors.deepPurple) 
                            : (isDark ? Colors.grey[500] : Colors.grey[600]),
                        fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                _buildMicButton(isDark),
                const SizedBox(width: 4),
                _buildSendButton(isDark, gradient),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachButton(bool isDark) {
    return IconButton(
      icon: Icon(
        Icons.add_rounded,
        color: _isLoading ? Colors.grey : (isDark ? Colors.tealAccent : Colors.deepPurple),
        size: 28,
      ),
      onPressed: _isLoading ? null : _pickFiles,
      tooltip: 'Attach Files',
    );
  }

  Widget _buildLanguageButton(bool isDark) {
    return IconButton(
      icon: Icon(
        Icons.language_rounded,
        color: isDark ? Colors.tealAccent.withValues(alpha: 0.8) : Colors.deepPurple.withValues(alpha: 0.8), // High contrast
        size: 26, // Increased size
      ),
      onPressed: () => _showLanguageDialog(),
      tooltip: 'Select Language',
    );
  }

  Widget _buildMicButton(bool isDark) {
    return GestureDetector(
      onTap: _isLoading ? null : () {
        if (_isListening) {
          _stopListening();
        } else {
          _startListening();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isListening ? Colors.red.withValues(alpha: 0.2) : Colors.transparent,
        ),
        child: Icon(
          _isListening ? Icons.stop_circle_rounded : Icons.mic_none_rounded,
          key: ValueKey(_isListening),
          color: _isLoading 
              ? Colors.grey 
              : (_isListening ? Colors.redAccent : (isDark ? Colors.grey[400] : Colors.grey[600])),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildSendButton(bool isDark, Gradient gradient) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _isLoading ? null : gradient,
        color: _isLoading ? Colors.grey : null,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
        onPressed: _isLoading ? null : _sendMessage,
      ),
    );
  }

  void _showLanguageDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredLocales = _locales.where((locale) {
              final query = searchController.text.toLowerCase();
              return locale.name.toLowerCase().contains(query) || 
                     locale.localeId.toLowerCase().contains(query);
            }).toList();

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Language', 
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: isDark ? Colors.white : Colors.black87,
                    )
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: searchController,
                      style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Search language...',
                        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                        prefixIcon: Icon(Icons.search, color: isDark ? Colors.tealAccent : Colors.deepPurple),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setDialogState(() {}); // Rebuild dialog to filter list
                      },
                    ),
                  ),
                ],
              ),
              content: Theme(
                data: Theme.of(context).copyWith(
                  unselectedWidgetColor: isDark ? Colors.white30 : Colors.black26,
                ),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: filteredLocales.isEmpty
                      ? Center(
                          child: Text('No languages found', 
                            style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.black54)
                          )
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredLocales.length,
                          separatorBuilder: (context, index) => Divider(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final locale = filteredLocales[index];
                            final isSelected = locale.localeId == _currentLocaleId;
                            
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              title: Text(locale.name, 
                                style: GoogleFonts.inter(
                                  color: isSelected 
                                      ? (isDark ? Colors.tealAccent : Colors.deepPurple) 
                                      : (isDark ? Colors.white70 : Colors.black87),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 16,
                                )
                              ),
                              trailing: isSelected 
                                  ? Icon(Icons.check_circle, color: isDark ? Colors.tealAccent : Colors.deepPurple)
                                  : null,
                              onTap: () {
                                setState(() => _currentLocaleId = locale.localeId);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Language set to ${locale.name}'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: isDark ? Colors.tealAccent : Colors.deepPurple)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
