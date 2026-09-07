import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:trulura/models/chat.dart';
import 'package:trulura/models/message.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/services/database_service/database_service.dart';
import 'package:trulura/services/reporting_service.dart';
import 'package:trulura/services/user_service.dart';

/// A failure the person starting a conversation should actually be told about.
///
/// Deliberately distinct from the pattern in [ChatService.ensureChatWithUser],
/// which catches everything and returns null. That is survivable for the Sync
/// flow, where a chat is a side effect of accepting a connection, but not for
/// the New Message screen: there, a null means the user tapped a name, saw
/// nothing happen, and has no idea whether they are signed out, offline, or
/// looking at an account that has been deleted.
class StartConversationException implements Exception {
  /// Shown to the user verbatim, so it is phrased for a person, not a log.
  final String message;

  /// SQLSTATE from PostgREST when the failure came from the database, so a
  /// caller can branch on it and a bug report can name it. Null for failures
  /// detected client-side.
  final String? code;

  const StartConversationException(this.message, {this.code});

  @override
  String toString() =>
      'StartConversationException(${code ?? 'client'}): $message';
}

class ChatService {
  static const String _chatsKey = 'chats';
  static const String _messagesKey = 'messages';
  final UserService _userService = UserService();

  bool get _supabaseReady => DatabaseService.instance.isInitialized;

  static final RegExp _explicitZone = RegExp(r'(Z|z|[+-]\d{2}:?\d{2})$');

  /// Parses a timestamp column into device-local time.
  ///
  /// `conversations.created_at` and `messages.created_at` are
  /// `timestamp without time zone`, so PostgREST serialises them with no zone
  /// suffix -- `2026-09-07T14:03:11.123456`. `DateTime.parse` reads an
  /// unsuffixed string as *device-local*, but the server writes UTC, so every
  /// timestamp came out shifted by the device's UTC offset: messages sent
  /// "now" rendered hours away, and relative labels like "2h ago" were wrong
  /// by that offset everywhere.
  ///
  /// Sort order survived the bug because every value was skewed identically,
  /// which is exactly why it was invisible in the list and only wrong on the
  /// clock. Reinterpret an unsuffixed value as UTC before converting.
  DateTime _dateFrom(dynamic raw) {
    final text = raw?.toString() ?? '';
    if (text.isEmpty) return DateTime.now();
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return DateTime.now();
    if (parsed.isUtc || _explicitZone.hasMatch(text)) return parsed.toLocal();
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).toLocal();
  }

  bool _isMissingRelation(Object error, String relation) {
    final msg = error.toString().toLowerCase();
    final needle = relation.toLowerCase();
    return msg.contains('42p01') ||
        (msg.contains(needle) && msg.contains('does not exist')) ||
        (msg.contains('pgrst205') && msg.contains(needle));
  }

  Message _messageFromRow(Map<String, dynamic> row) {
    final created = _dateFrom(row['created_at']);
    return Message(
      id: row['id'].toString(),
      chatId: row['conversation_id'].toString(),
      senderId: row['sender_id'].toString(),
      content: (row['content'] ?? '').toString(),
      timestamp: created,
      createdAt: created,
      updatedAt: created,
    );
  }

  User _profileFromRow(Map<String, dynamic> row) {
    final now = DateTime.now();
    return User.fromJson({
      'id': row['id']?.toString() ?? '',
      'name': row['display_name']?.toString() ?? '',
      'username': row['username']?.toString() ?? '',
      'bio': row['bio']?.toString() ?? row['about_me']?.toString() ?? '',
      'profile_photo_url': row['profile_photo_url']?.toString() ??
          row['avatar_url']?.toString() ??
          '',
      'createdAt': row['created_at']?.toString() ?? now.toIso8601String(),
      'updatedAt': row['updated_at']?.toString() ?? now.toIso8601String(),
    });
  }

  Future<Map<String, User>> _profilesById(Iterable<String> ids) async {
    final unique = ids.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (unique.isEmpty || !_supabaseReady) return <String, User>{};

    try {
      final rows = await DatabaseService.instance.client
          .from('profiles')
          .select(
              'id, username, display_name, bio, about_me, profile_photo_url, avatar_url, created_at, updated_at')
          .inFilter('id', unique);
      return {
        for (final row in (rows as List).whereType<Map<String, dynamic>>())
          row['id'].toString(): _profileFromRow(row),
      };
    } catch (e) {
      debugPrint('ChatService._profilesById failed: $e');
      return <String, User>{};
    }
  }

  Future<List<Chat>> _getRemoteChats(String currentUserId) async {
    final client = DatabaseService.instance.client;

    List<Map<String, dynamic>> listRows = const <Map<String, dynamic>>[];
    try {
      final rows = await client
          .from('conversation_list')
          .select(
              'conversation_id, created_at, last_message, last_message_at, last_sender_id')
          .order('last_message_at', ascending: false, nullsFirst: false)
          .order('created_at', ascending: false);
      listRows = (rows as List).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      if (!_isMissingRelation(e, 'conversation_list')) rethrow;

      final memberRows = await client
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', currentUserId);
      final conversationIds = (memberRows as List)
          .whereType<Map<String, dynamic>>()
          .map((row) => row['conversation_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      if (conversationIds.isEmpty) return <Chat>[];

      final conversations = await client
          .from('conversations')
          .select('id, created_at')
          .inFilter('id', conversationIds)
          .order('created_at', ascending: false);
      listRows = (conversations as List)
          .whereType<Map<String, dynamic>>()
          .map((row) => {
                'conversation_id': row['id'],
                'created_at': row['created_at'],
              })
          .toList();
    }

    final conversationIds = listRows
        .map((row) => row['conversation_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (conversationIds.isEmpty) return <Chat>[];

    final memberRows = await client
        .from('conversation_members')
        .select('conversation_id, user_id')
        .inFilter('conversation_id', conversationIds);
    final idsByConversation = <String, List<String>>{};
    for (final row in (memberRows as List).whereType<Map<String, dynamic>>()) {
      final conversationId = row['conversation_id']?.toString() ?? '';
      final userId = row['user_id']?.toString() ?? '';
      if (conversationId.isEmpty || userId.isEmpty) continue;
      idsByConversation
          .putIfAbsent(conversationId, () => <String>[])
          .add(userId);
    }

    final missingLastIds = listRows
        .where((row) => row['last_message_at'] == null)
        .map((row) => row['conversation_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final lastByConversation = <String, Message>{};
    if (missingLastIds.isNotEmpty) {
      final messageRows = await client
          .from('messages')
          .select('id, conversation_id, sender_id, content, created_at')
          .inFilter('conversation_id', missingLastIds)
          .order('created_at', ascending: false);
      for (final row
          in (messageRows as List).whereType<Map<String, dynamic>>()) {
        final message = _messageFromRow(row);
        lastByConversation.putIfAbsent(message.chatId, () => message);
      }
    }

    final otherIds = idsByConversation.values
        .expand((ids) => ids)
        .where((id) => id != currentUserId)
        .toSet();
    final profiles = await _profilesById(otherIds);

    final chats = <Chat>[];
    for (final row in listRows) {
      final id = row['conversation_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final created = _dateFrom(row['created_at']);
      final members = idsByConversation[id] ?? <String>[currentUserId];
      final otherUsers = members
          .where((memberId) => memberId != currentUserId)
          .map((memberId) => profiles[memberId])
          .whereType<User>()
          .toList(growable: false);
      final fallbackLast = lastByConversation[id];
      final lastMessage =
          row['last_message']?.toString() ?? fallbackLast?.content;
      final lastAt = row['last_message_at'] == null
          ? fallbackLast?.timestamp
          : _dateFrom(row['last_message_at']);

      chats.add(Chat(
        id: id,
        participantIds: members,
        participants: otherUsers,
        lastMessage: lastMessage,
        lastMessageTime: lastAt,
        status: 'Active',
        createdAt: created,
        updatedAt: lastAt ?? created,
      ));
    }

    chats.sort((a, b) => (b.lastMessageTime ?? b.createdAt)
        .compareTo(a.lastMessageTime ?? a.createdAt));
    return chats;
  }

  Future<List<Message>> _getRemoteMessagesByChatId(String chatId) async {
    final rows = await DatabaseService.instance.client
        .from('messages')
        .select('id, conversation_id, sender_id, content, created_at')
        .eq('conversation_id', chatId)
        .order('created_at', ascending: true);
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(_messageFromRow)
        .toList(growable: false);
  }

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
      await prefs.setString(
          _chatsKey, jsonEncode(chats.map((c) => c.toJson()).toList()));
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
          timestamp:
              DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          isRead: true,
          createdAt:
              DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          updatedAt:
              DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
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
      await prefs.setString(
          _messagesKey, jsonEncode(messages.map((m) => m.toJson()).toList()));
    }
  }

  Future<List<Chat>> getAllChats(String currentUserId) async {
    try {
      if (_supabaseReady) {
        return await _getRemoteChats(currentUserId);
      }
      final prefs = await SharedPreferences.getInstance();
      await _initSampleData();
      final data = prefs.getString(_chatsKey);
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        final chats = jsonList.map((json) => Chat.fromJson(json)).toList();
        final userChats = chats
            .where((c) => c.participantIds.contains(currentUserId))
            .toList();
        for (var chat in userChats) {
          final participants = <dynamic>[];
          for (var id in chat.participantIds) {
            if (id != currentUserId) {
              final user = await _userService.getUserById(id);
              if (user != null) participants.add(user);
            }
          }
          userChats[userChats.indexOf(chat)] = chat.copyWith(
              participants: participants.cast<dynamic>().toList().cast());
        }
        return userChats;
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get chats: $e');
      return [];
    }
  }

  Future<Chat?> getChatById(String chatId,
      {required String currentUserId}) async {
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
      if (_supabaseReady) {
        return await _getRemoteMessagesByChatId(chatId);
      }
      final prefs = await SharedPreferences.getInstance();
      await _initSampleData();
      final data = prefs.getString(_messagesKey);
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        final messages =
            jsonList.map((json) => Message.fromJson(json)).toList();
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
          await prefs.setString(
              _messagesKey, jsonEncode(kept.map((m) => m.toJson()).toList()));
        }

        return kept.where((m) => m.chatId == chatId).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
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

  /// Persists a message.
  ///
  /// Throws when a remote send fails. ChatThreadScreen._sendMessage tells sent
  /// from failed purely by whether this throws: on success it clears the
  /// pending bubble, on error it marks it retryable. Swallowing the error made
  /// every rejection -- an RLS denial, the messages_content_non_empty
  /// constraint, an offline socket -- look like a successful send, and the
  /// message vanished from the UI without ever reaching the server.
  ///
  /// The local SharedPreferences path keeps its catch: that is the offline
  /// fallback, where a write failure is not something the user can act on.
  Future<void> saveMessage(Message message) async {
    if (_supabaseReady) {
      // created_at is deliberately not sent. messages.created_at is
      // `timestamp without time zone` with a `now()` default, so the server
      // writes UTC. Sending a client ISO string stores the device's local
      // wall clock as though it were UTC, which _dateFrom then reads back as
      // UTC and shifts again -- the send would land in the future or past by
      // the device's offset. Let the default win; it is the same reason
      // PostService omits created_at/updated_at.
      await DatabaseService.instance.client.from('messages').insert({
        'conversation_id': message.chatId,
        'sender_id': message.senderId,
        'content': message.content,
      });
      return;
    }
    try {
      // Basic block enforcement: if the receiver is blocked, prevent send.
      // (In this local stub we infer "other" user by chat participants elsewhere.
      // ChatThreadScreen performs a stronger check.)
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_messagesKey);
      final messages = data != null
          ? (jsonDecode(data) as List)
              .map((json) => Message.fromJson(json))
              .toList()
          : <Message>[];
      messages.add(message);
      await prefs.setString(
          _messagesKey, jsonEncode(messages.map((m) => m.toJson()).toList()));
    } catch (e) {
      debugPrint('Failed to save message: $e');
    }
  }

  /// People the signed-in user could start a conversation with.
  ///
  /// Verified by role on 2026-09-07 that `authenticated` can read other users'
  /// profile rows, so this needs no migration: RLS on profiles is enabled and
  /// denies anon entirely, but a signed-in user sees every profile. If that
  /// policy is ever tightened to self-only, this returns an empty list and the
  /// picker shows its empty state rather than failing.
  ///
  /// Throws [StartConversationException] instead of returning an empty list
  /// when the user is not signed in, so the screen can say which of the two it
  /// is -- "nobody to message yet" and "you are signed out" look identical
  /// otherwise.
  Future<List<User>> getConnectableProfiles() async {
    if (!_supabaseReady) {
      throw const StartConversationException(
        'Messaging is unavailable right now. Check your connection and try again.',
      );
    }
    final client = DatabaseService.instance.client;
    final me = client.auth.currentUser?.id;
    if (me == null) {
      throw const StartConversationException(
        'You need to be signed in to start a conversation.',
        code: 'not_authenticated',
      );
    }

    try {
      final rows = await client
          .from('profiles')
          .select(
              'id, username, display_name, bio, about_me, profile_photo_url, avatar_url, created_at, updated_at')
          .neq('id', me)
          // supabase-dart's `order` defaults to descending; be explicit.
          .order('display_name', ascending: true)
          .limit(200);
      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(_profileFromRow)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw StartConversationException(
        e.message.isEmpty ? 'Could not load people to message.' : e.message,
        code: e.code,
      );
    }
  }

  /// Starts (or reuses) the direct conversation with [otherUserId] and returns
  /// its id.
  ///
  /// Goes through the `start_direct_conversation` RPC, which is the only path
  /// that can create a conversation: 20260907_close_self_join_hole dropped the
  /// INSERT policies on conversations and conversation_members, so a direct
  /// insert from the client is refused. The RPC is idempotent -- picking
  /// somebody you already have a thread with returns that thread's id rather
  /// than opening a second one.
  ///
  /// Throws [StartConversationException] on every failure. It never returns a
  /// sentinel, because the caller navigates on the result and a silent null
  /// would strand the user on the picker with no explanation.
  Future<String> startDirectConversation(String otherUserId) async {
    if (!_supabaseReady) {
      throw const StartConversationException(
        'Messaging is unavailable right now. Check your connection and try again.',
      );
    }
    final client = DatabaseService.instance.client;
    final me = client.auth.currentUser?.id;
    if (me == null) {
      throw const StartConversationException(
        'You need to be signed in to start a conversation.',
        code: 'not_authenticated',
      );
    }
    final target = otherUserId.trim();
    if (target.isEmpty) {
      throw const StartConversationException('That account is missing an id.');
    }
    if (target == me) {
      throw const StartConversationException(
        'You cannot start a conversation with yourself.',
      );
    }

    try {
      final result = await client.rpc(
        'start_direct_conversation',
        params: {'p_other_user_id': target},
      );
      final id = result?.toString() ?? '';
      if (id.isEmpty) {
        throw const StartConversationException(
          'The server did not return a conversation. Try again.',
        );
      }
      return id;
    } on PostgrestException catch (e) {
      throw StartConversationException(_startFailureMessage(e), code: e.code);
    }
  }

  /// Turns the RPC's own SQLSTATEs into something a person can act on.
  ///
  /// The codes are raised deliberately inside start_direct_conversation, so
  /// they are a contract rather than incidental Postgres noise.
  String _startFailureMessage(PostgrestException e) {
    switch (e.code) {
      case '42501':
        return 'Your session has expired. Sign in again to start a conversation.';
      case '22023':
        return 'Pick someone other than yourself to start a conversation.';
      case '23503':
        return 'That account no longer exists.';
    }
    return e.message.isEmpty
        ? 'Could not start the conversation. Try again.'
        : e.message;
  }

  /// Creates (or returns an existing) chat between the current user and a
  /// target user. This is used by Sync when a connection is accepted / created.
  Future<Chat?> ensureChatWithUser(
      {required String currentUserId, required String targetUserId}) async {
    try {
      if (_supabaseReady) {
        final conversationId = await DatabaseService.instance.client
            .rpc('start_direct_conversation', params: {
          'p_other_user_id': targetUserId,
        });
        final chat = await getChatById(
          conversationId.toString(),
          currentUserId: currentUserId,
        );
        return chat ??
            Chat(
              id: conversationId.toString(),
              participantIds: [currentUserId, targetUserId],
              status: 'Active',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
      }
      final prefs = await SharedPreferences.getInstance();
      await _initSampleData();
      final data = prefs.getString(_chatsKey);
      final chats = data != null
          ? (jsonDecode(data) as List)
              .map((e) => Chat.fromJson(e as Map<String, dynamic>))
              .toList()
          : <Chat>[];

      final existing = chats.where((c) {
        final ids = c.participantIds.toSet();
        return ids.length == 2 &&
            ids.contains(currentUserId) &&
            ids.contains(targetUserId);
      }).toList(growable: false);
      if (existing.isNotEmpty) return existing.first;

      final now = DateTime.now();
      final id =
          'c_${now.microsecondsSinceEpoch}_${currentUserId.hashCode.abs()}_${targetUserId.hashCode.abs()}';
      final next = Chat(
          id: id,
          participantIds: [currentUserId, targetUserId],
          status: 'Active',
          createdAt: now,
          updatedAt: now);
      chats.add(next);
      await prefs.setString(
          _chatsKey, jsonEncode(chats.map((c) => c.toJson()).toList()));
      return next;
    } catch (e) {
      debugPrint('ChatService.ensureChatWithUser failed: $e');
      return null;
    }
  }
}
