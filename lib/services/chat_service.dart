import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trulura/models/chat.dart';
import 'package:trulura/models/message.dart';
import 'package:trulura/services/reporting_service.dart';
import 'package:trulura/services/user_service.dart';

class ChatService {
  static const String _chatsKey = 'chats';
  static const String _messagesKey = 'messages';
  final UserService _userService = UserService();

  Future<void> _initSampleData() async {
    final prefs = await SharedPreferences.getInstance();
    final existingChats = prefs.getString(_chatsKey);
    final existingMessages = prefs.getString(_messagesKey);
    
    if (existingChats == null) {
      final chats = [
        Chat(
          id: '1',
          participantIds: ['1', '2'],
          lastMessage: 'See you there! 😊',
          lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        Chat(
          id: '2',
          participantIds: ['1', '3'],
          lastMessage: 'That sounds amazing!',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
          status: 'Active',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        Chat(
          id: '3',
          participantIds: ['1', '4'],
          lastMessage: 'Let\'s connect tomorrow',
          lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
          status: 'Paused',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      await prefs.setString(_chatsKey, jsonEncode(chats.map((c) => c.toJson()).toList()));
    }

    if (existingMessages == null) {
      final messages = [
        Message(
          id: '1',
          chatId: '1',
          senderId: '2',
          content: 'Hey! Want to grab coffee later?',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Message(
          id: '2',
          chatId: '1',
          senderId: '1',
          content: 'Sure! What time works for you?',
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        ),
        Message(
          id: '3',
          chatId: '1',
          senderId: '2',
          content: 'How about 3pm at the new place downtown?',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        Message(
          id: '4',
          chatId: '1',
          senderId: '1',
          content: 'See you there! 😊',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ];
      await prefs.setString(_messagesKey, jsonEncode(messages.map((m) => m.toJson()).toList()));
    }
  }

  Future<List<Chat>> getAllChats(String currentUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _initSampleData();
      final data = prefs.getString(_chatsKey);
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        final chats = jsonList.map((json) => Chat.fromJson(json)).toList();
        final userChats = chats.where((c) => c.participantIds.contains(currentUserId)).toList();
        for (var chat in userChats) {
          final participants = <dynamic>[];
          for (var id in chat.participantIds) {
            if (id != currentUserId) {
              final user = await _userService.getUserById(id);
              if (user != null) participants.add(user);
            }
          }
          userChats[userChats.indexOf(chat)] = chat.copyWith(participants: participants.cast<dynamic>().toList().cast());
        }
        return userChats;
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get chats: $e');
      return [];
    }
  }

  Future<Chat?> getChatById(String chatId, {required String currentUserId}) async {
    try {
      final chats = await getAllChats(currentUserId);
      return chats.firstWhere((c) => c.id == chatId);
    } catch (e) {
      debugPrint('Failed to get chat by id: $e');
      return null;
    }
  }

  Future<List<Message>> getMessagesByChatId(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _initSampleData();
      final data = prefs.getString(_messagesKey);
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        final messages = jsonList.map((json) => Message.fromJson(json)).toList();
        final now = DateTime.now();

        // Ephemeral retention: hide expired messages and auto-sanitize storage.
        final kept = <Message>[];
        bool changed = false;
        for (final m in messages) {
          if (m.expiresAt != null && now.isAfter(m.expiresAt!)) {
            changed = true;
            continue;
          }
          kept.add(m);
        }
        if (changed) {
          await prefs.setString(_messagesKey, jsonEncode(kept.map((m) => m.toJson()).toList()));
        }

        return kept.where((m) => m.chatId == chatId).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get messages: $e');
      return [];
    }
  }

  Future<bool> canInteractWithUser({required String otherUserId}) async {
    // Local-only enforcement for blocks. (Server enforcement can later mirror this.)
    try {
      return !(await ReportingService().isBlocked(otherUserId));
    } catch (e) {
      debugPrint('ChatService.canInteractWithUser failed: $e');
      return true;
    }
  }

  Future<void> saveMessage(Message message) async {
    try {
      // Basic block enforcement: if the receiver is blocked, prevent send.
      // (In this local stub we infer "other" user by chat participants elsewhere.
      // ChatThreadScreen performs a stronger check.)
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_messagesKey);
      final messages = data != null ? (jsonDecode(data) as List).map((json) => Message.fromJson(json)).toList() : <Message>[];
      messages.add(message);
      await prefs.setString(_messagesKey, jsonEncode(messages.map((m) => m.toJson()).toList()));
    } catch (e) {
      debugPrint('Failed to save message: $e');
    }
  }

  /// Creates (or returns an existing) chat between the current user and a
  /// target user. This is used by Sync when a connection is accepted / created.
  Future<Chat?> ensureChatWithUser({required String currentUserId, required String targetUserId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _initSampleData();
      final data = prefs.getString(_chatsKey);
      final chats = data != null ? (jsonDecode(data) as List).map((e) => Chat.fromJson(e as Map<String, dynamic>)).toList() : <Chat>[];

      final existing = chats.where((c) {
        final ids = c.participantIds.toSet();
        return ids.length == 2 && ids.contains(currentUserId) && ids.contains(targetUserId);
      }).toList(growable: false);
      if (existing.isNotEmpty) return existing.first;

      final now = DateTime.now();
      final id = 'c_${now.microsecondsSinceEpoch}_${currentUserId.hashCode.abs()}_${targetUserId.hashCode.abs()}';
      final next = Chat(id: id, participantIds: [currentUserId, targetUserId], status: 'Active', createdAt: now, updatedAt: now);
      chats.add(next);
      await prefs.setString(_chatsKey, jsonEncode(chats.map((c) => c.toJson()).toList()));
      return next;
    } catch (e) {
      debugPrint('ChatService.ensureChatWithUser failed: $e');
      return null;
    }
  }
}
