import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:boty_flutter/providers/order_provider.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:boty_flutter/widgets/product_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderDrawer extends StatelessWidget {
  final String contactPhone;

  const OrderDrawer({super.key, required this.contactPhone});

  Future<void> _openProductSelector(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => const ProductSelector(),
    );

    if (result != null && context.mounted) {
      Provider.of<OrderProvider>(context, listen: false).addToCart(result);
    }
  }

  Future<void> _submitOrder(BuildContext context) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final apiService = Provider.of<ApiService>(
      context,
      listen: false,
    ); // Fix ApiService provider usage

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await orderProvider.submitOrder(
      apiService,
      chatProvider.apiToken,
      contactPhone,
    );

    if (context.mounted) {
      Navigator.pop(context); // Close loading

      if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${result.error}"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = result.data;
      if (data != null) {
        // 1. Construir texto SHURUMBA Style 👗✨
        final items = (data['items'] as List).cast<Map<String, dynamic>>();
        final total = data['total'];
        final shipping = data['shipping'];
        final discount = data['discount'];

        StringBuffer buffer = StringBuffer();
        buffer.writeln("✨ *Resumen de tu Pedido - SHURUMBA* ✨");
        buffer.writeln("");
        buffer.writeln("👗 *Tus prendas:*");
        for (var item in items) {
          buffer.writeln("- ${item['quantity']}x ${item['name']}");
        }
        buffer.writeln("");

        if (shipping > 0) {
          buffer.writeln("🚚 *Envío:* S/${shipping.toStringAsFixed(2)}");
        }
        if (discount > 0) {
          buffer.writeln("🏷️ *Descuento:* -S/${discount.toStringAsFixed(2)}");
        }

        buffer.writeln("-------------------------");
        buffer.writeln("💰 *TOTAL A PAGAR: S/${total.toStringAsFixed(2)}*");
        buffer.writeln("");
        buffer.writeln("¡Gracias por elegirnos! 💖");

        // 2. Enviar mensaje como el bot
        chatProvider.sendMessage(contactPhone, buffer.toString());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Pedido creado y enviado")),
        );

        // Refresh chat
        chatProvider.refreshContacts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final cartItems = orderProvider.cartItems;

    return Container(
      width: 400,
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueAccent.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Text(
                  "Nuevo Pedido",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (cartItems.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.grey),
                    tooltip: "Vaciar Carrito",
                    onPressed: () => orderProvider.clearCart(),
                  ),
              ],
            ),
          ),

          // List
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_shopping_cart,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "El carrito está vacío",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openProductSelector(context),
                          icon: const Icon(Icons.add),
                          label: const Text("Agregar Producto"),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: cartItems.length + 1, // +1 for Add Button
                    itemBuilder: (context, index) {
                      if (index == cartItems.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: OutlinedButton.icon(
                            onPressed: () => _openProductSelector(context),
                            icon: const Icon(Icons.add),
                            label: const Text("Agregar otro producto"),
                          ),
                        );
                      }

                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: SizedBox(
                            width: 40,
                            height: 40,
                            child: item.imageUrl.isNotEmpty
                                ? Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(Icons.image),
                                  )
                                : const Icon(Icons.image),
                          ),
                          title: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            "S/ ${item.price.toStringAsFixed(2)} x ${item.quantity}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                ),
                                onPressed: () => orderProvider.updateQuantity(
                                  item.retailerId,
                                  -1,
                                ),
                              ),
                              Text("${item.quantity}"),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 20,
                                ),
                                onPressed: () => orderProvider.updateQuantity(
                                  item.retailerId,
                                  1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Total & Actions
          if (cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total:", style: TextStyle(fontSize: 18)),
                      Text(
                        "S/ ${orderProvider.total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _submitOrder(context),
                      child: const Text(
                        "RECEPCIONAR PEDIDO",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
