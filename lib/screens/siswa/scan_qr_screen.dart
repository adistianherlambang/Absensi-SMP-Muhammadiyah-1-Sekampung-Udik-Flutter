import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/siswa_provider.dart';
import '../../app/theme.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  bool _initialized = false;
  late String _sessionId;
  late String _userQRId;
  bool _isProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _sessionId = args['session_id']!;
      _userQRId = args['qr_id']!;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final siswaProvider = context.watch<SiswaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code Kehadiran'),
      ),
      body: Stack(
        children: [
          // Scanner Camera View
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

              // Hentikan kamera sementara agar tidak trigger terus menerus
              await _cameraController.stop();

              try {
                if (!mounted) return;
                await Provider.of<SiswaProvider>(context, listen: false).scanQRForPresence(
                  qrContent: qrVal,
                  currentStudentUid: authProvider.currentUser!.uid,
                  currentStudentQRId: _userQRId,
                  sessionId: _sessionId,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Presensi Anda berhasil dicatat!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context); // Kembali ke dashboard
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception:', '')),
                    backgroundColor: Colors.red,
                  ),
                );
                // Restart kamera jika gagal
                await _cameraController.start();
                setState(() {
                  _isProcessing = false;
                });
              }
            },
          ),

          // QR Scanner Overlay / Frame
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

          // Loading Overlay
          if (_isProcessing || siswaProvider.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Memverifikasi Kehadiran...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // Petunjuk Teks di bagian bawah
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
                'Arahkan kamera ke QR Code yang ditampilkan untuk melakukan presensi.',
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
