class CartItem {
  final String retailerId;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.retailerId,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      "retailer_id": retailerId,
      "name": name,
      "unit_price": price,
      "quantity": quantity,
      "image_url": imageUrl,
    };
  }
}
