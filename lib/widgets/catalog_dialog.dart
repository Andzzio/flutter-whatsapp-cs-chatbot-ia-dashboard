import 'package:boty_flutter/models/contact.dart';
import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:boty_flutter/screens/scanner_screen.dart';
import 'package:boty_flutter/utils/barcode_scanner_utils.dart';
import 'package:provider/provider.dart';

class CatalogDialog extends StatefulWidget {
  final Contact contact;
  const CatalogDialog({super.key, required this.contact});

  @override
  State<CatalogDialog> createState() => _CatalogDialogState();
}

class _CatalogDialogState extends State<CatalogDialog> {
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
    final products = await _apiService.getProducts(token);
    if (mounted) {
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    }
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (code != null && code.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código detectado. Buscando...'),
            duration: Duration(milliseconds: 500),
          ),
        );
      }

      final parseResult = BarcodeScannerUtils.parse(code);
      final sku = parseResult.sku;

      setState(() {
        _searchController.text = sku;
      });
      _filterProducts(sku);
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

  Future<void> _sendProduct(String retailerId) async {
    Navigator.pop(context); // Cerrar diálogo primero

    // Feedback inmediato
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Enviando producto...")));

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final success = await _apiService.sendProduct(
      chatProvider.apiToken,
      widget.contact.phone,
      retailerId,
    );

    if (!mounted) return;

    if (success) {
      // Forzar sync para ver el mensaje enviado
      chatProvider.refreshContacts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al enviar producto"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendCatalog() async {
    Navigator.pop(context); // Cerrar diálogo

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Enviando catálogo...")));

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final success = await _apiService.sendCatalog(
      chatProvider.apiToken,
      widget.contact.phone,
    );

    if (!mounted) return;

    if (success) {
      chatProvider.refreshContacts();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Catálogo enviado")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al enviar catálogo"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive size: fixed on desktop, percentage on mobile
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isDesktop ? 500 : size.width * 0.9,
        height: isDesktop ? 600 : size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  size: 24,
                  color: Colors.pinkAccent,
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    "Catálogo de Productos",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _sendCatalog(),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text("Enviar", style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar por nombre o ID...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.pinkAccent,
                  ),
                  onPressed: _scanBarcode,
                  tooltip: 'Escanear Código',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _filterProducts,
            ),
            const SizedBox(height: 16),

            // Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No se encontraron productos",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 columnas
                            childAspectRatio: 0.75, // Aspect ratio de tarjeta
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final imageUrl = product['image_url'] ?? "";
                        final name = product['name'] ?? "Producto sin nombre";
                        // Safe Price handling (Backend sends float or string)
                        final rawPrice = product['price'];
                        String priceDisplay = "";
                        if (rawPrice != null) {
                          if (rawPrice is num && rawPrice > 0) {
                            priceDisplay = "S/ ${rawPrice.toStringAsFixed(2)}";
                          } else if (rawPrice is String &&
                              rawPrice.isNotEmpty) {
                            priceDisplay = rawPrice;
                          }
                        }

                        final retailerId = product['retailer_id'] ?? "";

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _sendProduct(retailerId),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Imagen
                                Expanded(
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, progress) {
                                            if (progress == null) return child;
                                            final p =
                                                progress.expectedTotalBytes !=
                                                    null
                                                ? progress.cumulativeBytesLoaded /
                                                      progress
                                                          .expectedTotalBytes!
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
                                                        fontSize: 10,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          },
                                          errorBuilder: (ctx, err, stack) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.image,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                                // Info
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      if (priceDisplay.isNotEmpty)
                                        Text(
                                          priceDisplay,
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      Text(
                                        "ID: $retailerId",
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Hover/Action overlay hint could be added here
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
