import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/admin_provider.dart';
import '../../models/class_model.dart';
import '../../core/services/qr_service.dart';
import '../../core/services/qr_card_renderer.dart';
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
                  Expanded(
                    child: filteredClasses.isEmpty
                        ? const Center(child: Text('Tidak ada kelas ditemukan.'))
                        : ListView.builder(
                            itemCount: filteredClasses.length,
                            itemBuilder: (context, index) {
                              final cls = filteredClasses[index];
                              final qrData = _qrService.generateClassQRContent(cls.id);

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

  /// Pre-render gambar QR ke Uint8List, lalu tampilkan di dialog sebagai Image.memory
  Future<void> _showQRPrintDialog(ClassModel cls, String qrData) async {
    Uint8List? pngBytes;
    try {
      pngBytes = await renderQRCardToPng(qrData: qrData, className: cls.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal merender gambar QR: $e'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preview gambar yang sudah di-render offscreen
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    pngBytes!,
                    width: 280,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                const SizedBox(height: 24),
                // Bagikan QR (full-width)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppTheme.primaryColor),
                      foregroundColor: AppTheme.primaryColor,
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Bagikan QR'),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await _shareQRBytes(pngBytes!, cls.name);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('Unduh PNG'),
                          onPressed: () async {
                            Navigator.pop(dialogCtx);
                            await _downloadQRBytes(pngBytes!, cls.name);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadQRBytes(Uint8List pngBytes, String className) async {
    try {
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

  Future<void> _shareQRBytes(Uint8List pngBytes, String className) async {
    try {
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
