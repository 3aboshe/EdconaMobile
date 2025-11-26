enum MessageType {
  TEXT,
  VOICE,
  FILE,
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String schoolId;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String? content;
  final String? audioSrc;
  final Map<String, dynamic>? attachments;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.schoolId,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.TEXT,
    this.content,
    this.audioSrc,
    this.attachments,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      schoolId: json['schoolId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      type: _parseType(json['type'] as String?),
      content: json['content'] as String?,
      audioSrc: json['audioSrc'] as String?,
      attachments: json['attachments'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'schoolId': schoolId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.toString().split('.').last,
      'content': content,
      'audioSrc': audioSrc,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static MessageType _parseType(String? type) {
    if (type == null) return MessageType.TEXT;
    return MessageType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => MessageType.TEXT,
    );
  }
}
