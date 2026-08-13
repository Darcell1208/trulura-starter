import 'package:trulura/models/user.dart';

class Chat {
  final String id;
  final List<String> participantIds;
  final List<User> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.participantIds,
    this.participants = const [],
    this.lastMessage,
    this.lastMessageTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'participantIds': participantIds,
    'participants': participants.map((u) => u.toJson()).toList(),
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime?.toIso8601String(),
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
    id: json['id'] as String,
    participantIds: (json['participantIds'] as List<dynamic>).map((e) => e as String).toList(),
    participants: (json['participants'] as List<dynamic>?)?.map((e) => User.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    lastMessage: json['lastMessage'] as String?,
    lastMessageTime: json['lastMessageTime'] != null ? DateTime.parse(json['lastMessageTime'] as String) : null,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Chat copyWith({
    String? id,
    List<String>? participantIds,
    List<User>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Chat(
    id: id ?? this.id,
    participantIds: participantIds ?? this.participantIds,
    participants: participants ?? this.participants,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
