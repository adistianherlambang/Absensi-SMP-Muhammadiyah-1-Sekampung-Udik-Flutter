import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/mapel_provider.dart';
import '../../models/user_model.dart';
import '../../models/leave_request_model.dart';
import '../../core/services/db_service.dart';
import '../../app/theme.dart';

class InputAttendanceScreen extends StatefulWidget {
  const InputAttendanceScreen({super.key});

  @override
  State<InputAttendanceScreen> createState() => _InputAttendanceScreenState();
}

class _InputAttendanceScreenState extends State<InputAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  
  bool _initialized = false;
  late String _classId;
  String _className = '';
  List<UserModel> _students = [];
  
  // Menyimpan status kehadiran siswa (studentId -> status)
  // Status: 'hadir', 'izin', 'sakit', 'alpa'
  final Map<String, String> _studentStatuses = {};
  final Map<String, LeaveRequestModel> _todayLeaves = {};

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _classId = args['class_id']!;

      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      
      // Ambil data kelas
      try {
        final cls = adminProvider.classes.firstWhere((c) => c.id == _classId);
        _className = cls.name;
      } catch (_) {
        _className = 'Tidak Diketahui';
      }

      // Ambil daftar siswa di kelas ini
      _students = adminProvider.users.where((u) => u.role == 'siswa' && u.classId == _classId).toList();
      _students.sort((a, b) => a.name.compareTo(b.name));

      // Inisialisasi status default: semua siswa hadir
      for (final student in _students) {
        _studentStatuses[student.uid] = 'hadir';
      }

      // Ambil data pengajuan izin/sakit hari ini untuk pre-populasi
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      DBService().getLeaveRequests().then((leaves) {
        if (!mounted) return;
        final todayLeaves = leaves.where((l) => l.date == dateStr).toList();
        setState(() {
          for (final student in _students) {
            LeaveRequestModel? studentLeave;
            for (var l in todayLeaves) {
              if (l.studentId == student.uid) {
                studentLeave = l;
                break;
              }
            }
            if (studentLeave != null) {
              _studentStatuses[student.uid] = studentLeave.status; // 'sakit' atau 'izin'
              _todayLeaves[student.uid] = studentLeave;
            }
          }
        });
      });

      _initialized = true;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hadir':
        return AppTheme.hadirColor;
      case 'izin':
        return AppTheme.izinColor;
      case 'sakit':
        return AppTheme.sakitColor;
      case 'alpa':
        return AppTheme.alpaColor;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusButton(String studentId, String status, String label) {
    final isSelected = _studentStatuses[studentId] == status;
    final statusColor = _getStatusColor(status);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _studentStatuses[studentId] = status;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? statusColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? statusColor : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mapelProvider = Provider.of<MapelProvider>(context, listen: false);

    try {
      await mapelProvider.submitClassAttendance(
        classId: _classId,
        subject: _subjectController.text.trim(),
        teacherUid: authProvider.currentUser!.uid,
        studentStatuses: _studentStatuses,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Presensi Kelas $_className berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Kembali ke Dashboard
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan presensi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapelProvider = context.watch<MapelProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Presensi Kelas $_className'),
      ),
      body: mapelProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Mata Pelajaran
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mata Pelajaran',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Matematika, Bahasa Indonesia',
                            prefixIcon: const Icon(Icons.book_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Nama mata pelajaran wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(height: 8, color: Colors.grey.shade100),

                  // Header List Siswa
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Kehadiran Siswa',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor),
                        ),
                        Text(
                          'Total: ${_students.length} Siswa',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),

                  // List Siswa
                  Expanded(
                    child: _students.isEmpty
                        ? const Center(child: Text('Tidak ada siswa di kelas ini.'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              final currentStatus = _studentStatuses[student.uid] ?? 'hadir';
                              final isHadir = currentStatus == 'hadir';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppTheme.textColor,
                                                ),
                                              ),
                                              if (_todayLeaves.containsKey(student.uid)) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Izin/Sakit: ${_todayLeaves[student.uid]!.reason}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _todayLeaves[student.uid]!.status == 'sakit'
                                                        ? AppTheme.sakitColor
                                                        : AppTheme.izinColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _studentStatuses[student.uid] = 'hadir';
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isHadir ? AppTheme.hadirColor : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isHadir ? AppTheme.hadirColor : Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Hadir',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isHadir ? Colors.white : Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (isHadir) {
                                                    _studentStatuses[student.uid] = 'alpa';
                                                  }
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: !isHadir ? Colors.redAccent : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: !isHadir ? Colors.redAccent : Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Tidak Hadir',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: !isHadir ? Colors.white : Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (!isHadir) ...[
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Text(
                                            'Status: ',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMutedColor),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildStatusButton(student.uid, 'izin', 'Izin'),
                                          const SizedBox(width: 6),
                                          _buildStatusButton(student.uid, 'sakit', 'Sakit'),
                                          const SizedBox(width: 6),
                                          _buildStatusButton(student.uid, 'alpa', 'Alpa'),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Button Submit
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Kirim Presensi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
