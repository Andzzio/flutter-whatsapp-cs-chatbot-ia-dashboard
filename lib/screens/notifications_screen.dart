import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:timeago/timeago.dart'
//as timeago; // Need to add timeago to pubspec
import '../providers/notification_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchNotifications();
    });
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).markAsRead(notification.id);
    }

    // Navigate to Chat if contactId is present or phone is in metadata
    final phone = notification.metadata['phone'];
    if (phone != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      try {
        final contact = chatProvider.contacts.firstWhere(
          (c) => c.phone == phone,
        );

        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ChatScreen(contact: contact)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Contacto no encontrado ($phone). Intenta recargar."),
          ),
        );
      }
    } else if (notification.contactId != null) {
      // Fallback if no phone in metadata (older notifs?)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Esta notificación no tiene datos de enlace directo."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificaciones"),
        actions: [
          if (notifProvider.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: "Borrar Todo",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("¿Borrar todo?"),
                    content: const Text(
                      "¿Estás seguro de que deseas eliminar todas las notificaciones?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cancelar"),
                      ),
                      TextButton(
                        onPressed: () {
                          notifProvider.deleteAll();
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          "Borrar",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: notifProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifProvider.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No tienes notificaciones pendientes",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifProvider.notifications.length,
              itemBuilder: (context, index) {
                final notification = notifProvider.notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onMarkRead: () => notifProvider.markAsRead(notification.id),
                  onDelete: () =>
                      notifProvider.deleteNotification(notification.id),
                  onTapAction: (n) => _handleNotificationTap(n),
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;
  final Function(NotificationModel) onTapAction;

  const _NotificationCard({
    required this.notification,
    required this.onMarkRead,
    required this.onDelete,
    required this.onTapAction,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: n.isRead
            ? (isDark ? const Color(0xFF1E1E24) : Colors.white)
            : (isDark ? const Color(0xFF2A2A35) : const Color(0xFFF0F7FF)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: n.isRead
              ? Colors.transparent
              : theme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Always Visible)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              if (!n.isRead && !_isExpanded) {
                // Optional: Mark read on expand? Or keep manual?
                // keeping manual or explicit click is better based on user request "full details on click"
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: n.isRead
                          ? Colors.grey.withOpacity(0.1)
                          : theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      n.notificationType == 'handoff'
                          ? Icons.support_agent_rounded
                          : n.notificationType == 'order'
                          ? Icons.shopping_bag_outlined
                          : Icons.notifications_outlined,
                      color: n.isRead ? Colors.grey : theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: n.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF2D3142),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!n.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.body,
                          maxLines: _isExpanded ? null : 1,
                          overflow: _isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        if (!_isExpanded) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateTime.parse(
                              n.createdAt.toString(),
                            ).toLocal().toString().substring(0, 16),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content (Actions & Details)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Date
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Recibido: ${DateTime.parse(n.createdAt.toString()).toLocal().toString().substring(0, 19)}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Metadata (if any)
                      if (n.metadata.isNotEmpty) ...[
                        Text(
                          "Detalles Adicionales:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...n.metadata.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "• ${e.key}: ",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.value.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Actions
                      Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: widget.onDelete,
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              "Eliminar",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                          if (!n.isRead)
                            TextButton.icon(
                              onPressed: () {
                                widget.onMarkRead();
                                // Optional: collapse after action?
                              },
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                              label: const Text("Marcar Leído"),
                            ),
                          ElevatedButton.icon(
                            onPressed: () => widget.onTapAction(n),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            label: const Text("Ver Chat"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
