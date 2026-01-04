import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/products/'),
        headers: {'Authorization': chatProvider.apiToken},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final productsList = data is List ? data : (data['products'] ?? data);
        setState(() {
          _products = List<Map<String, dynamic>>.from(productsList);
          _isLoading = false;
        });
      } else {
        throw Exception('Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando productos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((p) {
      final name = (p['name'] ?? p['product_name'] ?? '')
          .toString()
          .toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _showStockDialog(Map<String, dynamic> product) async {
    final controllerS = TextEditingController(
      text: product['stock_s']?.toString() ?? '0',
    );
    final controllerM = TextEditingController(
      text: product['stock_m']?.toString() ?? '0',
    );
    final controllerL = TextEditingController(
      text: product['stock_l']?.toString() ?? '0',
    );
    final controllerXL = TextEditingController(
      text: product['stock_xl']?.toString() ?? '0',
    );
    bool isAvailable = product['is_available'] ?? true;
    final imageUrl = product['image_url'] ?? '';
    final name = product['name'] ?? product['product_name'] ?? '';
    final retailerId = product['retailer_id'] ?? '';
    final price = double.tryParse((product['price'] ?? 0).toString()) ?? 0.0;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Imagen del producto como carta
                if (imageUrl.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDialogImagePlaceholder(),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      color: Colors.grey[100],
                    ),
                    child: _buildDialogImagePlaceholder(),
                  ),

                // Contenido del diálogo
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre completo del producto
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: $retailerId',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'S/${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Título de stocks
                      Text(
                        'Stock por talla',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stock S
                      _buildStockField('Talla S', controllerS),
                      const SizedBox(height: 12),

                      // Stock M
                      _buildStockField('Talla M', controllerM),
                      const SizedBox(height: 12),

                      // Stock L
                      _buildStockField('Talla L', controllerL),
                      const SizedBox(height: 12),

                      // Stock XL
                      _buildStockField('Talla XL', controllerXL),
                      const SizedBox(height: 20),

                      // Switch disponibilidad
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Producto disponible',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAvailable
                                        ? 'Visible en catálogo'
                                        : 'Oculto del catálogo',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isAvailable,
                              onChanged: (value) =>
                                  setState(() => isAvailable = value),
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'stock_s': int.tryParse(controllerS.text) ?? 0,
                  'stock_m': int.tryParse(controllerM.text) ?? 0,
                  'stock_l': int.tryParse(controllerL.text) ?? 0,
                  'stock_xl': int.tryParse(controllerXL.text) ?? 0,
                  'is_available': isAvailable,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _updateStock(product, result);
    }

    controllerS.dispose();
    controllerM.dispose();
    controllerL.dispose();
    controllerXL.dispose();
  }

  Widget _buildStockField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildDialogImagePlaceholder() {
    return Center(
      child: Icon(Icons.image_outlined, size: 80, color: Colors.grey[300]),
    );
  }

  Future<void> _updateStock(
    Map<String, dynamic> product,
    Map<String, dynamic> updates,
  ) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Actualizando...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/products/stock/'),
        headers: {
          'Authorization': chatProvider.apiToken,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'retailer_id': product['retailer_id'],
          'stock_s': updates['stock_s'] ?? 0,
          'stock_m': updates['stock_m'] ?? 0,
          'stock_l': updates['stock_l'] ?? 0,
          'stock_xl': updates['stock_xl'] ?? 0,
          'is_available': updates['is_available'],
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock actualizado'),
              backgroundColor: Colors.green,
            ),
          );
          _loadProducts();
        }
      } else {
        if (mounted) {
          final errorBody = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${errorBody['error'] ?? response.statusCode}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // === EXCEL IMPORT/EXPORT (Compatible Mobile/Desktop) ===
  Future<void> _exportExcel() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Generando Excel...')));

    final bytes = await _apiService.downloadProductsExcel(
      chatProvider.apiToken,
    );

    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al generar Excel'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final dir = Platform.isAndroid || Platform.isIOS
          ? await getTemporaryDirectory()
          : await getApplicationDocumentsDirectory();

      final file = File('${dir.path}/inventario.xlsx');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Excel guardado:\n${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving Excel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null || result.files.single.path == null) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Importando productos...')));

    final response = await _apiService.uploadProductsExcel(
      chatProvider.apiToken,
      result.files.single.path!,
    );

    if (mounted) {
      if (response.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${response['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        final updated = response['updated'] ?? 0;
        final totalErrors = response['total_errors'] ?? 0;

        String message = '✅ $updated productos actualizados';
        if (totalErrors > 0) {
          message += '\n⚠️ $totalErrors errores';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: totalErrors == 0 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );

        _loadProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Productos',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportExcel,
            tooltip: 'Exportar Excel',
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _importExcel,
            tooltip: 'Importar Excel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar estilo Apple
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Buscar',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[400],
                  size: 22,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Products list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? _buildEmptyState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 800;
                      return isDesktop
                          ? _buildDesktopList()
                          : _buildMobileList();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No hay productos' : 'Sin resultados',
            style: TextStyle(fontSize: 17, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 60),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Text(
                  'PRODUCTO',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'SKU',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'PRECIO',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  'S',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  'M',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  'L',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  'XL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  'ESTADO',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 60),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ..._filteredProducts.map((product) => _buildDesktopProductRow(product)),
      ],
    );
  }

  Widget _buildDesktopProductRow(Map<String, dynamic> product) {
    final stockS = product['stock_s'] ?? 0;
    final stockM = product['stock_m'] ?? 0;
    final stockL = product['stock_l'] ?? 0;
    final stockXL = product['stock_xl'] ?? 0;
    final totalStock = stockS + stockM + stockL + stockXL;
    final isAvailable = product['is_available'] ?? true;
    final imageUrl = product['image_url'] ?? '';
    final name = product['name'] ?? product['product_name'] ?? '';
    final retailerId = product['retailer_id'] ?? '';
    final price = double.tryParse((product['price'] ?? 0).toString()) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStockDialog(product),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Imagen
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(60),
                        )
                      : _buildImagePlaceholder(60),
                ),
                const SizedBox(width: 16),

                // Nombre
                Expanded(
                  flex: 3,
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // SKU
                SizedBox(
                  width: 100,
                  child: Text(
                    retailerId,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Precio
                SizedBox(
                  width: 100,
                  child: Text(
                    'S/${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Stock S
                SizedBox(
                  width: 70,
                  child: Center(child: _StockBadge(stock: stockS)),
                ),

                // Stock M
                SizedBox(
                  width: 70,
                  child: Center(child: _StockBadge(stock: stockM)),
                ),

                // Stock L
                SizedBox(
                  width: 70,
                  child: Center(child: _StockBadge(stock: stockL)),
                ),

                // Stock XL
                SizedBox(
                  width: 70,
                  child: Center(child: _StockBadge(stock: stockXL)),
                ),

                // Estado
                SizedBox(
                  width: 120,
                  child: _StatusChip(
                    isAvailable: isAvailable,
                    stock: totalStock,
                  ),
                ),

                // Botón editar
                SizedBox(
                  width: 60,
                  child: IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => _showStockDialog(product),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildMobileProductCard(product);
      },
    );
  }

  Widget _buildMobileProductCard(Map<String, dynamic> product) {
    final stockS = product['stock_s'] ?? 0;
    final stockM = product['stock_m'] ?? 0;
    final stockL = product['stock_l'] ?? 0;
    final stockXL = product['stock_xl'] ?? 0;
    final totalStock = stockS + stockM + stockL + stockXL;
    final isAvailable = product['is_available'] ?? true;
    final imageUrl = product['image_url'] ?? '';
    final name = product['name'] ?? product['product_name'] ?? '';
    final retailerId = product['retailer_id'] ?? '';
    final price = double.tryParse((product['price'] ?? 0).toString()) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showStockDialog(product),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Imagen
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildImagePlaceholder(70),
                            )
                          : _buildImagePlaceholder(70),
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU: $retailerId',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'S/${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Estado
                    _StatusChip(isAvailable: isAvailable, stock: totalStock),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Stocks por talla
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSizeStock('S', stockS),
                    _buildSizeStock('M', stockM),
                    _buildSizeStock('L', stockL),
                    _buildSizeStock('XL', stockXL),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeStock(String size, int stock) {
    return Column(
      children: [
        Text(
          size,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: stock > 0 ? Colors.green : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$stock',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: stock > 0 ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey[300],
        size: size * 0.4,
      ),
    );
  }
}

// Chip de Estado minimalista
class _StatusChip extends StatelessWidget {
  final bool isAvailable;
  final int stock;

  const _StatusChip({required this.isAvailable, required this.stock});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable
        ? (stock < 5 ? Colors.orange[600]! : Colors.green[600]!)
        : Colors.red[600]!;

    final text = isAvailable
        ? (stock < 5 ? 'Stock Bajo' : 'Disponible')
        : 'Agotado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// Badge de Stock minimalista
class _StockBadge extends StatelessWidget {
  final int stock;

  const _StockBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    final color = stock == 0
        ? Colors.red[600]!
        : (stock < 5 ? Colors.orange[600]! : Colors.grey[700]!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        stock.toString(),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
