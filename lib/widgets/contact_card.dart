import 'package:boty_flutter/models/contact.dart';
import 'package:flutter/material.dart';

class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;
  const ContactCard({super.key, required this.contact, required this.onTap});
  @override
  Widget build(BuildContext context) {
    String lastMsg = "Sin mensajes";
    if (contact.messages.isNotEmpty) {
      lastMsg = contact.messages.last.text;
    }
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : "?",
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          contact.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact.unreadCount > 0)
              Container(
                margin: EdgeInsets.only(right: 8),
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${contact.unreadCount}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            contact.isBotActive
                ? Icon(Icons.smart_toy, color: Colors.green, size: 20)
                : Icon(Icons.person, color: Colors.grey, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
