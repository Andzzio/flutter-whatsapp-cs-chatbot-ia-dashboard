import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filterStatus = 'all';
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/orders/?status=$_filterStatus'),
        headers: {'Authorization': chatProvider.apiToken},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _orders = List<Map<String, dynamic>>.from(data['orders']);
          _isLoading = false;
        });
      } else {
        throw Exception('Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando pedidos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/api/orders/$orderId/status/'),
        headers: {
          'Authorization': chatProvider.apiToken,
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estado actualizado'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
      } else {
        throw Exception('Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pedido #${order['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cliente: ${order['contact_name']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Teléfono: ${order['contact_phone']}'),
              const SizedBox(height: 16),
              const Text(
                'Productos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...List.generate((order['items'] as List).length, (index) {
                final item = order['items'][index];
                return Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    '- ${item['quantity']}x ${item['product_name']} (S/${item['unit_price']})',
                  ),
                );
              }),
              const SizedBox(height: 16),
              Text('Subtotal: S/${order['subtotal'].toStringAsFixed(2)}'),
              if (order['shipping_cost'] > 0)
                Text('Envío: S/${order['shipping_cost'].toStringAsFixed(2)}'),
              if (order['discount'] > 0)
                Text('Descuento: -S/${order['discount'].toStringAsFixed(2)}'),
              const Divider(),
              Text(
                'Total: S/${order['total_amount'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (order['status'] == 'PENDING') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateOrderStatus(order['id'], 'COMPLETED');
              },
              child: const Text('Marcar Completado'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateOrderStatus(order['id'], 'CANCELLED');
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _filterStatus,
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
              _loadOrders();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todos')),
              const PopupMenuItem(value: 'PENDING', child: Text('Pendientes')),
              const PopupMenuItem(
                value: 'COMPLETED',
                child: Text('Completados'),
              ),
              const PopupMenuItem(
                value: 'CANCELLED',
                child: Text('Cancelados'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay pedidos',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final statusColor = order['status'] == 'PENDING'
                      ? Colors.orange
                      : order['status'] == 'COMPLETED'
                      ? Colors.green
                      : Colors.red;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Icon(Icons.receipt, color: statusColor),
                      ),
                      title: Text(
                        'Pedido #${order['id']} - ${order['contact_name']}',
                      ),
                      subtitle: Text(
                        'S/${order['total_amount'].toStringAsFixed(2)} • ${order['items'].length} productos',
                      ),
                      trailing: Chip(
                        label: Text(
                          order['status'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: statusColor,
                      ),
                      onTap: () => _showOrderDetails(order),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
