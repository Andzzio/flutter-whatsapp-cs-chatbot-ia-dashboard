import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contact.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl =
      "https://django-whatsapp-cs-chatbot-ia-backend.onrender.com";

  Future<List<Contact>> syncContacts(String token) async {
    if (token.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/sync/"),
        headers: {"Authorization": token},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> contactsJson = data["contacts"] ?? [];
        return contactsJson.map((json) => Contact.fromJson(json)).toList();
      } else {
        debugPrint("Error en sync: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error de conexión: $e");
      return [];
    }
  }

  Future<bool> sendMessage(String token, String phone, String text) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/contacts/$phone/send-message/"),
        headers: {"Authorization": token, "Content-Type": "application/json"},
        body: json.encode({"text": text}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error enviando mensaje: $e");
      return false;
    }
  }

  Future<bool> toggleBot(String token, String phone, bool isActive) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/contacts/$phone/toggle-bot/"),
        headers: {"Authorization": token, "Content-Type": "application/json"},
        body: json.encode({"is_active": isActive}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error toggle bot: $e");
      return false;
    }
  }

  Future<bool> markMessagesAsRead(String token, String phone) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/contacts/$phone/mark-read/"),
        headers: {"Authorization": token},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error marking read: $e");
      return false;
    }
  }
}
