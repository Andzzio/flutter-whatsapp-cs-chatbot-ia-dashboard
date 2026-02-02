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
      final apiService = ApiService();

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
          // 1. Construir texto SHURUMBA Style 👗✨ (VERSION MOBILE SYNC)
          final items = (data['items'] as List).cast<Map<String, dynamic>>();
          final total = data['total'];
          final shipping = data['shipping'];
          final discount = data['discount'];

          StringBuffer buffer = StringBuffer();
          buffer.writeln("✨ *Resumen de tu Pedido - SHURUMBA* ✨");
          buffer.writeln("");
          buffer.writeln("👗 *Tus prendas:*");
          for (var item in items) {
            String itemText = "- ${item['quantity']}x ${item['name']}";
            if (item['size'] != null && item['size'].toString().isNotEmpty) {
              itemText += " (Talla: ${item['size']})";
            }
            // Add unit price or total item price
            if (item['price'] != null) {
              final unitPrice =
                  double.tryParse(item['price'].toString()) ?? 0.0;
              final quantity = int.tryParse(item['quantity'].toString()) ?? 1;
              final lineTotal = unitPrice * quantity;

              itemText += " - S/${lineTotal.toStringAsFixed(2)}";

              if (quantity > 1) {
                itemText += " (S/${unitPrice.toStringAsFixed(2)} c/u)";
              }
            }
            buffer.writeln(itemText);
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
          await chatProvider.sendMessage(contactPhone, buffer.toString());

          // 3. Desactivar el bot automáticamente (Handover) - DESKTOP SYNC
          await chatProvider.toggleBot(contactPhone, false);

          // 4. Feedback y CERRAR DRAWER
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text("¡Pedido enviado correctamente! Bot desactivado."),
              backgroundColor: Colors.green,
            ),
          );
          // Close drawer? Maybe keep it open or empty it? Mobile closes it.
          // Desktop behavior usually keeps context, but let's clear cart at least.
          // The order provider clears cart inside submitOrder typically or we allow clearing.
          // User typically wants to close the 'New Order' mode if done.
          // Navigator.pop(context) in desktop closes the specific drawer if it's pushed?
          // No, in chat_screen it is a sibling widget conditioned by boolean.
          // Navigator.pop() here would pop the SCREEN if not careful because drawer isn't pushed on stack.
          // WAIT. In chat_screen.dart:
          // if (isDesktop) { setState(() { _showDesktopDrawer = !_showDesktopDrawer; }); }
          // The Drawer is IN THE TREE, not pushed.
          // So Navigator.pop() will close the ChatScreen! BAD.

          // FIX: We need a way to close the drawer or just clear state.
          // Since it's a StatelessWidget, we can't setState `_showDesktopDrawer`.
          // But we can just Clear Cart and maybe show success.
          // Or we use a callback? OrderDrawer doesn't have a callback.
          // Let's just Clear Cart (done by provider usually) and refresh contacts.

          chatProvider.refreshContacts();
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error en _submitOrder: $e");
      debugPrint("StackTrace: $stackTrace");

      if (context.mounted) {
        try {
          Navigator.of(context).pop(); // Close loading
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

  Widget _buildSizeBadge(String size) {
    Color color;
    switch (size.toUpperCase()) {
      case 'S':
        color = Colors.blue;
        break;
      case 'M':
        color = Colors.green;
        break;
      case 'L':
        color = Colors.orange;
        break;
      case 'XL':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "Talla: $size",
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
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
                          label: const Text("Agregar Productos"),
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
                            label: const Text("Agregar más productos"),
                          ),
                        );
                      }

                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              // Image
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                  image: item.imageUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(item.imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: item.imageUrl.isEmpty
                                    ? const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (item.size != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: _buildSizeBadge(item.size!),
                                      ),
                                    Text(
                                      "S/ ${item.price.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Controls
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        orderProvider.updateQuantity(
                                          item.retailerId,
                                          -1,
                                          size: item.size,
                                        ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      "${item.quantity}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        orderProvider.updateQuantity(
                                          item.retailerId,
                                          1,
                                          size: item.size,
                                        ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
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
