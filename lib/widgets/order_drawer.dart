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
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final apiService = ApiService(); // FIX: Direct instantiation like mobile

      // Guardar referencia antes del await
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

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
        navigator.pop(); // Close loading

        if (result.error != null) {
          scaffoldMessenger.showSnackBar(
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
            buffer.writeln(
              "🏷️ *Descuento:* -S/${discount.toStringAsFixed(2)}",
            );
          }

          buffer.writeln("-------------------------");
          buffer.writeln("💰 *TOTAL A PAGAR: S/${total.toStringAsFixed(2)}*");
          buffer.writeln("");
          buffer.writeln("¡Gracias por elegirnos! 💖");

          // 2. Enviar mensaje como el bot
          chatProvider.sendMessage(contactPhone, buffer.toString());

          // 3. Feedback y CERRAR DRAWER (FIX #3)
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text("¡Pedido enviado correctamente!"),
              backgroundColor: Colors.green,
            ),
          );
          navigator.pop(); // FIX: Close drawer after submit
          chatProvider.refreshContacts();
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error en _submitOrder: $e");
      debugPrint("StackTrace: $stackTrace");

      if (context.mounted) {
        try {
          Navigator.of(context).pop(); // Close loading if open
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error inesperado: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
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
                  // FIX: Add Shipping Cost Input (like mobile)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Envío:",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          initialValue: orderProvider.shippingCost
                              .toStringAsFixed(2),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                          decoration: const InputDecoration(
                            prefixText: "S/ ",
                            isDense: true,
                            border: UnderlineInputBorder(),
                          ),
                          onChanged: (value) {
                            final val = double.tryParse(value);
                            if (val != null) {
                              orderProvider.setShippingCost(val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total a Pagar:",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        "S/ ${orderProvider.total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _submitOrder(context),
                      child: const Text("Enviar Pedido"),
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
