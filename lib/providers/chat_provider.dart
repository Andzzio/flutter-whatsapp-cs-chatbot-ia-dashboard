import 'dart:async';
import 'package:boty_flutter/models/contact.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Contact> _contacts = [];
  String _apiToken = "";
  Timer? _syncTimer;

  List<Contact> get contacts => _contacts;
  String get apiToken => _apiToken;

  ChatProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _apiToken = prefs.getString('api_token') ?? "";
    notifyListeners();
    if (_apiToken.isNotEmpty) {
      _startSyncLoop();
    }
  }

  Future<void> setToken(String token) async {
    _apiToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
    notifyListeners();
    _startSyncLoop();
  }

  void _startSyncLoop() {
    _syncTimer?.cancel();

    _sync();
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _sync();
    });
  }

  Future<void> _sync() async {
    if (_apiToken.isEmpty) return;
    try {
      final newContacts = await _apiService.syncContacts(_apiToken);
      _contacts = newContacts;
      notifyListeners();
    } catch (e) {
      debugPrint("Error en provider: $e");
    }
  }

  Future<void> refreshContacts() async {
    await _sync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> sendMessage(String phone, String text) async {
    if (_apiToken.isEmpty) return;
    final success = await _apiService.sendMessage(_apiToken, phone, text);
    if (success) {
      _sync();
    }
  }

  Future<void> toggleBot(String phone, bool isActive) async {
    if (_apiToken.isEmpty) return;
    final success = await _apiService.toggleBot(_apiToken, phone, isActive);
    if (success) {
      final index = _contacts.indexWhere((c) => c.phone == phone);
      if (index != -1) {
        _contacts[index].isBotActive = isActive;
        notifyListeners();
      }
    }
  }

  Future<void> markAsRead(String phone) async {
    if (_apiToken.isEmpty) return;

    // Optimistic update
    final index = _contacts.indexWhere((c) => c.phone == phone);
    if (index != -1) {
      _contacts[index].unreadCount = 0;
      notifyListeners();
    }

    await _apiService.markMessagesAsRead(_apiToken, phone);
    // No need to sync immediately as the optimistic update handles the UI
    // The next periodic sync will confirm the state
  }
}
