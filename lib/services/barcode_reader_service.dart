import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:camera/camera.dart';

class BarcodeReaderService {
  /// Lee un código de barras desde un archivo de imagen (JPG, PNG).
  /// Retorna el texto del código o null si no se detecta.
  static Future<String?> readBarcodeFromFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;

      final xfile = XFile(path);
      debugPrint('Scanning File with flutter_zxing: $path');

      // Enable aggressive decoding options
      final params = DecodeParams(
        tryHarder: true,
        tryRotate: true,
        tryInverted: true,
        format: Format.code128, // Specific format if desired, or Format.any
      );

      final Code result = await zx.readBarcodeImagePath(xfile, params);

      if (result.isValid && result.text != null) {
        return result.text;
      }
      return null;
    } catch (e) {
      debugPrint('Error scanning file: $e');
      return null;
    }
  }
}
