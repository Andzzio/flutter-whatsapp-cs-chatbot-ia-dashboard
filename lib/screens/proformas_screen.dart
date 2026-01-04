import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class ProformasScreen extends StatefulWidget {
  const ProformasScreen({super.key});

  @override
  State<ProformasScreen> createState() => _ProformasScreenState();
}

class _ProformasScreenState extends State<ProformasScreen> {
  bool _isLoading = false;
  List<dynamic> _proformas = [];

  @override
  void initState() {
    super.initState();
    _loadProformas();
  }

  Future<void> _loadProformas() async {
    setState(() => _isLoading = true);
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // Consultar orders con status=PROFORMA
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/orders/?status=PROFORMA',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': chatProvider.apiToken},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _proformas = data['orders'] ?? [];
        });
      } else {
        throw Exception('Error cargando proformas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM HH:mm').format(date);
    } catch (e) {
      return '-';
    }
  }

  void _showProformaDetails(Map<String, dynamic> proforma) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Proforma #${proforma['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Text(
                  'Pendiente de Talla',
                  style: TextStyle(fontSize: 12, color: Colors.purple.shade700),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cliente: ${proforma['contact_name']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Teléfono: ${proforma['contact_phone']}'),
              const SizedBox(height: 16),
              const Text(
                'Productos:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ...List.generate((proforma['items'] as List).length, (index) {
                final item = proforma['items'][index];
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
                        child: Text(
                          item['product_name'],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      // En proformas no mostramos size badge porque no tienen
                      const SizedBox(width: 8),
                      Text('S/${item['price'] ?? 0}'),
                    ],
                  ),
                );
              }),
              const Divider(),
              Text(
                'Total Estimado: S/${proforma['total_amount'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          // Aquí podríamos poner botón para "Gestionar/Asignar Talla" en el futuro
          // Por ahora usuario pidió solo verlas.
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proformas'),
        backgroundColor: Colors.purple[100],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _proformas.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay proformas pendientes'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _proformas.length,
              itemBuilder: (context, index) {
                final proforma = _proformas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple[100],
                      child: const Icon(
                        Icons.assignment_outlined,
                        color: Colors.purple,
                      ),
                    ),
                    title: Text(
                      '#${proforma['id']} - ${proforma['contact_name']}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatDate(proforma['created_at'])),
                        Text(
                          'S/${proforma['total_amount'].toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showProformaDetails(proforma),
                  ),
                );
              },
            ),
    );
  }
}
