import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Print-Ready Card Layout
              Container(
                width: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.print),
                    label: const Text('Cetak QR'),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Kartu meja presensi kelas ${cls.name} siap dicetak!'),
                          action: SnackBarAction(
                            label: 'OK',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
