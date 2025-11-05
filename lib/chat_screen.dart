    import 'package:flutter/material.dart';
    import 'package:fluttertoast/fluttertoast.dart';
    import 'package:google_fonts/google_fonts.dart';
    import 'package:provider/provider.dart';
    import 'theme_provider.dart'; // Assuming you still use this
    import 'gemini_service.dart'; // Import your new Gemini service

    class ChatScreen extends StatefulWidget {
      const ChatScreen({super.key});

      @override
      State<ChatScreen> createState() => _ChatScreenState();
    }

    class _ChatScreenState extends State<ChatScreen> {
      final TextEditingController _messageController = TextEditingController();
      final GeminiChatService _geminiService = GeminiChatService(); // Instantiate your Gemini service
      final List<ChatMessage> _messages = []; // This list will hold the messages to display
      bool _isLoading = false; // To show a loading indicator while Gemini is responding

      @override
      void initState() {
        super.initState();
        // Add an initial greeting message from the bot when the chat screen loads
        _addMessage(ChatMessage(text: "Hello! How can I help you today?", type: ChatMessageType.bot));
      }

      @override
      void dispose() {
        _messageController.dispose(); // Clean up the controller when the widget is disposed
        super.dispose();
      }

      // Helper function to add a message to the UI and trigger a rebuild
      void _addMessage(ChatMessage message) {
        setState(() {
          _messages.add(message);
        });
      }

      // Function to send the user's message to Gemini and get a response
      Future<void> _sendMessage() async {
        // Prevent sending empty messages or multiple messages while loading
        if (_messageController.text.trim().isEmpty || _isLoading) return;

        final userMessageText = _messageController.text.trim();
        _messageController.clear(); // Clear input field immediately for good UX
        _addMessage(ChatMessage(text: userMessageText, type: ChatMessageType.user)); // Display user's message

        setState(() {
          _isLoading = true; // Show loading indicator
        });

        try {
          // Call the Gemini service to get a response
          final botResponseText = await _geminiService.sendMessage(userMessageText);
          _addMessage(ChatMessage(text: botResponseText, type: ChatMessageType.bot)); // Display bot's response
        } catch (e) {
          print("Error sending message to Gemini: $e");
          Fluttertoast.showToast(msg: "Error: Could not get a response.", backgroundColor: Colors.red);
          _addMessage(ChatMessage(text: "Error: Could not get a response.", type: ChatMessageType.bot)); // Display error message
        } finally {
          setState(() {
            _isLoading = false; // Hide loading indicator
          });
        }
      }

      // Function to clear the chat and start a new conversation
      void _clearChat() {
        setState(() {
          _messages.clear(); // Clear UI messages
          _geminiService.clearHistory(); // Clear history in the Gemini service
          _addMessage(ChatMessage(text: "Hello! How can I help you today?", type: ChatMessageType.bot)); // Restart with greeting
        });
      }

      @override
      Widget build(BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          appBar: AppBar(
            title: Text('Gemini Chatbot', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            centerTitle: true,
            // Adjust AppBar background color based on theme
            backgroundColor: isDark ? Colors.black87 : Theme.of(context).primaryColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _clearChat,
                tooltip: 'Start a new chat',
              ),
              IconButton(
                icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Align(
                      alignment: message.type == ChatMessageType.user
                          ? Alignment.centerRight // User messages on the right
                          : Alignment.centerLeft,  // Bot messages on the left
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          // Customize message bubble colors based on sender and theme
                          color: message.type == ChatMessageType.user
                              ? (isDark ? Colors.blueGrey : Colors.blueAccent)
                              : (isDark ? Colors.grey : Colors.grey),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            // Customize text color based on sender and theme
                            color: message.type == ChatMessageType.user
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Show a loading indicator when the bot is processing
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                ),
              // Input field for new messages
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask Gemini...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0)),
                          fillColor: isDark ? Colors.grey : Colors.grey,
                          filled: true,
                        ),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        onSubmitted: (_) => _sendMessage(), // Send on Enter key press
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: isDark ? Colors.tealAccent : Theme.of(context).primaryColor,
                      onPressed: _sendMessage, // Send on button tap
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }
