import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TicketPdfGenerator {
  /// Genera un PDF en formato ticket 80mm
  /// [product]: Map con los datos del producto (name, retailerId, price)
  /// [size]: Talla seleccionada (S, M, L, XL)
  static Future<Uint8List> generateTicketPdf({
    required Map<String, dynamic> product,
    required String size,
  }) async {
    final pdf = pw.Document();

    final name = product['name'] ?? product['product_name'] ?? 'Producto';
    final sku = product['retailer_id'] ?? 'N/A';
    final price = double.tryParse((product['price'] ?? 0).toString()) ?? 0.0;

    // Determinar sufijo de talla
    String suffix;
    switch (size.toUpperCase()) {
      case 'S':
        suffix = '0S';
        break;
      case 'M':
        suffix = '0M';
        break;
      case 'L':
        suffix = '0L';
        break;
      case 'XL':
        suffix = 'XL';
        break;
      default:
        suffix = '00';
    }

    final encodedSku = '$sku$suffix';

    // Crear el layout
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10), // Margen pequeño para ticket
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                '==================================',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'SHURUMBA',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '----------------------------------',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 10),

              // Información del Producto
              pw.Container(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SKU: $encodedSku',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Descripción: $name',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                '----------------------------------',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 10),

              // Talla
              pw.Text(
                'TALLA: $size',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              pw.SizedBox(height: 10),

              // Precio
              pw.Text(
                'PRECIO: S/${price.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Text(
                '----------------------------------',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 15),

              // Código de Barras (Code 128)
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: encodedSku,
                width: 180,
                height: 60,
                textStyle: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 5),
              pw.Text(encodedSku, style: const pw.TextStyle(fontSize: 10)),

              pw.SizedBox(height: 15),

              pw.Text(
                '==================================',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Abre el diálogo de impresión (o guardar como PDF)
  static Future<void> printTicket({
    required Map<String, dynamic> product,
    required String size,
  }) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        // Ignoramos el formato que viene del driver por defecto y forzamos roll80
        // o generamos nuestro PDF y dejamos que el sistema lo ajuste
        return generateTicketPdf(product: product, size: size);
      },
      name: 'Ticket-${product['retailer_id']}-$size',
    );
  }
}
