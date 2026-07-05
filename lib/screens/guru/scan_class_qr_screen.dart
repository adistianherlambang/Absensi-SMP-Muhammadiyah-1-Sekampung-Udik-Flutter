import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/qr_service.dart';
import '../../app/theme.dart';

class ScanClassQRScreen extends StatefulWidget {
  const ScanClassQRScreen({super.key});

  @override
  State<ScanClassQRScreen> createState() => _ScanClassQRScreenState();
}

class _ScanClassQRScreenState extends State<ScanClassQRScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  final QRService _qrService = QRService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Meja Kelas'),
      ),
      body: Stack(
        children: [
          // Scanner View
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) async {
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final qrVal = barcodes.first.rawValue;
              if (qrVal == null) return;

              setState(() {
                _isProcessing = true;
              });

              // Stop camera scan temporarily
              await _cameraController.stop();

              // Parse QR
              final parsed = _qrService.parseClassQRContent(qrVal);
              if (parsed == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Format QR Code tidak valid / bukan milik kelas SMPM 1.'),
                    backgroundColor: Colors.red,
                  ),
                );
                // Restart scanner
                await _cameraController.start();
                setState(() {
                  _isProcessing = false;
                });
                return;
              }

              final classId = parsed['class_id']!;

              // Navigate to Input Attendance Screen
              if (!mounted) return;
              Navigator.pushReplacementNamed(
                context,
                '/guru/input-attendance',
                arguments: {'class_id': classId},
              );
            },
          ),

          // Custom scan overlay frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // Loading/processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Memproses QR Kelas...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // Teks Petunjuk
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Arahkan kamera ke QR Code yang berada di meja kelas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          )
        ],
      ),
    );
  }
}
