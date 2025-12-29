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
    String timeDisplay = "";
    if (contact.lastActivity != null) {
      final now = DateTime.now();
      final difference = now.difference(contact.lastActivity!);
      final localTime = contact.lastActivity!.toLocal();

      if (difference.inDays == 0 && localTime.day == now.day) {
        timeDisplay =
            "${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}";
      } else if (difference.inDays < 1 && localTime.day == now.day - 1) {
        timeDisplay = "Ayer";
      } else {
        timeDisplay = "${localTime.day}/${localTime.month}";
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          radius: 24,
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : "?",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeDisplay,
              style: TextStyle(
                color: contact.unreadCount > 0
                    ? Colors.green
                    : Colors.grey[600],
                fontSize: 12,
                fontWeight: contact.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (contact.needsHumanAttention)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Text(
                        "AYUDA",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              if (contact.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: contact.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
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
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (contact.isMuted)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.notifications_off_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                contact.isBotActive
                    ? const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.smart_toy,
                          size: 18,
                          color: Colors.green,
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.person, size: 18, color: Colors.grey),
                      ),
                if (contact.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${contact.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
