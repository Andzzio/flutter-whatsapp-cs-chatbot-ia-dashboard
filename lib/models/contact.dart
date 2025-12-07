import 'package:boty_flutter/models/message.dart';

class Contact {
  final String name;
  final String phone;
  bool isBotActive;
  int unreadCount;
  List<Message> messages;

  Contact({
    required this.name,
    required this.phone,
    required this.isBotActive,
    this.unreadCount = 0,
    required this.messages,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    var list = json['history'] as List;
    List<Message> messagesList = list.map((i) => Message.fromJson(i)).toList();

    return Contact(
      name: json['name'],
      phone: json['phone'],
      isBotActive: json['is_bot_active'] ?? true,
      unreadCount: json['unread_count'] ?? 0,
      messages: messagesList,
    );
  }
}
