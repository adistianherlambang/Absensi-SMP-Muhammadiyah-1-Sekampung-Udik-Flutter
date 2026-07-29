import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';

class ScanClassQRScreen extends StatelessWidget {
  const ScanClassQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Pelajaran Guru'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner_rounded,
              size: 90,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Alur Presensi Berbasis QR Siswa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Setiap siswa kini memiliki QR Code masing-masing. Buka Sesi Pelajaran untuk memilih Kelas & Mata Pelajaran, lalu pindai QR Code siswa di kelas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMutedColor, height: 1.4),
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Buka Sesi Presensi Pelajaran', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.mapelOpenSession);
              },
            ),
          ],
        ),
      ),
    );
  }
}
