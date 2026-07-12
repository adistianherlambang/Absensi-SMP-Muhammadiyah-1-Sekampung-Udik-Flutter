import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' hide Border;
import '../../providers/admin_provider.dart';
import '../../core/services/db_service.dart';
import '../../app/theme.dart';
import '../../models/session_model.dart';
import '../../models/user_model.dart';
import '../../widgets/searchable_select.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DBService _dbService = DBService();
  String? _selectedClassId;
  bool _isLoading = false;
  List<SessionModel> _sessions = [];
  List<UserModel> _students = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    if (_selectedClassId == null && adminProvider.classes.isNotEmpty) {
      _selectedClassId = adminProvider.classes.first.id;
      _loadClassData();
    }
  }

  Future<void> _loadClassData() async {
    if (_selectedClassId == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final allSessions = await _dbService.getSessions(classId: _selectedClassId);
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      
      setState(() {
        _sessions = allSessions;
        _students = adminProvider.users.where((u) => u.role == 'siswa' && u.classId == _selectedClassId).toList();
      });
    } catch (e) {
      // Error handling
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateExcelReport() async {
    if (_selectedClassId == null || _students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data siswa untuk dibuat laporan.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final className = adminProvider.classes.firstWhere((c) => c.id == _selectedClassId).name;

      var excel = Excel.createExcel();
      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      excel.rename(defaultSheet, 'Laporan Presensi');
      Sheet sheet = excel['Laporan Presensi'];

      // Set column widths
      sheet.setColumnWidth(0, 6.0);
      sheet.setColumnWidth(1, 28.0);
      sheet.setColumnWidth(2, 28.0);
      sheet.setColumnWidth(3, 20.0);
      sheet.setColumnWidth(4, 10.0);
      sheet.setColumnWidth(5, 10.0);
      sheet.setColumnWidth(6, 10.0);
      sheet.setColumnWidth(7, 10.0);
      sheet.setColumnWidth(8, 14.0);

      // Title Styles
      // Title Styles
      final titleStyle = CellStyle(
        bold: true,
        fontSize: 16,
        fontColorHex: ExcelColor.fromHexString('FF4F46E5'), // Indigo primary
      );

      final subtitleStyle = CellStyle(
        fontSize: 11,
        fontColorHex: ExcelColor.fromHexString('FF4B5563'), // Slate-600
      );

      final dateStyle = CellStyle(
        italic: true,
        fontSize: 9,
        fontColorHex: ExcelColor.fromHexString('FF9CA3AF'), // Gray-400
      );

      // Write Title Block
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('LAPORAN PRESENSI KELAS $className');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('SMP Muhammadiyah 1 Sekampung Udik');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = subtitleStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = TextCellValue('Tanggal Cetak: ${DateTime.now().toLocal().toString().split('.')[0]}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).cellStyle = dateStyle;

      // Table Headers style
      final headerStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('FF4F46E5'), // Indigo header fill
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
      );

      final List<String> headers = [
        'No',
        'Nama Siswa',
        'Email',
        'QR Code ID',
        'Hadir',
        'Izin',
        'Sakit',
        'Alpa',
        'Persentase'
      ];

      for (int i = 0; i < headers.length; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Write Data Rows
      int studentIndex = 1;
      int currentRowIndex = 5;

      for (var student in _students) {
        int hadirCount = 0;
        int izinCount = 0;
        int sakitCount = 0;
        int alpaCount = 0;

        for (var session in _sessions) {
          final attendances = await _dbService.getAttendances(session.id);
          final record = attendances.where((a) => a.studentId == student.uid);
          if (record.isNotEmpty) {
            final status = record.first.status.toLowerCase();
            if (status == 'hadir') hadirCount++;
            else if (status == 'izin') izinCount++;
            else if (status == 'sakit') sakitCount++;
            else alpaCount++;
          } else {
            alpaCount++;
          }
        }

        int totalSessions = _sessions.length;
        double percentage = totalSessions > 0 ? (hadirCount / totalSessions) * 100 : 0.0;

        // Alternating row background
        final isEven = studentIndex % 2 == 0;
        final rowBgColor = isEven ? 'FFF9FAFB' : 'FFFFFFFF';

        final dataStyleLeft = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString(rowBgColor),
          fontColorHex: ExcelColor.fromHexString('FF1F2937'),
          fontSize: 9,
          horizontalAlign: HorizontalAlign.Left,
        );

        final dataStyleCenter = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString(rowBgColor),
          fontColorHex: ExcelColor.fromHexString('FF1F2937'),
          fontSize: 9,
          horizontalAlign: HorizontalAlign.Center,
        );

        // 0: No
        var cellNo = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRowIndex));
        cellNo.value = IntCellValue(studentIndex);
        cellNo.cellStyle = dataStyleCenter;

        // 1: Nama
        var cellName = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRowIndex));
        cellName.value = TextCellValue(student.name);
        cellName.cellStyle = dataStyleLeft;

        // 2: Email
        var cellEmail = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRowIndex));
        cellEmail.value = TextCellValue(student.email);
        cellEmail.cellStyle = dataStyleLeft;

        // 3: QR Code ID
        var cellQR = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRowIndex));
        cellQR.value = TextCellValue(student.qrCodeId ?? '-');
        cellQR.cellStyle = dataStyleCenter;

        // 4: Hadir
        var cellHadir = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRowIndex));
        cellHadir.value = IntCellValue(hadirCount);
        cellHadir.cellStyle = dataStyleCenter;

        // 5: Izin
        var cellIzin = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRowIndex));
        cellIzin.value = IntCellValue(izinCount);
        cellIzin.cellStyle = dataStyleCenter;

        // 6: Sakit
        var cellSakit = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRowIndex));
        cellSakit.value = IntCellValue(sakitCount);
        cellSakit.cellStyle = dataStyleCenter;

        // 7: Alpa
        var cellAlpa = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRowIndex));
        cellAlpa.value = IntCellValue(alpaCount);
        cellAlpa.cellStyle = dataStyleCenter;

        // 8: Persentase
        var cellPerc = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: currentRowIndex));
        cellPerc.value = TextCellValue("${percentage.toStringAsFixed(1)}%");
        cellPerc.cellStyle = dataStyleCenter;

        studentIndex++;
        currentRowIndex++;
      }

      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Gagal membuat byte file Excel');

      if (Platform.isAndroid || Platform.isIOS) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/Laporan_Presensi_Kelas_${className.replaceAll(' ', '_')}.xlsx';
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
        await file.create(recursive: true);
        await file.writeAsBytes(fileBytes);

        // Native share sheet
        await Share.shareXFiles([XFile(path)], text: 'Laporan Presensi Kelas $className');
      } else {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Pilih lokasi penyimpanan Laporan Excel:',
          fileName: 'Laporan_Presensi_Kelas_${className.replaceAll(' ', '_')}.xlsx',
        );
        if (outputFile != null) {
          final file = File(outputFile);
          await file.create(recursive: true);
          await file.writeAsBytes(fileBytes);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh laporan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmResetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Data Kehadiran'),
        content: const Text(
          'Apakah Anda yakin ingin melakukan reset semua data kehadiran dan pengajuan izin untuk memulai tahun ajaran baru? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _dbService.resetAttendanceData();
        await _loadClassData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua data kehadiran berhasil direset untuk tahun ajaran baru!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal melakukan reset data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Kehadiran'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (adminProvider.classes.isEmpty)
                    const Center(child: Text('Tidak ada kelas terdaftar.'))
                  else ...[
                    SearchableSelect<dynamic>(
                      labelText: 'Pilih Kelas',
                      items: adminProvider.classes,
                      itemLabel: (c) => c.name as String,
                      selectedValue: _selectedClassId != null
                          ? adminProvider.classes.firstWhere((c) => c.id == _selectedClassId, orElse: () => adminProvider.classes.first)
                          : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedClassId = val?.id;
                        });
                        _loadClassData();
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Rincian Laporan',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.people_outline, color: AppTheme.primaryColor, size: 20),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(child: Text('Jumlah Siswa Terdata', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textColor))),
                              Text('${_students.length} orang', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Colors.grey.shade200, height: 1),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.history_toggle_off, color: AppTheme.accentColor, size: 20),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(child: Text('Total Sesi Presensi', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textColor))),
                              Text('${_sessions.length} sesi', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: Icon(Platform.isAndroid || Platform.isIOS ? Icons.share : Icons.download),
                      label: Text(Platform.isAndroid || Platform.isIOS ? 'Bagikan Laporan (Excel)' : 'Unduh Laporan (Excel)'),
                      onPressed: _students.isEmpty ? null : _generateExcelReport,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.restart_alt, color: Colors.red),
                      label: const Text('Reset Data Tahun Ajaran Baru', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _confirmResetData,
                    ),
                    const SizedBox(height: 16),
                  ]
                ],
              ),
            ),
    );
  }
}
