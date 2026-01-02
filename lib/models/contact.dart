import 'package:boty_flutter/models/message.dart';

class Contact {
  final String name;
  final String phone;
  bool isBotActive;
  bool isMuted;
  bool needsHumanAttention;
  int unreadCount;
  List<Message> messages;

  Contact({
    required this.name,
    required this.phone,
    required this.isBotActive,
    this.isMuted = false,
    this.needsHumanAttention = false,
    this.unreadCount = 0,
    required this.messages,
    this.notes = "",
    this.tags = const [],
    this.lastActivity,
  });

  String notes;
  List<String> tags;
  DateTime? lastActivity;

  factory Contact.fromJson(Map<String, dynamic> json) {
    var list = json['history'] as List;
    List<Message> messagesList = list.map((i) => Message.fromJson(i)).toList();

    DateTime? lastActivityDate;
    if (json['last_activity'] != null) {
      lastActivityDate = DateTime.tryParse(json['last_activity']);
    }

    return Contact(
      name: json['name'],
      phone: json['phone'],
      isBotActive: json['is_bot_active'] ?? true,
      unreadCount: json['unread_count'] ?? 0,
      needsHumanAttention: json['needs_human_attention'] ?? false,
      messages: messagesList,
      lastActivity: lastActivityDate,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }
}
