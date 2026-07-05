import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/admin_provider.dart';
import '../../models/class_model.dart';
import '../../core/services/qr_service.dart';
import '../../app/theme.dart';

class GenerateQRScreen extends StatefulWidget {
  const GenerateQRScreen({super.key});

  @override
  State<GenerateQRScreen> createState() => _GenerateQRScreenState();
}

class _GenerateQRScreenState extends State<GenerateQRScreen> {
  final QRService _qrService = QRService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final allClasses = adminProvider.classes;

    // Filter kelas berdasarkan pencarian
    final filteredClasses = allClasses.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cetak QR Code Kelas'),
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari nama kelas...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Daftar Kelas
                  Expanded(
                    child: filteredClasses.isEmpty
                        ? const Center(child: Text('Tidak ada kelas ditemukan.'))
                        : ListView.builder(
                            itemCount: filteredClasses.length,
                            itemBuilder: (context, index) {
                              final cls = filteredClasses[index];
                              final qrData = _qrService.generateClassQRContent(cls.id);

                              // Dapatkan nama wali kelas
                              String teacherName = 'Tidak ada';
                              try {
                                final teacher = adminProvider.users.firstWhere((u) => u.uid == cls.homeroomTeacherId);
                                teacherName = teacher.name;
                              } catch (_) {}

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.meeting_room_outlined, color: AppTheme.primaryColor),
                                  ),
                                  title: Text(
                                    cls.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor),
                                  ),
                                  subtitle: Text('Wali Kelas: $teacherName', style: const TextStyle(color: AppTheme.textMutedColor)),
                                  trailing: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.qr_code, size: 18),
                                    label: const Text('QR Meja'),
                                    onPressed: () => _showQRPrintDialog(cls, qrData),
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

  void _showQRPrintDialog(ClassModel cls, String qrData) {
    final GlobalKey repaintKey = GlobalKey();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Print-Ready Card Layout wrapped in RepaintBoundary
              RepaintBoundary(
                key: repaintKey,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SMP MUHAMMADIYAH 1',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black, letterSpacing: 0.5),
                        textAlign: TextAlign.center,
                      ),
                      const Text(
                        'SEKAMPUNG UDIK',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        color: Colors.black,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      const SizedBox(height: 16),
                      // QR Code
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(10),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 180.0,
                          gapless: false,
                          errorStateBuilder: (cxt, err) {
                            return const Center(child: Text('Gagal membuat QR Code'));
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'KARTU MEJA PRESENSI',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'KELAS ${cls.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Scan kartu ini menggunakan aplikasi Guru untuk mencatat kehadiran kelas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9, color: Colors.black87, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppTheme.primaryColor),
                        foregroundColor: AppTheme.primaryColor,
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Bagikan QR'),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _shareQRImage(repaintKey, cls.name);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Unduh PNG'),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _downloadQRImage(repaintKey, cls.name);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadQRImage(GlobalKey repaintKey, String className) async {
    try {
      final RenderRepaintBoundary? boundary =
          repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw 'Gagal menemukan area gambar';
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw 'Gagal merender data gambar';
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      String path = '';
      if (Platform.isAndroid || Platform.isIOS) {
        Directory? directory = await getExternalStorageDirectory();
        directory ??= await getApplicationDocumentsDirectory();
        path = '${directory.path}/QR_Presensi_Kelas_$className.png';
        final file = File(path);
        await file.create(recursive: true);
        await file.writeAsBytes(pngBytes);
      } else {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Pilih lokasi penyimpanan gambar QR:',
          fileName: 'QR_Presensi_Kelas_$className.png',
        );
        if (outputFile != null) {
          path = outputFile;
          final file = File(path);
          await file.create(recursive: true);
          await file.writeAsBytes(pngBytes);
        } else {
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gambar QR berhasil diunduh ke: $path'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh gambar QR: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _shareQRImage(GlobalKey repaintKey, String className) async {
    try {
      final RenderRepaintBoundary? boundary =
          repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw 'Gagal menemukan area gambar';
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw 'Gagal merender data gambar';
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final XFile xFile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: 'QR_Presensi_Kelas_$className.png',
      );

      await Share.shareXFiles(
        [xFile],
        text: 'Kartu Meja Presensi Kelas $className - SMP Muhammadiyah 1 Sekampung Udik',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membagikan gambar QR: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
