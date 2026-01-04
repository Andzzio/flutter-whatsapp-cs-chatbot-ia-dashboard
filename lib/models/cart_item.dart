class CartItem {
  final String retailerId;
  final String name;
  final double price;
  final String imageUrl;
  final String? size; // Talla del producto (S, M, L, XL)
  int quantity;

  CartItem({
    required this.retailerId,
    required this.name,
    required this.price,
    this.imageUrl = "",
    this.size,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'retailer_id': retailerId,
      'id': retailerId,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'quantity': quantity,
      'size': size, // ✅ Incluir talla en el map
    };
  }
}
