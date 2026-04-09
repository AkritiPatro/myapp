import 'dart:typed_data';

enum ChatMessageType { user, bot }

class ChatAttachment {
  final String name;
  final Uint8List bytes;
  final String mimeType;

  ChatAttachment({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  bool get isImage => mimeType.startsWith('image/');
}

class ChatMessage {
  final String text;
  final ChatMessageType type;
  final DateTime timestamp;
  final List<ChatAttachment> attachments;

  ChatMessage({
    required this.text,
    required this.type,
    DateTime? timestamp,
    this.attachments = const [],
  }) : timestamp = timestamp ?? DateTime.now();
}