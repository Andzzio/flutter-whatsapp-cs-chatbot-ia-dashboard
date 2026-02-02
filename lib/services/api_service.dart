import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/contact.dart';
import '../models/snippet.dart';

class ApiService {
  // static const String baseUrl = "https://django-whatsapp-cs-chatbot-ia-backend.onrender.com";
  // static const String baseUrl = "http://192.168.1.48:8000"; // SOLO PARA CASA 🏠
  // IP Pública / Túnel (Ngrok) - PARA APK EMPRESARIAL 🌍
  static const String baseUrl =
      "https://cloistral-forcedly-elianna.ngrok-free.dev";

  Future<List<Contact>> syncContacts(
    String token, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (token.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/sync/?limit=$limit&offset=$offset"),
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
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
        headers: {
          "Authorization": token,
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
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
        headers: {
          "Authorization": token,
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
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
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
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
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
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
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
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
        headers: {
          "Authorization": token,
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
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
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error deletting message: $e");
      return false;
    }
  }

  Future<bool> resetMemory(String token, String phone) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/contacts/$phone/reset-memory/"),
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error resetting memory: $e");
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
        "items": items.map((i) => i.toMap()).toList(),
        "shipping_cost": shippingCost,
      };

      final response = await http.post(
        Uri.parse("$baseUrl/api/contacts/$phone/create-order/"),
        headers: {
          "Authorization": token,
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
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
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
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
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
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
        headers: {
          "Authorization": token,
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
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
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
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

      final response = await http.get(
        uri,
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
      );

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

  // --- ANALYTICS V3 ---
  Future<Map<String, dynamic>> getAnalyticsStats(
    String token,
    String period,
  ) async {
    try {
      final uri = Uri.parse(
        "$baseUrl/api/analytics/stats/",
      ).replace(queryParameters: {'period': period});

      final response = await http.get(
        uri,
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint("Error fetching analytics stats: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> getAnalyticsTrends(
    String token,
    String period,
    String metric,
  ) async {
    try {
      final uri = Uri.parse(
        "$baseUrl/api/analytics/trends/",
      ).replace(queryParameters: {'period': period, 'metric': metric});

      final response = await http.get(
        uri,
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint("Error fetching analytics trends: $e");
      return {};
    }
  }

  // --- STOCK MANAGEMENT ---
  Future<bool> updateProductStock(
    String token,
    String retailerId,
    Map<String, int> stocks, {
    bool? isAvailable,
  }) async {
    try {
      final body = {
        "retailer_id": retailerId,
        "stock_s": stocks['S'] ?? 0,
        "stock_m": stocks['M'] ?? 0,
        "stock_l": stocks['L'] ?? 0,
        "stock_xl": stocks['XL'] ?? 0,
        if (isAvailable != null) "is_available": isAvailable,
      };

      final response = await http.post(
        Uri.parse("$baseUrl/api/products/stock/"),
        headers: {
          "Authorization": token,
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        debugPrint("Stock updated successfully for $retailerId");
        return true;
      } else {
        debugPrint(
          "Error updating stock: ${response.statusCode} - ${response.body}",
        );
        return false;
      }
    } catch (e) {
      debugPrint("Error updating stock: $e");
      return false;
    }
  }

  Future<({bool success, String? error})> revertOrderStock(
    String token,
    int orderId,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/orders/$orderId/revert-stock/"),
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
      );

      if (response.statusCode == 200) {
        return (success: true, error: null);
      } else {
        try {
          final body = json.decode(response.body);
          return (
            success: false,
            error: body['error']?.toString() ?? "Error desconocido",
          );
        } catch (_) {
          return (success: false, error: "Error ${response.statusCode}");
        }
      }
    } catch (e) {
      return (success: false, error: "Error de conexión: $e");
    }
  }

  // --- ORDERS STOCK DEDUCTION ---
  Future<Map<String, dynamic>> deductOrderStock(
    String token,
    int orderId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/orders/$orderId/deduct-stock/"),
        headers: {
          "Authorization": token,
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        return {"error": error["error"] ?? "Error desconocido"};
      }
    } catch (e) {
      debugPrint("Error deducting stock: $e");
      return {"error": e.toString()};
    }
  }

  // --- EXCEL IMPORT/EXPORT ---
  Future<List<int>?> downloadProductsExcel(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/products/export/excel/"),
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint("Error downloading Excel: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error downloading Excel: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> uploadProductsExcel(
    String token,
    String filePath,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/api/products/import/excel/"),
      );
      request.headers["Authorization"] = token;
      request.headers["ngrok-skip-browser-warning"] = "true";
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        final error = json.decode(responseData);
        return {"error": error["error"] ?? "Error ${response.statusCode}"};
      }
    } catch (e) {
      debugPrint("Error uploading Excel: $e");
      return {"error": e.toString()};
    }
  }

  // --- GENERIC HTTP METHODS (For new features like Notifications) ---
  Future<dynamic> cancelableRequest(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    // Simplified: Just a GET request for now
    try {
      //final uri = Uri.parse(
      //"$baseUrl/$endpoint",
      //).replace(queryParameters: params);
      // We assume a default token or pass it.
      // Ideally, specific methods should pass headers.
      // For this refactor, we'll hardcode a "GET" wrapper that requires a token to be passed
      // but since we need it generic, let's look at how providers use it.
      // Provider passes 'api/notifications/'. We need the token.
      // Since ApiService is stateless static, providers should manage token.
      // But here we are adding instance methods without a visible token.
      // FIX: Updates below.
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> get(String endpoint, String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/$endpoint"),
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> patch(
    String endpoint,
    String token,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/$endpoint"),
        headers: {
          "Authorization": token,
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: json.encode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<dynamic> delete(String endpoint, String token) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/$endpoint"),
        headers: {"Authorization": token, "ngrok-skip-browser-warning": "true"},
      );
      return response.statusCode == 200; // or 204
    } catch (e) {
      return false;
    }
  }
}
