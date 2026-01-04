import 'package:boty_flutter/models/cart_item.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:flutter/material.dart';

class OrderProvider extends ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  double _shippingCost = 10.0;
  double get shippingCost => _shippingCost;

  // Product Cache
  List<dynamic> _productCache = [];
  List<dynamic> get productCache => _productCache;

  void setShippingCost(double cost) {
    _shippingCost = cost;
    notifyListeners();
  }

  Future<List<dynamic>> fetchProducts(
    ApiService apiService,
    String token, {
    bool forceRefresh = false,
  }) async {
    if (_productCache.isNotEmpty && !forceRefresh) {
      return _productCache;
    }

    try {
      final products = await apiService.getProducts(token);
      if (products.isNotEmpty) {
        _productCache = products;
        notifyListeners();
      }
      return products;
    } catch (e) {
      debugPrint("Error fetching products in provider: $e");
      return [];
    }
  }

  double get subtotal => _cartItems.fold(0, (sum, item) => sum + item.total);

  double get total => subtotal + _shippingCost;

  void addToCart(dynamic productMap) {
    final retailerId = productMap['retailer_id'] ?? "";
    final name = productMap['name'] ?? "Unknown";
    final imageUrl = productMap['image_url'] ?? "";
    final size = productMap['selected_size']; // ✅ Capturar talla

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

    // Buscar si ya existe el mismo producto CON LA MISMA TALLA
    final index = _cartItems.indexWhere(
      (i) => i.retailerId == retailerId && i.size == size,
    );

    if (index != -1) {
      // Ya existe con esa talla, incrementar cantidad
      _cartItems[index].quantity++;
    } else {
      // Agregar nuevo item con talla
      _cartItems.add(
        CartItem(
          retailerId: retailerId,
          name: name,
          price: price,
          imageUrl: imageUrl,
          size: size, // ✅ Guardar talla
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

  Future<({Map<String, dynamic>? data, String? error})> submitOrder(
    ApiService apiService,
    String token,
    String phone,
  ) async {
    if (_cartItems.isEmpty) return (data: null, error: "Carrito vacío");

    try {
      final result = await apiService.createOrder(
        token,
        phone,
        _cartItems,
        shippingCost: _shippingCost,
      );

      if (result.error == null && result.data != null) {
        clearCart();
        return (data: result.data, error: null); // Success
      }
      return (data: null, error: result.error ?? "Error desconocido");
    } catch (e) {
      debugPrint("Order submit error: $e");
      return (data: null, error: "Excepción interna: $e");
    }
  }
}
