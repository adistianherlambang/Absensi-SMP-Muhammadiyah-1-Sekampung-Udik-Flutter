import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/auth_provider.dart';
import '../../providers/piket_provider.dart';
import '../../models/user_model.dart';
import '../../models/attendance_model.dart';
import '../../core/services/qr_service.dart';
import '../../widgets/searchable_select.dart';
import '../../app/theme.dart';

class ValidateAttendanceScreen extends StatefulWidget {
  const ValidateAttendanceScreen({super.key});

  @override
  State<ValidateAttendanceScreen> createState() =>
      _ValidateAttendanceScreenState();
}

class _ValidateAttendanceScreenState extends State<ValidateAttendanceScreen> {
  bool _initialized = false;
  late String _sessionId;
  late String _classId;
  late String _className;
  late String _sessionStatus;
  final QRService _qrService = QRService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _sessionId = args['session_id']!;
      _classId = args['class_id']!;
      _className = args['class_name']!;
      _sessionStatus = args['status']!;
      final bool autoScan = args['auto_scan'] ?? true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<PiketProvider>(context, listen: false)
            .loadSessionDetails(_sessionId, _classId);
        if (autoScan && _sessionStatus == 'active') {
          _openStudentQRScanner();
        }
      });
      _initialized = true;
    }
  }

  /// Buka Modal Scanner Kamera Pemindaian QR Siswa secara Kontinu
  void _openStudentQRScanner() {
    if (_sessionStatus != 'active') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi presensi sudah ditutup.')),
      );
      return;
    }

    final piketProvider = Provider.of<PiketProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final MobileScannerController cameraController = MobileScannerController();
    bool isProcessingScan = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.black,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: Text('Scan QR Code Siswa — Kelas $_className'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.flash_on),
                    onPressed: () => cameraController.toggleTorch(),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  MobileScanner(
                    controller: cameraController,
                    onDetect: (capture) async {
                      if (isProcessingScan) return;

                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isEmpty) return;

                      final qrVal = barcodes.first.rawValue;
                      if (qrVal == null) return;

                      setModalState(() {
                        isProcessingScan = true;
                      });

                      final parsed = _qrService.parseQRContent(qrVal);
                      final studentId =
                          parsed != null ? parsed['student_id']! : qrVal;

                      try {
                        final student = await piketProvider.scanStudentQR(
                          sessionId: _sessionId,
                          studentId: studentId,
                          classId: _classId,
                          recorderUid: authProvider.currentUser!.uid,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${student.name} - HADIR',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green.shade600,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(e
                                        .toString()
                                        .replaceAll('Exception: ', ''))),
                              ],
                            ),
                            backgroundColor: Colors.redAccent,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }

                      await Future.delayed(const Duration(milliseconds: 1500));
                      if (mounted) {
                        setModalState(() {
                          isProcessingScan = false;
                        });
                      }
                    },
                  ),
                  Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppTheme.primaryColor, width: 4),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                  if (isProcessingScan)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryColor),
                      ),
                    ),
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Arahkan kamera ke QR Siswa Kelas $_className',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Siswa otomatis tercatat HADIR begitu QR Code terdeteksi.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showOverrideDialog(
      UserModel student, AttendanceModel? currentAttendance) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_sessionStatus != 'active' &&
        authProvider.currentUser?.role != 'guru_piket') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Sesi presensi sudah ditutup. Tidak dapat mengubah absensi.')),
      );
      return;
    }

    final piketProvider = Provider.of<PiketProvider>(context, listen: false);
    String selectedStatus = currentAttendance?.status ?? 'alpa';
    final noteController =
        TextEditingController(text: currentAttendance?.note ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Edit Presensi: ${student.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status Kehadiran:',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                      DropdownMenuItem(value: 'izin', child: Text('Izin')),
                      DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                      DropdownMenuItem(value: 'alpa', child: Text('Alpa')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedStatus = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Catatan (opsional):',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Koreksi manual guru piket',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await piketProvider.overrideAttendance(
                        sessionId: _sessionId,
                        studentId: student.uid,
                        status: selectedStatus,
                        recorderUid: authProvider.currentUser!.uid,
                        note: noteController.text.trim().isNotEmpty
                            ? noteController.text.trim()
                            : null,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Presensi berhasil diperbarui!')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Gagal menyimpan: $e'),
                            backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleCloseSession() async {
    final piketProvider = Provider.of<PiketProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await piketProvider.closeHarianSession(
          _sessionId, authProvider.currentUser!.uid);
      setState(() {
        _sessionStatus = 'closed';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sesi presensi harian berhasil ditutup.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal menutup sesi: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'hadir':
        bg = AppTheme.hadirColor.withOpacity(0.12);
        fg = AppTheme.hadirColor;
        icon = Icons.check_circle;
        label = 'Hadir';
        break;
      case 'izin':
        bg = AppTheme.izinColor.withOpacity(0.15);
        fg = AppTheme.izinColor;
        icon = Icons.info;
        label = 'Izin';
        break;
      case 'sakit':
        bg = AppTheme.sakitColor.withOpacity(0.15);
        fg = AppTheme.sakitColor;
        icon = Icons.warning_amber_rounded;
        label = 'Sakit';
        break;
      case 'alpa':
      default:
        bg = AppTheme.alpaColor.withOpacity(0.15);
        fg = AppTheme.alpaColor;
        icon = Icons.cancel;
        label = 'Alpa';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final piketProvider = context.watch<PiketProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isActive = _sessionStatus == 'active';
    final isWali = authProvider.currentUser?.role == 'guru_wali_kelas';

    final totalStudents = piketProvider.students.length;
    final totalHadir = piketProvider.students
        .where(
            (s) => piketProvider.sessionAttendances[s.uid]?.status == 'hadir')
        .length;
    final totalIzin = piketProvider.students
        .where(
            (s) => piketProvider.sessionAttendances[s.uid]?.status == 'izin')
        .length;
    final totalSakit = piketProvider.students
        .where(
            (s) => piketProvider.sessionAttendances[s.uid]?.status == 'sakit')
        .length;
    final totalAlpa = piketProvider.students.where((s) {
      final st = piketProvider.sessionAttendances[s.uid]?.status;
      return st == null || st == 'alpa';
    }).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Sesi Kelas $_className'),
        centerTitle: true,
      ),
      body: piketProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Detail Sesi Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kelas $_className',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.hadirColor.withOpacity(0.15)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isActive ? 'Sesi Aktif' : 'Ditutup',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? AppTheme.hadirColor
                                      : Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sesi Presensi Harian Pagi',
                          style: TextStyle(
                            color: AppTheme.textMutedColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Stats Summary Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatBox(
                                  'Total', '$totalStudents', Colors.grey.shade800),
                            ),
                            Expanded(
                              child: _buildStatBox(
                                  'Hadir', '$totalHadir', AppTheme.hadirColor),
                            ),
                            Expanded(
                              child: _buildStatBox(
                                  'Izin', '$totalIzin', AppTheme.izinColor),
                            ),
                            Expanded(
                              child: _buildStatBox(
                                  'Sakit', '$totalSakit', AppTheme.sakitColor),
                            ),
                            Expanded(
                              child: _buildStatBox(
                                  'Alpa', '$totalAlpa', AppTheme.alpaColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Utama Scan QR Siswa
                  if (isActive && !isWali) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                        label: const Text(
                          'Scan QR Code Siswa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _openStudentQRScanner,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Header List Siswa
                  Text(
                    'Daftar Presensi Siswa',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // List Siswa
                  Expanded(
                    child: piketProvider.students.isEmpty
                        ? const Center(
                            child:
                                Text('Tidak ada siswa terdaftar di kelas ini.'))
                        : ListView.builder(
                            itemCount: piketProvider.students.length,
                            itemBuilder: (context, index) {
                              final student = piketProvider.students[index];
                              final attendance =
                                  piketProvider.sessionAttendances[student.uid];
                              final statusText = attendance?.status ?? 'alpa';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () =>
                                      _showOverrideDialog(student, attendance),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppTheme.primaryColor
                                              .withOpacity(0.12),
                                          child: Text(
                                            student.name.isNotEmpty
                                                ? student.name[0]
                                                : 'S',
                                            style: const TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: AppTheme.textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                attendance?.note != null
                                                    ? 'Catatan: ${attendance!.note}'
                                                    : (statusText == 'alpa'
                                                        ? 'Belum di-scan'
                                                        : 'Terpresensi via QR'),
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildStatusBadge(statusText),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Tombol Selesaikan & Tutup Sesi
                  if (isActive && !isWali) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _handleCloseSession,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.alpaColor,
                        side: const BorderSide(color: AppTheme.alpaColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.lock_clock_outlined),
                      label: const Text(
                        'Selesaikan & Tutup Sesi Presensi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
