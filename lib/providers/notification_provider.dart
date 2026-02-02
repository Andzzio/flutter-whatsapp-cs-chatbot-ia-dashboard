import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final String? notificationType;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
  final int? contactId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.notificationType,
    required this.createdAt,
    this.metadata = const {},
    this.contactId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      isRead: json['is_read'] ?? false,
      notificationType: json['notification_type'],
      createdAt: DateTime.parse(json['created_at']),
      metadata: json['metadata'] ?? {},
      contactId: json['contact'],
    );
  }
}

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token') ?? "";
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await _apiService.get('api/notifications/', token);

      if (response != null && response is List) {
        _notifications = response
            .map((e) => NotificationModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final token = await _getToken();
      await _apiService.patch('api/notifications/$id/mark_read/', token, {
        'is_read': true,
      });
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        await fetchNotifications();
      }
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      final token = await _getToken();
      await _apiService.delete('api/notifications/$id/', token);
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting notification: $e");
    }
  }

  Future<void> deleteAll() async {
    try {
      final token = await _getToken();
      await _apiService.delete('api/notifications/delete_all/', token);
      _notifications.clear();
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting all notifications: $e");
    }
  }
}
