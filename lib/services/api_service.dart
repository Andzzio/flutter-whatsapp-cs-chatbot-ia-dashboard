import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contact.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl =
      "https://django-whatsapp-cs-chatbot-ia-backend.onrender.com";
  // static const String baseUrl = "http://127.0.0.1:8000"; // Local Development

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

  Future<bool> sendMessage(
    String token,
    String phone,
    String text, {
    int? replyToId,
  }) async {
    try {
      final body = {
        "text": text,
        if (replyToId != null) "reply_to_id": replyToId,
      };

      final response = await http.post(
        Uri.parse("$baseUrl/api/contacts/$phone/send-message/"),
        headers: {"Authorization": token, "Content-Type": "application/json"},
        body: json.encode(body),
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

  // --- Catalog Methods ---
  Future<List<dynamic>> getProducts(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/products/"),
        headers: {"Authorization": token},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["products"] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching products: $e");
      return [];
    }
  }

  Future<bool> sendProduct(
    String token,
    String phone,
    String retailerId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/contacts/$phone/send-product/"),
        headers: {"Authorization": token, "Content-Type": "application/json"},
        body: json.encode({"retailer_id": retailerId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error sending product: $e");
      return false;
    }
  }

  Future<bool> deleteMessage(String token, int msgId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/messages/$msgId/delete/"),
        headers: {"Authorization": token},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error deletting message: $e");
      return false;
    }
  }

  Future<bool> createOrder(
    String token,
    String phone,
    List<dynamic> items,
  ) async {
    try {
      final body = {"items": items.map((i) => i.toJson()).toList()};

      final response = await http.post(
        Uri.parse("$baseUrl/api/contacts/$phone/create-order/"),
        headers: {"Authorization": token, "Content-Type": "application/json"},
        body: json.encode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error creating order: $e");
      return false;
    }
  }
}
