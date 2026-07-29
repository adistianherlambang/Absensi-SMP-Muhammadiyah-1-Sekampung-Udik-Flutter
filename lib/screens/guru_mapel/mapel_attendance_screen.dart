import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mapel_provider.dart';
import '../../models/user_model.dart';
import '../../models/attendance_model.dart';
import '../../core/services/qr_service.dart';
import '../../widgets/searchable_select.dart';
import '../../app/theme.dart';

class MapelAttendanceScreen extends StatefulWidget {
  const MapelAttendanceScreen({super.key});

  @override
  State<MapelAttendanceScreen> createState() => _MapelAttendanceScreenState();
}

class _MapelAttendanceScreenState extends State<MapelAttendanceScreen> {
  bool _initialized = false;
  late String _sessionId;
  late String _classId;
  late String _className;
  late String _subject;
  late String _sessionStatus;
  final QRService _qrService = QRService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _sessionId = args['session_id']!;
      _classId = args['class_id']!;
      _className = args['class_name']!;
      _subject = args['subject']!;
      _sessionStatus = args['status']!;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<MapelProvider>(context, listen: false)
            .loadSessionDetails(_sessionId, _classId);
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

    final mapelProvider = Provider.of<MapelProvider>(context, listen: false);
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
                title: const Text('Scan QR Code Siswa'),
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

                      // Parse Student QR
                      final parsed = _qrService.parseQRContent(qrVal);
                      final studentId = parsed != null ? parsed['student_id']! : qrVal;

                      try {
                        final student = await mapelProvider.scanStudentQR(
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
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${student.name} - HADIR',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e.toString().replaceAll('Exception: ', ''))),
                              ],
                            ),
                            backgroundColor: Colors.redAccent,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }

                      // Jeda 1.5 detik sebelum siap memindai siswa berikutnya
                      await Future.delayed(const Duration(milliseconds: 1500));
                      if (mounted) {
                        setModalState(() {
                          isProcessingScan = false;
                        });
                      }
                    },
                  ),

                  // Overlay Frame Scan
                  Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.greenAccent, width: 4),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),

                  // Indicator Status Proses
                  if (isProcessingScan)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.greenAccent),
                      ),
                    ),

                  // Footer Info
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Arahkan kamera ke QR Siswa Kelas $_className',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Siswa otomatis bertambah HADIR tanpa butuh tombol persetujuan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 11),
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

  void _showMarkDialog(UserModel student, AttendanceModel? currentAttendance) {
    if (_sessionStatus != 'active') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi mapel sudah ditutup. Tidak dapat mengubah absensi.')),
      );
      return;
    }

    final mapelProvider = Provider.of<MapelProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    String selectedStatus = currentAttendance?.status ?? 'alpa';
    final noteController = TextEditingController(text: currentAttendance?.note ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Koreksi Presensi: ${student.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Status Kehadiran:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SearchableSelect<Map<String, String>>(
                    labelText: 'Status Kehadiran',
                    items: const [
                      {'value': 'hadir', 'label': 'Hadir'},
                      {'value': 'izin', 'label': 'Izin'},
                      {'value': 'sakit', 'label': 'Sakit'},
                      {'value': 'alpa', 'label': 'Alpa'},
                    ],
                    itemLabel: (item) => item['label']!,
                    selectedValue: {
                      'value': selectedStatus,
                      'label': selectedStatus == 'hadir' ? 'Hadir' :
                               selectedStatus == 'izin' ? 'Izin' :
                               selectedStatus == 'sakit' ? 'Sakit' : 'Alpa'
                    },
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedStatus = val['value']!;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Catatan (opsional):', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Koreksi manual guru',
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
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await mapelProvider.updateAttendance(
                        sessionId: _sessionId,
                        studentId: student.uid,
                        status: selectedStatus,
                        recorderUid: authProvider.currentUser!.uid,
                        note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Presensi berhasil diperbarui!')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
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
    final mapelProvider = Provider.of<MapelProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await mapelProvider.closeMapelSession(_sessionId, authProvider.currentUser!.uid);
      setState(() {
        _sessionStatus = 'closed';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi presensi mata pelajaran berhasil ditutup dan disimpan ke histori.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menutup sesi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildStatusWidget(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'hadir':
        color = AppTheme.hadirColor;
        icon = Icons.check_circle_outline;
        label = 'Hadir';
        break;
      case 'izin':
        color = AppTheme.izinColor;
        icon = Icons.info_outline;
        label = 'Izin';
        break;
      case 'sakit':
        color = AppTheme.sakitColor;
        icon = Icons.warning_amber_outlined;
        label = 'Sakit';
        break;
      case 'alpa':
      default:
        color = AppTheme.alpaColor;
        icon = Icons.highlight_off;
        label = 'Alpa';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapelProvider = context.watch<MapelProvider>();
    final isActive = _sessionStatus == 'active';

    final totalStudents = mapelProvider.students.length;
    final totalHadir = mapelProvider.students.where((s) => mapelProvider.sessionAttendances[s.uid]?.status == 'hadir').length;
    final totalIzin = mapelProvider.students.where((s) => mapelProvider.sessionAttendances[s.uid]?.status == 'izin').length;
    final totalSakit = mapelProvider.students.where((s) => mapelProvider.sessionAttendances[s.uid]?.status == 'sakit').length;
    final totalAlpa = mapelProvider.students.where((s) {
      final st = mapelProvider.sessionAttendances[s.uid]?.status;
      return st == null || st == 'alpa';
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Presensi Sesi $_subject'),
      ),
      body: mapelProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Detail Sesi Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Detail Sesi Pelajaran', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textColor)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'Aktif' : 'Ditutup',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Mata Pelajaran: $_subject', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                        Text('Kelas: $_className', style: const TextStyle(color: AppTheme.textMutedColor)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem('Total', '$totalStudents', Colors.black87),
                            _buildSummaryItem('Hadir', '$totalHadir', AppTheme.hadirColor),
                            _buildSummaryItem('Izin', '$totalIzin', AppTheme.izinColor),
                            _buildSummaryItem('Sakit', '$totalSakit', AppTheme.sakitColor),
                            _buildSummaryItem('Alpa', '$totalAlpa', AppTheme.alpaColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tombol Utama: Scan QR Code Siswa
                  if (isActive) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 26),
                      label: const Text(
                        'SCAN QR CODE SISWA',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      onPressed: _openStudentQRScanner,
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    'Daftar Presensi Siswa Kelas $_className',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: mapelProvider.students.isEmpty
                        ? const Center(child: Text('Tidak ada siswa terdaftar di kelas ini.'))
                        : ListView.builder(
                            itemCount: mapelProvider.students.length,
                            itemBuilder: (context, index) {
                              final student = mapelProvider.students[index];
                              final attendance = mapelProvider.sessionAttendances[student.uid];
                              final statusText = attendance?.status ?? 'alpa';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                                  subtitle: Text(
                                    attendance?.note != null ? 'Catatan: ${attendance!.note}' : (statusText == 'alpa' ? 'Belum di-scan (Default Tidak Hadir)' : 'Presensi via Scan'),
                                    style: const TextStyle(color: AppTheme.textMutedColor, fontSize: 12),
                                  ),
                                  trailing: _buildStatusWidget(statusText),
                                  onTap: () => _showMarkDialog(student, attendance),
                                ),
                              );
                            },
                          ),
                  ),

                  if (isActive) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _handleCloseSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.alpaColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Selesaikan & Tutup Sesi Presensi'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
