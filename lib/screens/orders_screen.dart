import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:boty_flutter/screens/proformas_screen.dart'; // Importar pantalla proformas

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

      // Si es 'all', llamamos api sin status especifico PERO filtramos en cliente para no mostrar proformas
      // O idealmente el backend soportaría excluir status.
      // Como no queremos tocar backend de nuevo, filtramos en cliente.

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/orders/?status=$_filterStatus'),
        headers: {'Authorization': chatProvider.apiToken},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        var loadedOrders = List<Map<String, dynamic>>.from(data['orders']);

        // FILTRO CLIENTE: Excluir PROFORMA de la vista principal siempre
        loadedOrders = loadedOrders
            .where((o) => o['status'] != 'PROFORMA')
            .toList();

        setState(() {
          _orders = loadedOrders;
          _isLoading = false;
        });
      } else {
        // ... error handling
        throw Exception('Status: ${response.statusCode}');
      }
    } catch (e) {
      // ... existing error handling
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

  // ... Resto de métodos ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
        actions: [
          // Botón para ir a Proformas
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProformasScreen(),
                ),
              );
            },
            icon: const Icon(Icons.assignment_outlined, color: Colors.purple),
            label: const Text(
              'Proformas',
              style: TextStyle(color: Colors.purple),
            ),
            style: TextButton.styleFrom(backgroundColor: Colors.purple[50]),
          ),
          const SizedBox(width: 8),

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
              const PopupMenuItem(value: 'pending', child: Text('Pendientes')),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completados'),
              ),
              const PopupMenuItem(
                value: 'cancelled',
                child: Text('Cancelados'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(child: Text('No hay pedidos activos'))
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final stockDeducted = order['stock_deducted'] ?? false;
                  final stockReverted = order['stock_reverted'] ?? false;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            order['status'],
                          ).withAlpha(128),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '#${order['id']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(order['contact_name'])),
                          if (stockDeducted && !stockReverted)
                            Tooltip(
                              message: 'Stock Descontado',
                              child: Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                            ),
                          if (stockReverted)
                            Tooltip(
                              message: 'Stock Revertido',
                              child: Icon(
                                Icons.replay_circle_filled,
                                size: 16,
                                color: Colors.orange,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total: S/${order['total_amount'].toStringAsFixed(2)}',
                          ),
                          // Preview of items with sizes
                          if (order['items'] != null)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: (order['items'] as List).map<Widget>((
                                  item,
                                ) {
                                  if (item['size'] != null) {
                                    return _buildSizeBadge(item['size']);
                                  }
                                  return const SizedBox.shrink();
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            order['status'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  _getStatusColor(order['status']) ==
                                      Colors.red[100]
                                  ? Colors.red
                                  : Colors.black54,
                            ),
                          ),
                          Text(
                            _formatDate(
                              order['created_at'],
                            ).split(' ')[0], // Show only date
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      onTap: () => _showOrderDetails(order),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final stockDeducted = order['stock_deducted'] ?? false;
    final stockReverted = order['stock_reverted'] ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text('Pedido #${order['id']}'),
            const Spacer(),
            if (stockDeducted && !stockReverted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'Stock OK',
                  style: TextStyle(fontSize: 10, color: Colors.green),
                ),
              ),
            if (stockReverted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  'Revertido',
                  style: TextStyle(fontSize: 10, color: Colors.orange),
                ),
              ),
          ],
        ),
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
              const Divider(),
              ...List.generate((order['items'] as List).length, (index) {
                final item = order['items'][index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${item['quantity']}x',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['product_name'],
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (item['size'] != null) _buildSizeBadge(item['size']),
                      const SizedBox(width: 8),
                      Text('S/${item['price'] ?? item['unit_price'] ?? 0}'),
                    ],
                  ),
                );
              }),
              const Divider(),
              Text('Subtotal: S/${order['subtotal'].toStringAsFixed(2)}'),
              if (order['shipping_cost'] > 0)
                Text('Envío: S/${order['shipping_cost'].toStringAsFixed(2)}'),
              if (order['discount'] > 0)
                Text('Descuento: -S/${order['discount'].toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text(
                'Total: S/${order['total_amount'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (stockDeducted && order['stock_deducted_at'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Descontado el: ${_formatDate(order['stock_deducted_at'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // Botón Descontar Stock (Si no descontado O revertido)
          if (!stockDeducted || stockReverted)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              icon: const Icon(Icons.inventory, size: 16, color: Colors.white),
              label: const Text(
                'Descontar Stock',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.pop(context);
                _confirmDeductStock(order);
              },
            ),

          // Botón Revertir Stock (Solo si descontado Y no revertido)
          if (stockDeducted && !stockReverted)
            OutlinedButton.icon(
              icon: const Icon(Icons.undo, size: 16),
              label: const Text('Revertir Stock'),
              onPressed: () {
                Navigator.pop(context);
                _confirmRevertStock(order);
              },
            ),

          // Acciones de estado
          if (order['status'] != 'CANCELLED') ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.more_horiz, size: 20),
              ),
              tooltip: 'Acciones',
              onSelected: (value) {
                Navigator.pop(context);
                if (value == 'complete')
                  _updateOrderStatus(order['id'], 'DELIVERED');
                if (value == 'process')
                  _updateOrderStatus(order['id'], 'PROCESSING');
                if (value == 'cancel')
                  _confirmCancelOrder(
                    order['id'],
                  ); // Usar nuevo método con pass
              },
              itemBuilder: (context) => [
                if (order['status'] == 'PENDING')
                  const PopupMenuItem(
                    value: 'process',
                    child: Row(
                      children: [
                        Icon(Icons.work_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Procesar'),
                      ],
                    ),
                  ),
                if (order['status'] != 'COMPLETED' &&
                    order['status'] != 'DELIVERED')
                  const PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Marcar Entregado'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Cancelar Pedido',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
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

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }

  Future<void> _confirmDeductStock(Map<String, dynamic> order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Descuento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Descontar stock de los siguientes productos?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...List.generate((order['items'] as List).length, (index) {
              final item = order['items'][index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${item['quantity']}x ${item['product_name']}'),
              );
            }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange[600]),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar Descuento'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deductStock(order['id']);
    }
  }

  Future<void> _deductStock(int orderId) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Descontando stock...')));

    final result = await ApiService().deductOrderStock(
      chatProvider.apiToken,
      orderId,
    );

    if (mounted) {
      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Stock descontado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PROFORMA':
        return Colors.purple[100]!;
      case 'PENDING':
        return Colors.orange[100]!;
      case 'PROCESSING':
        return Colors.blue[100]!;
      case 'COMPLETED':
      case 'DELIVERED':
        return Colors.green[100]!;
      case 'CANCELLED':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Widget _buildSizeBadge(String? size) {
    if (size == null) return const SizedBox.shrink();

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
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha((25.5).round()), // 0.1 * 255
        border: Border.all(
          color: color.withAlpha((127.5).round()),
        ), // 0.5 * 255
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        size,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(
    int orderId,
    String newStatus, {
    String? password,
  }) async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      final body = {'status': newStatus};
      if (password != null) {
        body['password'] = password;
      }

      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/api/orders/$orderId/status/'),
        headers: {
          'Authorization': chatProvider.apiToken,
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estado actualizado'),
              backgroundColor: Colors.green,
            ),
          );
          _loadOrders();
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Error desconocido');
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

  Future<void> _confirmCancelOrder(int orderId) async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Confirmar Cancelación'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Para cancelar el pedido, ingresa la contraseña de autorización.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cerrar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  if (passwordController.text.isNotEmpty) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Cancelar Pedido'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      await _updateOrderStatus(
        orderId,
        'CANCELLED',
        password: passwordController.text,
      );
    }
  }

  Future<void> _confirmRevertStock(Map<String, dynamic> order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revertir Stock'),
        content: const Text(
          '¿Estás seguro de que deseas revertir el stock de esta orden? ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revertir Stock'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _revertStock(order['id']);
    }
  }

  Future<void> _revertStock(int orderId) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Revirtiendo stock...')));

    final result = await ApiService().revertOrderStock(
      chatProvider.apiToken,
      orderId,
    );

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Stock revertido correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
