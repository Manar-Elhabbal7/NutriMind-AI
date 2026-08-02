enum MessageType { text, image, file, audio }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final String? mediaPath;
  final String? mediaName;
  final String? mediaDuration;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.mediaPath,
    this.mediaName,
    this.mediaDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'mediaPath': mediaPath,
      'mediaName': mediaName,
      'mediaDuration': mediaDuration,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      type: MessageType.values[json['type'] ?? 0],
      mediaPath: json['mediaPath'],
      mediaName: json['mediaName'],
      mediaDuration: json['mediaDuration'],
    );
  }
}
