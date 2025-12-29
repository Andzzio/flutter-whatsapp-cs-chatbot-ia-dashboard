import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:boty_flutter/providers/order_provider.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:boty_flutter/widgets/product_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderBottomSheet extends StatelessWidget {
  final String contactPhone;

  const OrderBottomSheet({super.key, required this.contactPhone});

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
    final apiService = ApiService();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await orderProvider.submitOrder(
      apiService,
      chatProvider.apiToken,
      contactPhone,
    );

    if (context.mounted) {
      Navigator.pop(context); // Close loading
      if (success) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Pedido creado exitosamente")),
        );
        // Refresh chat
        chatProvider.refreshContacts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al crear pedido"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final cartItems = orderProvider.cartItems;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85, // 85% of screen height
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.receipt, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Text(
                  "Nuevo Pedido",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (cartItems.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.grey),
                    tooltip: "Vaciar Carrito",
                    onPressed: () => orderProvider.clearCart(),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

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
                          "Carrito vacío",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _openProductSelector(context),
                          icon: const Icon(Icons.add),
                          label: const Text("Agregar Productos"),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length + 1,
                    itemBuilder: (context, index) {
                      if (index == cartItems.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: OutlinedButton.icon(
                              onPressed: () => _openProductSelector(context),
                              icon: const Icon(Icons.add),
                              label: const Text("Agregar más productos"),
                            ),
                          ),
                        );
                      }

                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              // Image
                              Container(
                                width: 60,
                                height: 60,
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
                                    ? Icon(Icons.image, color: Colors.grey)
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "S/ ${item.price.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Controls
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 20),
                                    onPressed: () => orderProvider
                                        .updateQuantity(item.retailerId, -1),
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    onPressed: () => orderProvider
                                        .updateQuantity(item.retailerId, 1),
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
            SafeArea(
              child: Container(
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
                        const Text(
                          "Total a Pagar:",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          "S/ ${orderProvider.total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () => _submitOrder(context),
                        child: const Text(
                          "RECEPCIONAR PEDIDO",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
