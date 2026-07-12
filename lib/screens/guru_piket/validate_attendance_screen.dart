import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/piket_provider.dart';
import '../../models/user_model.dart';
import '../../models/attendance_model.dart';
import '../../widgets/searchable_select.dart';
import '../../app/theme.dart';

class ValidateAttendanceScreen extends StatefulWidget {
  const ValidateAttendanceScreen({super.key});

  @override
  State<ValidateAttendanceScreen> createState() => _ValidateAttendanceScreenState();
}

class _ValidateAttendanceScreenState extends State<ValidateAttendanceScreen> {
  bool _initialized = false;
  late String _sessionId;
  late String _classId;
  late String _className;
  late String _sessionStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _sessionId = args['session_id']!;
      _classId = args['class_id']!;
      _className = args['class_name']!;
      _sessionStatus = args['status']!;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<PiketProvider>(context, listen: false)
            .loadSessionDetails(_sessionId, _classId);
      });
      _initialized = true;
    }
  }

  void _showOverrideDialog(UserModel student, AttendanceModel? currentAttendance) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser?.role == 'guru_wali_kelas') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guru Wali Kelas hanya memiliki hak akses melihat presensi.')),
      );
      return;
    }
    if (_sessionStatus != 'active') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi sudah ditutup. Tidak dapat mengubah kehadiran.')),
      );
      return;
    }

    final piketProvider = Provider.of<PiketProvider>(context, listen: false);
    
    String selectedStatus = currentAttendance?.status ?? 'hadir';
    final noteController = TextEditingController(text: currentAttendance?.note ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Presensi Manual: ${student.name}'),
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
                  const Text('Catatan Tambahan:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Izin acara keluarga, Sakit demam',
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
                      const SnackBar(content: Text('Menyimpan perubahan kehadiran...')),
                    );
                    try {
                      await piketProvider.updateAttendanceManual(
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
    final piketProvider = Provider.of<PiketProvider>(context, listen: false);
    try {
      await piketProvider.closeHarianSession(_sessionId);
      setState(() {
        _sessionStatus = 'closed';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi presensi harian berhasil ditutup.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menutup sesi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Helper untuk mendapatkan representasi status tanpa menggunakan badge
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
    final piketProvider = context.watch<PiketProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isActive = _sessionStatus == 'active';
    final isWali = authProvider.currentUser?.role == 'guru_wali_kelas';

    return Scaffold(
      appBar: AppBar(
        title: Text('Sesi Kelas $_className'),
      ),
      body: piketProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detail Sesi Presensi', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textColor)),
                          const SizedBox(height: 8),
                          Text('ID Sesi: $_sessionId', style: const TextStyle(color: AppTheme.textMutedColor)),
                          const Text('Tipe: Harian Pagi', style: TextStyle(color: AppTheme.textMutedColor)),
                          Text(
                            isActive ? 'Status: Sesi Terbuka' : 'Status: Sesi Ditutup',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isActive ? AppTheme.hadirColor : Colors.grey,
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
                    child: piketProvider.students.isEmpty
                        ? const Center(child: Text('Tidak ada siswa di kelas ini.'))
                        : ListView.builder(
                            itemCount: piketProvider.students.length,
                            itemBuilder: (context, index) {
                              final student = piketProvider.students[index];
                              final attendance = piketProvider.sessionAttendances[student.uid];
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
                                   subtitle: attendance?.note != null ? Text('Catatan: ${attendance!.note}', style: const TextStyle(color: AppTheme.textMutedColor)) : null,
                                   trailing: _buildStatusWidget(statusText),
                                   onTap: () => _showOverrideDialog(student, attendance),
                                 ),
                               );
                            },
                          ),
                  ),
                  if (isActive && !isWali) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handleCloseSession,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alpaColor),
                      child: const Text('Tutup Sesi Presensi'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
