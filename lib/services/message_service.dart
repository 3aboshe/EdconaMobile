import '../models/message.dart';
import 'api_service.dart';
import 'encryption_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageService {
  Future<List<Message>> getMessages({String? userId, String? otherUserId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['userId'] = userId;
      if (otherUserId != null) queryParams['otherUserId'] = otherUserId;

      final response = await ApiService.dio.get('/api/messages', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final messages = (response.data as List)
            .map((json) => Message.fromJson(json))
            .toList();

        // Decrypt encrypted messages
        final decryptedMessages = <Message>[];
        for (final message in messages) {
          if (message.isEncrypted && message.encryptedContent != null && userId != null) {
            final decrypted = await EncryptionService.decryptMessage(
              {
                'encryptedContent': message.encryptedContent,
                'encryptedAesKey': message.encryptedAesKey,
                'iv': message.iv,
              },
              userId,
            );
            decryptedMessages.add(message.copyWith(content: decrypted));
          } else {
            decryptedMessages.add(message);
          }
        }

        return decryptedMessages;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load messages: ${e.toString()}');
    }
  }

  Future<Message?> sendMessage(Map<String, dynamic> messageData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      // Get receiver's public key and encrypt message
      final receiverId = messageData['receiverId'] as String;
      final receiverPublicKey = await EncryptionService.getPublicKey(receiverId);

      if (receiverPublicKey != null && messageData['content'] != null) {
        final content = messageData['content'] as String;
        final encryptedData = await EncryptionService.encryptMessage(content, receiverPublicKey);

        // Replace plaintext with encrypted data
        messageData['encryptedContent'] = encryptedData['encryptedContent'];
        messageData['encryptedAesKey'] = encryptedData['encryptedAesKey'];
        messageData['iv'] = encryptedData['iv'];
        messageData['encryptionVersion'] = encryptedData['encryptionVersion'];
        messageData['isEncrypted'] = true;
        messageData.remove('content'); // Remove plaintext
      }

      final response = await ApiService.dio.post('/api/messages', data: messageData);
      if (response.statusCode == 201) {
        return Message.fromJson(response.data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await ApiService.dio.put('/api/messages/$id/read');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to mark message as read: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      final messages = await getMessages(userId: userId);

      Map<String, List<Message>> conversations = {};
      Map<String, Message> lastMessages = {};
      Map<String, int> unreadCounts = {};

      for (final message in messages) {
        final otherUserId = message.senderId == userId
            ? message.receiverId
            : message.senderId;

        if (!conversations.containsKey(otherUserId)) {
          conversations[otherUserId] = [];
          unreadCounts[otherUserId] = 0;
        }

        conversations[otherUserId]!.add(message);
        
        if (!lastMessages.containsKey(otherUserId) || message.timestamp.isAfter(lastMessages[otherUserId]!.timestamp)) {
           lastMessages[otherUserId] = message;
        }

        if (message.receiverId == userId && !message.isRead) {
          unreadCounts[otherUserId] = (unreadCounts[otherUserId] ?? 0) + 1;
        }
      }

      final result = <Map<String, dynamic>>[];
      for (final entry in conversations.entries) {
        final otherUserId = entry.key;
        final lastMessage = lastMessages[otherUserId];

        // Try to get other user details
        Map<String, dynamic>? otherUser;
        try {
          final userResponse = await ApiService.dio.get('/api/auth/user/$otherUserId');
          if (userResponse.statusCode == 200) {
            otherUser = userResponse.data;
          }
        } catch (e) {
          otherUser = {
            'id': otherUserId,
            'name': 'Unknown User',
            'subject': 'Unknown',
          };
        }

        result.add({
          'id': 'conv_$otherUserId',
          'otherUser': otherUser ?? {'id': otherUserId, 'name': 'Unknown User'},
          'lastMessage': {
            'message': lastMessage?.content ?? '',
            'timestamp': lastMessage?.timestamp.toIso8601String() ?? '',
          },
          'unreadCount': unreadCounts[otherUserId] ?? 0,
        });
      }

      result.sort((a, b) {
        final aTime = DateTime.tryParse(a['lastMessage']['timestamp']) ?? DateTime(0);
        final bTime = DateTime.tryParse(b['lastMessage']['timestamp']) ?? DateTime(0);
        return bTime.compareTo(aTime);
      });

      return result;
    } catch (e) {
      throw Exception('Failed to load conversations: ${e.toString()}');
    }
  }

  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final response = await ApiService.dio.get('/api/messages/unread/$userId');
      if (response.statusCode == 200) {
        return response.data['count'] ?? 0;
      }
    } catch (e) {
       final messages = await getMessages(userId: userId);
       return messages.where((msg) => msg.receiverId == userId && !msg.isRead).length;
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getTeachersForParent(String parentId) async {
    try {
      // This is a placeholder. You should implement the actual logic to fetch teachers for a parent.
      // For example, fetch children, then fetch teachers for their classes.
      // Or use a dedicated endpoint if available.
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getParentsForTeacher(String teacherId) async {
    try {
       // This is a placeholder.
       return [];
    } catch (e) {
      return [];
    }
  }

  /// Initialize encryption keys for user (call after login)
  Future<bool> initializeEncryptionKeys(String userId) async {
    try {
      // Check if keys already exist
      final hasKeys = await EncryptionService.hasKeys(userId);
      if (hasKeys) {
        return true;
      }

      // Generate and store new keys
      return await EncryptionService.generateAndStoreKeys(userId);
    } catch (e) {
      print('Error initializing encryption keys: $e');
      return false;
    }
  }
}
