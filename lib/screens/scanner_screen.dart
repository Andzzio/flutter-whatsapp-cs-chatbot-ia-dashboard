import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart'; // For HapticFeedback

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
    // formats: const [BarcodeFormat.all], // Default is all
    // High resolution for better detail on dense timestamps
    cameraResolution: const Size(1280, 720),
    autoStart: false,
  );

  late AnimationController _animationController;
  bool _isScanned = false; // Prevent double scans
  bool _isSuccess = false; // Visual success state
  String _statusText = "Iniciando cámara...";
  double _zoomFactor = 0.0; // 0.0 to 1.0 (internal slider value)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Laser Animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Slight delay to avoid graphic buffer collision on startup
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        controller.start();
        setState(() {
          _statusText = "Buscando código...";
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        controller.start();
        break;
      case AppLifecycleState.inactive:
        controller.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  // Calculate scan window based on screen size (3:1 ratio)
  Rect _getScanWindow(Size screenSize) {
    final double cutWidth = screenSize.width * 0.90;
    final double cutHeight = cutWidth / 3;
    return Rect.fromCenter(
      center: screenSize.center(Offset.zero),
      width: cutWidth,
      height: cutHeight,
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      debugPrint("Scan Candidate: ${barcode.rawValue}"); // Feedback in logs

      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        _isScanned = true;

        // Visual Success Feedback
        setState(() {
          _isSuccess = true;
          _statusText = "¡CÓDIGO DETECTADO!";
        });

        HapticFeedback.heavyImpact();

        // Delay pop to show green box
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            Navigator.of(context).pop(barcode.rawValue);
          }
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for scan window calculation
    final Size screenSize = MediaQuery.of(context).size;
    final Rect scanWindow = _getScanWindow(screenSize);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Escanear Código',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black26, // Semi-transparent
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.auto:
                  case TorchState.unavailable:
                    return const Icon(Icons.no_flash, color: Colors.grey);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                  default:
                    return const Icon(Icons.camera_alt);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Mobile Scanner View
          MobileScanner(
            controller: controller,
            // scanWindow: scanWindow, // DISABLE WINDOW to ensure full screen detection
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      'Error de cámara: ${error.errorCode}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),

          // 2. Custom Dark Overlay with Animation
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                size: screenSize,
                painter: BarcodeOverlayPainter(
                  scanWindow: scanWindow,
                  animValue: _animationController.value,
                  isSuccess: _isSuccess,
                ),
              );
            },
          ),

          // 3. Zoom Slider (Bottom)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text(
                  "Zoom",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: _zoomFactor,
                  onChanged: (value) {
                    setState(() {
                      _zoomFactor = value;
                      controller.setZoomScale(
                        value,
                      ); // 0.0 to 1.0 maps to min/max zoom
                    });
                  },
                ),
              ],
            ),
          ),

          // 4. Status Text
          Positioned(
            top: 100,
            width: screenSize.width,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green : Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BarcodeOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double animValue; // 0.0 to 1.0 (used for laser position)
  final bool isSuccess;

  BarcodeOverlayPainter({
    required this.scanWindow,
    required this.animValue,
    this.isSuccess = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Darken Background (70% opacity for high contrast focus)
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.7);
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final backgroundPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(screenRect),
      Path()..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)),
      ),
    );
    canvas.drawPath(backgroundPath, backgroundPaint);

    // 2. Draw Visual Indicators
    if (isSuccess) {
      // SUCCESS STATE: Full Green Box
      final successPaint = Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;

      canvas.drawRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)),
        successPaint,
      );
    } else {
      // SCANNING STATE: Professional "Corners" (Yape/Passport style)
      final cornerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;

      final double cornerLength = 40.0;
      final double r = 16.0; // Radius matching the hole

      // Top Left
      final pathTL = Path()
        ..moveTo(scanWindow.left, scanWindow.top + cornerLength)
        ..lineTo(scanWindow.left, scanWindow.top + r)
        ..quadraticBezierTo(
          scanWindow.left,
          scanWindow.top,
          scanWindow.left + r,
          scanWindow.top,
        )
        ..lineTo(scanWindow.left + cornerLength, scanWindow.top);
      canvas.drawPath(pathTL, cornerPaint);

      // Top Right
      final pathTR = Path()
        ..moveTo(scanWindow.right - cornerLength, scanWindow.top)
        ..lineTo(scanWindow.right - r, scanWindow.top)
        ..quadraticBezierTo(
          scanWindow.right,
          scanWindow.top,
          scanWindow.right,
          scanWindow.top + r,
        )
        ..lineTo(scanWindow.right, scanWindow.top + cornerLength);
      canvas.drawPath(pathTR, cornerPaint);

      // Bottom Right
      final pathBR = Path()
        ..moveTo(scanWindow.right, scanWindow.bottom - cornerLength)
        ..lineTo(scanWindow.right, scanWindow.bottom - r)
        ..quadraticBezierTo(
          scanWindow.right,
          scanWindow.bottom,
          scanWindow.right - r,
          scanWindow.bottom,
        )
        ..lineTo(scanWindow.right - cornerLength, scanWindow.bottom);
      canvas.drawPath(pathBR, cornerPaint);

      // Bottom Left
      final pathBL = Path()
        ..moveTo(scanWindow.left + cornerLength, scanWindow.bottom)
        ..lineTo(scanWindow.left + r, scanWindow.bottom)
        ..quadraticBezierTo(
          scanWindow.left,
          scanWindow.bottom,
          scanWindow.left,
          scanWindow.bottom - r,
        )
        ..lineTo(scanWindow.left, scanWindow.bottom - cornerLength);
      canvas.drawPath(pathBL, cornerPaint);

      // 3. Draw Laser Line (Gradient Fade for "High Tech" feel)
      final laserPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader =
            LinearGradient(
              colors: [
                Colors.redAccent.withOpacity(0.0),
                Colors.redAccent.withOpacity(0.8),
                Colors.redAccent.withOpacity(0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(
              Rect.fromLTWH(
                scanWindow.left,
                scanWindow.top,
                scanWindow.width,
                scanWindow.height,
              ),
            );

      // Calculate Y position based on animation value
      final double yPos = scanWindow.top + (scanWindow.height * animValue);

      // Draw a "glow" rect as the laser line
      canvas.drawRect(
        Rect.fromLTWH(scanWindow.left + 10, yPos - 2, scanWindow.width - 20, 4),
        laserPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BarcodeOverlayPainter oldDelegate) {
    return oldDelegate.animValue != animValue ||
        oldDelegate.isSuccess != isSuccess;
  }
}
