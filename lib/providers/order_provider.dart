import 'package:boty_flutter/models/cart_item.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:flutter/material.dart';

class OrderProvider extends ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  double get subtotal => _cartItems.fold(0, (sum, item) => sum + item.total);

  // Could add delivery costs logic later
  double get total => subtotal;

  void addToCart(dynamic productMap) {
    final retailerId = productMap['retailer_id'] ?? "";
    final name = productMap['name'] ?? "Unknown";
    final imageUrl = productMap['image_url'] ?? "";

    // Parse price safely
    double price = 0.0;
    try {
      final p = productMap['price'];
      if (p is num) {
        price = p.toDouble();
      } else if (p is String) {
        // Handle "S/ 40.00"
        final clean = p.replaceAll("S/", "").replaceAll(",", ".").trim();
        price = double.tryParse(clean) ?? 0.0;
      }
    } catch (e) {
      debugPrint("Error parsing price: $e");
    }

    // Check if exists logic
    final index = _cartItems.indexWhere((i) => i.retailerId == retailerId);
    if (index != -1) {
      _cartItems[index].quantity++;
    } else {
      _cartItems.add(
        CartItem(
          retailerId: retailerId,
          name: name,
          price: price,
          imageUrl: imageUrl,
        ),
      );
    }
    notifyListeners();
  }

  void removeFromCart(String retailerId) {
    _cartItems.removeWhere((i) => i.retailerId == retailerId);
    notifyListeners();
  }

  void updateQuantity(String retailerId, int delta) {
    final index = _cartItems.indexWhere((i) => i.retailerId == retailerId);
    if (index != -1) {
      final newQty = _cartItems[index].quantity + delta;
      if (newQty > 0) {
        _cartItems[index].quantity = newQty;
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<bool> submitOrder(
    ApiService apiService,
    String token,
    String phone,
  ) async {
    if (_cartItems.isEmpty) return false;

    try {
      final success = await apiService.createOrder(token, phone, _cartItems);
      if (success) {
        clearCart();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Order submit error: $e");
      return false;
    }
  }
}
