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
      "retailer_id": retailerId.length > 190
          ? retailerId.substring(0, 190)
          : retailerId,
      "name": name.length > 450 ? name.substring(0, 450) : name,
      "unit_price": price,
      "quantity": quantity,
      "image_url": imageUrl.length > 1900
          ? imageUrl.substring(0, 1900)
          : imageUrl,
    };
  }
}
