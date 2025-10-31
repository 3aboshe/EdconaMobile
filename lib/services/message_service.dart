import 'api_service.dart';

class MessageService {
  Future<List<Map<String, dynamic>>> getMessages({
    String? userId,
    String? senderId,
    String? receiverId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'limit': limit,
        'offset': offset,
      };

      if (userId != null) queryParams['userId'] = userId;
      if (senderId != null) queryParams['senderId'] = senderId;
      if (receiverId != null) queryParams['receiverId'] = receiverId;

      final response = await ApiService.dio.get(
        '/api/messages',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // Map the API response to our expected format
        final messages = List<Map<String, dynamic>>.from(response.data);
        return messages.map((msg) => {
          'id': msg['id'],
          'senderId': msg['senderId'],
          'receiverId': msg['receiverId'],
          'message': msg['content'], // API uses 'content' instead of 'message'
          'timestamp': msg['timestamp'],
          'read': msg['isRead'] ?? false, // API uses 'isRead' instead of 'read'
          'type': msg['type'] ?? 'TEXT',
          'attachments': msg['attachments'] ?? [],
        }).toList();
      }
    } catch (e) {
      throw Exception('Failed to load messages: ${e.toString()}');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      // Get all messages and create conversations from them
      final messages = await getMessages(userId: userId);

      // Group messages by the other user
      Map<String, List<Map<String, dynamic>>> conversations = {};
      Map<String, Map<String, dynamic>> lastMessages = {};
      Map<String, int> unreadCounts = {};

      for (final message in messages) {
        final otherUserId = message['senderId'] == userId
            ? message['receiverId']
            : message['senderId'];

        if (otherUserId != null) {
          if (!conversations.containsKey(otherUserId)) {
            conversations[otherUserId] = [];
            unreadCounts[otherUserId] = 0;
          }

          conversations[otherUserId]!.add(message);
          lastMessages[otherUserId] = message;

          // Count unread messages (received and not read)
          if (message['receiverId'] == userId && message['read'] == false) {
            unreadCounts[otherUserId] = (unreadCounts[otherUserId] ?? 0) + 1;
          }
        }
      }

      // Convert to conversation format
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
          // Create basic user info if we can't get details
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
            'message': lastMessage?['message'] ?? '',
            'timestamp': lastMessage?['timestamp'] ?? '',
          },
          'unreadCount': unreadCounts[otherUserId] ?? 0,
        });
      }

      // Sort by last message timestamp (most recent first)
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

  Future<Map<String, dynamic>> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    String? childId,
    String? subjectId,
  }) async {
    try {
      final data = {
        'senderId': senderId,
        'receiverId': receiverId,
        'content': message, // API expects 'content' not 'message'
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'TEXT',
        'isRead': false,
      };

      if (childId != null) data['childId'] = childId;
      if (subjectId != null) data['subjectId'] = subjectId;

      final response = await ApiService.dio.post(
        '/api/messages',
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        final errorData = response.data;
        return {'success': false, 'message': errorData['message'] ?? 'Failed to send message'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to send message: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> markMessageAsRead(String messageId) async {
    try {
      final response = await ApiService.dio.put('/api/messages/$messageId/read');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to mark message as read: ${e.toString()}'};
    }
    return {'success': false, 'message': 'Failed to mark message as read'};
  }

  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final response = await ApiService.dio.get('/api/messages/unread/$userId');

      if (response.statusCode == 200) {
        return response.data['count'] ?? 0;
      }
    } catch (e) {
      // Calculate from messages if dedicated endpoint doesn't exist
      final messages = await getMessages(userId: userId);
      final unreadCount = messages.where((msg) =>
          msg['receiverId'] == userId && msg['read'] == false
      ).length;
      return unreadCount;
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getTeachersForParent(String parentId) async {
    try {
      // First try dedicated endpoint
      final response = await ApiService.dio.get('/api/users/teachers/$parentId');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      // If endpoint doesn't exist, return empty list
      // In a real implementation, you might need to get this from
      // the parent's children's classes or other relationships
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getParentsForTeacher(String teacherId) async {
    try {
      final response = await ApiService.dio.get('/api/users/parents/$teacherId');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      // Return empty if endpoint doesn't exist
    }
    return [];
  }
}