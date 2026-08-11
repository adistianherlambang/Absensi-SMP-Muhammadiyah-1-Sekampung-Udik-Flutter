import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/class_model.dart';
import '../../models/user_model.dart';
import '../../core/services/qr_service.dart';
import '../../core/services/qr_card_renderer.dart';
import '../../core/utils/file_download_helper.dart';
import '../../widgets/searchable_select.dart';
import '../../app/theme.dart';

class GenerateQRScreen extends StatefulWidget {
  const GenerateQRScreen({super.key});

  @override
  State<GenerateQRScreen> createState() => _GenerateQRScreenState();
}

class _GenerateQRScreenState extends State<GenerateQRScreen> {
  final QRService _qrService = QRService();
  String? _selectedClassId;
  String _searchQuery = '';
  bool _isProcessingBatch = false;

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final allClasses = adminProvider.classes;
    final allUsers = adminProvider.users;

    // Filter siswa
    final allStudents = allUsers.where((u) => u.role == 'siswa').toList();
    final filteredStudents = allStudents.where((s) {
      final matchesClass = _selectedClassId == null || s.classId == _selectedClassId;
      final matchesQuery = s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesClass && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cetak Kartu QR Siswa'),
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filter Kelas & Batch Download
                  Row(
                    children: [
                      Expanded(
                        child: SearchableSelect<ClassModel>(
                          labelText: 'Filter Kelas',
                          items: allClasses,
                          itemLabel: (c) => c.name,
                          selectedValue: _selectedClassId != null
                              ? allClasses.firstWhere((c) => c.id == _selectedClassId, orElse: () => allClasses.first)
                              : null,
                          onChanged: (val) {
                            setState(() {
                              _selectedClassId = val?.id;
                            });
                          },
                        ),
                      ),
                      if (_selectedClassId != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          tooltip: 'Tampilkan Semua Kelas',
                          onPressed: () {
                            setState(() {
                              _selectedClassId = null;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Field
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari nama siswa...',
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

                  // Tombol Unduh Batch ZIP per Kelas
                  if (_selectedClassId != null) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isProcessingBatch
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.folder_zip_rounded),
                      label: Text(
                        _isProcessingBatch
                            ? 'Memproses Batch ZIP Kelas...'
                            : 'Unduh / Bagikan Batch ZIP Kelas (${_getClassName(_selectedClassId!, allClasses)})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isProcessingBatch
                          ? null
                          : () => _handleBatchZipDownload(_selectedClassId!, allClasses, allStudents),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Header Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar Kartu QR Siswa (${filteredStudents.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // List Siswa
                  Expanded(
                    child: filteredStudents.isEmpty
                        ? const Center(child: Text('Tidak ada siswa ditemukan.'))
                        : ListView.builder(
                            itemCount: filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = filteredStudents[index];
                              final className = _getClassName(student.classId, allClasses);
                              final qrData = _qrService.generateQRContent(
                                student.uid,
                                student.qrCodeId ?? student.uid,
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                                    child: const Icon(Icons.person, color: AppTheme.primaryColor),
                                  ),
                                  title: Text(
                                    student.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor),
                                  ),
                                  subtitle: Text('Kelas: $className', style: const TextStyle(color: AppTheme.textMutedColor)),
                                  trailing: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.qr_code, size: 18),
                                    label: const Text('Kartu QR'),
                                    onPressed: () => _showQRPrintDialog(student, className, qrData),
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

  String _getClassName(String? classId, List<ClassModel> classes) {
    if (classId == null || classId.isEmpty) return 'Tanpa Kelas';
    try {
      return classes.firstWhere((c) => c.id == classId).name;
    } catch (_) {
      return 'Kelas $classId';
    }
  }

  /// Tampilkan Dialog Preview Kartu QR Siswa dengan 2 Opsi (Unduh Folder Download & Bagikan)
  Future<void> _showQRPrintDialog(UserModel student, String className, String qrData) async {
    Uint8List? pngBytes;
    try {
      pngBytes = await renderStudentQRCardToPng(
        qrData: qrData,
        studentName: student.name,
        className: className,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal merender gambar QR: $e'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (!mounted) return;

    final fileName = 'QR_Siswa_${student.name.replaceAll(' ', '_')}_$className.png';

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    pngBytes!,
                    width: 280,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                const SizedBox(height: 24),
                // Opsi 1: Bagikan
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppTheme.primaryColor),
                      foregroundColor: AppTheme.primaryColor,
                    ),
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: const Text('1. Bagikan Kartu QR'),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      try {
                        await FileDownloadHelper.shareFile(
                          bytes: pngBytes!,
                          fileName: fileName,
                          mimeType: 'image/png',
                          subjectText: 'Kartu Presensi QR Siswa - ${student.name} ($className)',
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal membagikan: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Opsi 2: Unduh ke Folder Download
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text('2. Unduh ke Folder Downloads'),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      try {
                        final savedPath = await FileDownloadHelper.saveToPublicDownloads(
                          bytes: pngBytes!,
                          fileName: fileName,
                        );
                        if (savedPath != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Berhasil disimpan di ${FileDownloadHelper.getUserFriendlyPath(savedPath)}'),
                              backgroundColor: Colors.green.shade600,
                            ),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal mengunduh: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Memproses Unduh / Bagikan Batch ZIP Kartu QR Siswa per Kelas
  Future<void> _handleBatchZipDownload(
    String classId,
    List<ClassModel> classes,
    List<UserModel> allStudents,
  ) async {
    final className = _getClassName(classId, classes);
    final classStudents = allStudents.where((s) => s.classId == classId).toList();

    if (classStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada siswa di kelas ini untuk di-zip.')),
      );
      return;
    }

    setState(() {
      _isProcessingBatch = true;
    });

    try {
      final Map<String, Uint8List> filesMap = {};

      for (var student in classStudents) {
        final qrData = _qrService.generateQRContent(student.uid, student.qrCodeId ?? student.uid);
        final pngBytes = await renderStudentQRCardToPng(
          qrData: qrData,
          studentName: student.name,
          className: className,
        );
        final safeName = student.name.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
        filesMap['$safeName.png'] = pngBytes;
      }

      final zipBytes = FileDownloadHelper.createZipArchive(filesMap);
      final zipFileName = 'QR_Siswa_$className.zip';

      if (!mounted) return;

      // Tampilkan pilihan Unduh ke Folder Download / Bagikan
      showDialog(
        context: context,
        builder: (dialogCtx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Batch ZIP Kartu QR - Kelas $className'),
            content: Text(
              'Berhasil mengemas ${filesMap.length} Kartu QR Siswa ke dalam berkas ZIP ($zipFileName). Pilih opsi penyimpanan:',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.share_rounded),
                label: const Text('Bagikan ZIP'),
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  await FileDownloadHelper.shareFile(
                    bytes: zipBytes,
                    fileName: zipFileName,
                    mimeType: 'application/zip',
                    subjectText: 'Batch ZIP Kartu QR Siswa - Kelas $className',
                  );
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Unduh ZIP'),
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  final savedPath = await FileDownloadHelper.saveToPublicDownloads(
                    bytes: zipBytes,
                    fileName: zipFileName,
                  );
                  if (savedPath != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ZIP berhasil disimpan di ${FileDownloadHelper.getUserFriendlyPath(savedPath)}'),
                        backgroundColor: Colors.green.shade600,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat batch ZIP: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingBatch = false;
        });
      }
    }
  }
}
