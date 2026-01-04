import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:boty_flutter/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductSelector extends StatefulWidget {
  const ProductSelector({super.key});

  @override
  State<ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<ProductSelector> {
  final ApiService _apiService = ApiService();
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProducts();
    });
  }

  Future<void> _fetchProducts() async {
    final token = Provider.of<ChatProvider>(context, listen: false).apiToken;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // Usamos forceRefresh para asegurar stock actualizado al momento de la venta
    final products = await orderProvider.fetchProducts(
      _apiService,
      token,
      forceRefresh: true,
    );

    if (mounted) {
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredProducts = _products.where((p) {
        final name = (p['name'] ?? "").toString().toLowerCase();
        final retailerId = (p['retailer_id'] ?? "").toString().toLowerCase();
        return name.contains(_searchQuery) || retailerId.contains(_searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.add_shopping_cart, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Agregar Producto al Pedido",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar producto...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _filterProducts,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final name = product['name'] ?? "Unknown";
                        final imgUrl = product['image_url'];

                        return ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[200],
                            child: imgUrl != null && imgUrl.isNotEmpty
                                ? Image.network(
                                    imgUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      final p =
                                          progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!
                                          : null;
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value: p,
                                              strokeWidth: 2,
                                            ),
                                            if (p != null)
                                              Text(
                                                "${(p * 100).toInt()}%",
                                                style: const TextStyle(
                                                  fontSize: 8,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Icon(Icons.image),
                                  )
                                : const Icon(Icons.image, color: Colors.grey),
                          ),
                          title: Text(name),
                          subtitle: Text(
                            product['price'] is num
                                ? "S/ ${(product['price'] as num).toStringAsFixed(2)}"
                                : product['price'].toString(),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.blue,
                            ),
                            onPressed: () async {
                              final result = await _showSizeSelector(
                                context,
                                product,
                              );
                              if (result != null) {
                                Navigator.pop(context, result);
                              }
                            },
                          ),
                          onTap: () async {
                            final result = await _showSizeSelector(
                              context,
                              product,
                            );
                            if (result != null) {
                              Navigator.pop(context, result);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showSizeSelector(
    BuildContext context,
    Map<String, dynamic> product,
  ) async {
    String? selectedSize;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            product['name'] ?? 'Producto',
            style: const TextStyle(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'S/ ${(product['price'] as num).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecciona una talla:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSizeButton('S', product, selectedSize, setState, (
                    size,
                  ) {
                    selectedSize = size;
                  }),
                  _buildSizeButton('M', product, selectedSize, setState, (
                    size,
                  ) {
                    selectedSize = size;
                  }),
                  _buildSizeButton('L', product, selectedSize, setState, (
                    size,
                  ) {
                    selectedSize = size;
                  }),
                  _buildSizeButton('XL', product, selectedSize, setState, (
                    size,
                  ) {
                    selectedSize = size;
                  }),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedSize == null
                  ? null
                  : () {
                      Navigator.pop(context, {
                        ...product,
                        'selected_size': selectedSize,
                      });
                    },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeButton(
    String size,
    Map<String, dynamic> product,
    String? selectedSize,
    StateSetter setState,
    Function(String) onTap,
  ) {
    final stockField = 'stock_${size.toLowerCase()}';
    final stock = product[stockField] ?? 0;
    final hasStock = stock > 0;
    final isSelected = selectedSize == size;

    return GestureDetector(
      onTap: hasStock
          ? () {
              setState(() {
                onTap(size);
              });
            }
          : null,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: !hasStock
              ? Colors.grey.shade200
              : isSelected
              ? Colors.blue
              : Colors.white,
          border: Border.all(
            color: !hasStock
                ? Colors.grey.shade400
                : isSelected
                ? Colors.blue
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              size,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: !hasStock
                    ? Colors.grey
                    : isSelected
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$stock',
              style: TextStyle(
                fontSize: 12,
                color: !hasStock
                    ? Colors.grey
                    : isSelected
                    ? Colors.white70
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
