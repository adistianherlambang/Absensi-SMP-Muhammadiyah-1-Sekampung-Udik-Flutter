import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mapel_provider.dart';
import '../../models/user_model.dart';
import '../../models/attendance_model.dart';
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

  void _showMarkDialog(UserModel student, AttendanceModel? currentAttendance) {
    if (_sessionStatus != 'active') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi mapel sudah ditutup. Tidak dapat mengubah absensi.')),
      );
      return;
    }

    final mapelProvider = Provider.of<MapelProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    String selectedStatus = currentAttendance?.status ?? 'hadir';
    final noteController = TextEditingController(text: currentAttendance?.note ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Presensi Mapel: ${student.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Kehadiran:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.all(12)),
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
                  const Text('Catatan (opsional):', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Terlambat 10 menit',
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Menyimpan absensi...')),
                    );
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
                        const SnackBar(content: Text('Absensi berhasil disimpan!')),
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
        const SnackBar(content: Text('Sesi mata pelajaran berhasil ditutup.')),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Sesi $_subject'),
      ),
      body: mapelProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detail Sesi Mapel', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text('Mata Pelajaran: $_subject'),
                          Text('Kelas: $_className'),
                          Text('ID Sesi: $_sessionId'),
                          Text(
                            isActive ? 'Status: Sesi Terbuka' : 'Status: Sesi Ditutup',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Daftar Kehadiran Siswa',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: mapelProvider.students.isEmpty
                        ? const Center(child: Text('Tidak ada siswa di kelas ini.'))
                        : ListView.builder(
                            itemCount: mapelProvider.students.length,
                            itemBuilder: (context, index) {
                              final student = mapelProvider.students[index];
                              final attendance = mapelProvider.sessionAttendances[student.uid];
                              final statusText = attendance?.status ?? 'alpa';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: attendance?.note != null ? Text('Catatan: ${attendance!.note}') : null,
                                  trailing: _buildStatusWidget(statusText),
                                  onTap: () => _showMarkDialog(student, attendance),
                                ),
                              );
                            },
                          ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handleCloseSession,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alpaColor),
                      child: const Text('Tutup Sesi Mapel'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
