class BarcodeParseResult {
  final String sku;
  final String? size;

  BarcodeParseResult({required this.sku, this.size});
}

class BarcodeScannerUtils {
  static BarcodeParseResult parse(String input) {
    if (input.isEmpty) return BarcodeParseResult(sku: '');

    // Normalize
    final code = input.trim().toUpperCase();

    // Check last 2 chars
    if (code.length > 2) {
      final last2 = code.substring(code.length - 2);
      final prefix = code.substring(0, code.length - 2);

      if (last2 == '0S') {
        return BarcodeParseResult(sku: prefix, size: 'S');
      } else if (last2 == '0M') {
        return BarcodeParseResult(sku: prefix, size: 'M');
      } else if (last2 == '0L') {
        return BarcodeParseResult(sku: prefix, size: 'L');
      } else if (last2 == '00') {
        return BarcodeParseResult(sku: prefix, size: null); // Mother
      } else if (last2 == 'XL') {
        return BarcodeParseResult(sku: prefix, size: 'XL');
      }
    }

    // Default: No suffix recognized, treat whole input as SKU
    return BarcodeParseResult(sku: code, size: null);
  }
}
