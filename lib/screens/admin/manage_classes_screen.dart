import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/searchable_select.dart';
import '../../app/theme.dart';
import '../../core/services/qr_service.dart';
import '../../core/services/qr_card_renderer.dart';
import '../../models/class_model.dart';

class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  String? _selectedTeacherId;
  final QRService _qrService = QRService();

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  void _showAddClassDialog() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    _classNameController.clear();
    
    // Filter guru untuk dropdown wali kelas
    final teachers = adminProvider.users.where((u) => u.role == 'guru_piket' || u.role == 'guru_mapel').toList();
    setState(() {
      _selectedTeacherId = teachers.isNotEmpty ? teachers.first.uid : null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tambah Kelas Baru',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _classNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kelas',
                        hintText: 'Contoh: IX-A',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Nama kelas tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    if (teachers.isEmpty)
                      const Text(
                        'Peringatan: Belum ada guru terdaftar untuk dipilih sebagai Wali Kelas. Tambahkan guru terlebih dahulu.',
                        style: TextStyle(color: Colors.red),
                      )
                    else
                      SearchableSelect<dynamic>(
                        labelText: 'Wali Kelas',
                        items: teachers,
                        itemLabel: (t) => t.name as String,
                        selectedValue: _selectedTeacherId != null
                            ? teachers.firstWhere((t) => t.uid == _selectedTeacherId, orElse: () => teachers.first)
                            : null,
                        onChanged: (val) {
                          setModalState(() {
                            _selectedTeacherId = val?.uid;
                          });
                        },
                        validator: (v) => v == null ? 'Pilih wali kelas' : null,
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: teachers.isEmpty
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;

                              Navigator.pop(context);
                              try {
                                await adminProvider.createClass(
                                  _classNameController.text.trim(),
                                  _selectedTeacherId!,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Kelas berhasil ditambahkan!')),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal menambah kelas: $e')),
                                );
                              }
                            },
                      child: const Text('Simpan Kelas'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kelas'),
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => adminProvider.fetchData(),
              child: adminProvider.classes.isEmpty
                  ? const Center(child: Text('Tidak ada kelas.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: adminProvider.classes.length,
                      itemBuilder: (context, index) {
                        final cls = adminProvider.classes[index];

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
                               child: const Icon(Icons.meeting_room, color: AppTheme.primaryColor),
                             ),
                             title: Text(
                               cls.name,
                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textColor),
                             ),
                             subtitle: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 const SizedBox(height: 4),
                                 Text('Wali Kelas: $teacherName', style: const TextStyle(color: AppTheme.textMutedColor)),
                                 const SizedBox(height: 2),
                                 Text(
                                   'Jumlah Siswa: ${cls.studentIds.length}',
                                   style: const TextStyle(
                                     fontWeight: FontWeight.w600,
                                     color: AppTheme.primaryColor,
                                   ),
                                 ),
                               ],
                             ),
                             trailing: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 IconButton(
                                   icon: const Icon(Icons.qr_code, color: AppTheme.primaryColor),
                                   onPressed: () => _showQRPrintDialog(cls, _qrService.generateClassQRContent(cls.id)),
                                 ),
                                 IconButton(
                                   icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                   onPressed: () => _confirmDeleteClass(cls.id, cls.name),
                                 ),
                               ],
                             ),
                           ),
                         );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: _showAddClassDialog,
        child: const Icon(Icons.add, color: Colors.white),
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
              // Preview card (display only)
              Container(
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
                        await _shareQRImage(qrData, cls.name);
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
                        await _downloadQRImage(qrData, cls.name);
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

  Future<void> _downloadQRImage(String qrData, String className) async {
    try {
      final Uint8List pngBytes = await renderQRCardToPng(
        qrData: qrData,
        className: className,
      );

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

  Future<void> _shareQRImage(String qrData, String className) async {
    try {
      final Uint8List pngBytes = await renderQRCardToPng(
        qrData: qrData,
        className: className,
      );

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

  void _confirmDeleteClass(String classId, String className) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Kelas'),
          content: Text('Apakah Anda yakin ingin menghapus kelas "$className"? Tindakan ini juga akan melepaskan siswa dari kelas ini.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await Provider.of<AdminProvider>(context, listen: false).deleteClass(classId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kelas berhasil dihapus.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus kelas: $e')),
                  );
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
