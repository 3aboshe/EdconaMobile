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

  // Encryption fields for end-to-end encryption
  final String? encryptedContent;
  final String? encryptedAesKey;
  final String? iv;
  final int? encryptionVersion;
  final bool isEncrypted;

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
    this.encryptedContent,
    this.encryptedAesKey,
    this.iv,
    this.encryptionVersion,
    this.isEncrypted = false,
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
      // Encryption fields
      encryptedContent: json['encryptedContent'] as String?,
      encryptedAesKey: json['encryptedAesKey'] as String?,
      iv: json['iv'] as String?,
      encryptionVersion: json['encryptionVersion'] as int?,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
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
      // Encryption fields
      'encryptedContent': encryptedContent,
      'encryptedAesKey': encryptedAesKey,
      'iv': iv,
      'encryptionVersion': encryptionVersion,
      'isEncrypted': isEncrypted,
    };
  }

  static MessageType _parseType(String? type) {
    if (type == null) return MessageType.TEXT;
    return MessageType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => MessageType.TEXT,
    );
  }

  /// Create a copy with updated fields (useful for decryption)
  Message copyWith({
    String? content,
    bool? isEncrypted,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      schoolId: schoolId,
      timestamp: timestamp,
      isRead: isRead,
      type: type,
      content: content ?? this.content,
      audioSrc: audioSrc,
      attachments: attachments,
      createdAt: createdAt,
      encryptedContent: encryptedContent,
      encryptedAesKey: encryptedAesKey,
      iv: iv,
      encryptionVersion: encryptionVersion,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }
}
