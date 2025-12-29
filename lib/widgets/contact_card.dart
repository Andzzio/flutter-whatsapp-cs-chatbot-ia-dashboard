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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (contact.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 4,
                  children: contact.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
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
            if (contact.isMuted)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.notifications_off_rounded,
                  color: Colors.grey.withValues(alpha: 0.6),
                  size: 18,
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
