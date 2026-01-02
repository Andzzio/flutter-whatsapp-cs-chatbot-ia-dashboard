import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/contact.dart';
import '../models/snippet.dart';

class ApiService {
  static const String baseUrl =
      "https://django-whatsapp-cs-chatbot-ia-backend.onrender.com";
  // static const String baseUrl = "http://127.0.0.1:8000"; // Local Development

  Future<List<Contact>> syncContacts(
    String token, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (token.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/sync/?limit=$limit&offset=$offset"),
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

  Future<bool> sendCatalog(String token, String phone) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/contacts/$phone/send-catalog/"),
        headers: {"Authorization": token},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error sending catalog: $e");
      return false;
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

  Future<({Map<String, dynamic>? data, String? error})> createOrder(
    String token,
    String phone,
    List<dynamic> items, {
    double shippingCost = 0.0,
  }) async {
    try {
      final body = {
        "items": items.map((i) => i.toJson()).toList(),
        "shipping_cost": shippingCost,
      };

      final response = await http.post(
        Uri.parse("$baseUrl/api/contacts/$phone/create-order/"),
        headers: {"Authorization": token, "Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return (
          data: jsonResponse['order'] as Map<String, dynamic>,
          error: null,
        );
      } else {
        // Try to parse error message
        try {
          final errBody = json.decode(response.body);
          return (
            data: null,
            error:
                errBody["error"]?.toString() ?? "Error ${response.statusCode}",
          );
        } catch (_) {
          return (data: null, error: "Error servidor: ${response.statusCode}");
        }
      }
    } catch (e) {
      debugPrint("Error creating order: $e");
      return (data: null, error: "Error de conexión: $e");
    }
  }

  // --- DASHBOARD STATS (V2) ---
  Future<Map<String, dynamic>> getDashboardStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/dashboard-stats/'),
        headers: {"Authorization": token},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint("Error stats: $e");
      return {};
    }
  }

  Future<List<Snippet>> getSnippets(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/snippets/'),
        headers: {"Authorization": token},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['snippets'] as List;
        return list.map((json) => Snippet.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error snippets: $e");
      return [];
    }
  }

  Future<bool> createSnippet(
    String token,
    String shortcut,
    String content,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/snippets/create/'),
        headers: {"Authorization": token, "Content-Type": "application/json"},
        body: json.encode({"shortcut": shortcut, "content": content}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error create snippet: $e");
      return false;
    }
  }

  Future<bool> deleteSnippet(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/snippets/$id/'),
        headers: {"Authorization": token},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error delete snippet: $e");
      return false;
    }
  }

  Future<List<dynamic>> getChatHistory(
    String token,
    String phone,
    int beforeId,
  ) async {
    try {
      final uri = Uri.parse("$baseUrl/api/chat-history/").replace(
        queryParameters: {
          'phone': phone,
          'before_id': beforeId.toString(),
          'limit': '50',
        },
      );

      final response = await http.get(uri, headers: {"Authorization": token});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["messages"] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching chat history: $e");
      return [];
    }
  }
}
