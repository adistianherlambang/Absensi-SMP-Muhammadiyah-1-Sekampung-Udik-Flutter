import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/db_service.dart';
import '../../models/session_model.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';
import '../../widgets/searchable_select.dart';
import '../../app/theme.dart';

class WeeklyRecapScreen extends StatefulWidget {
  const WeeklyRecapScreen({super.key});

  @override
  State<WeeklyRecapScreen> createState() => _WeeklyRecapScreenState();
}

class _WeeklyRecapScreenState extends State<WeeklyRecapScreen> {
  final DBService _dbService = DBService();
  String? _selectedClassId;
  bool _isLoading = false;
  List<SessionModel> _sessions = [];
  List<UserModel> _students = [];
  Map<String, Map<String, int>> _studentStats = {}; // studentUid -> {hadir: x, izin: y, sakit: z, alpa: w}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_selectedClassId == null) {
      if (authProvider.currentUser?.role == 'guru_wali_kelas') {
        ClassModel? myClass;
        for (var c in adminProvider.classes) {
          if (c.homeroomTeacherId == authProvider.currentUser?.uid) {
            myClass = c;
            break;
          }
        }
        if (myClass != null) {
          _selectedClassId = myClass.id;
          _loadWeeklyRecap();
        }
      } else if (adminProvider.classes.isNotEmpty) {
        _selectedClassId = adminProvider.classes.first.id;
        _loadWeeklyRecap();
      }
    }
  }

  Future<void> _loadWeeklyRecap() async {
    if (_selectedClassId == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final allSessions = await _dbService.getSessions(classId: _selectedClassId, type: 'harian');
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final studentsInClass = adminProvider.users.where((u) => u.role == 'siswa' && u.classId == _selectedClassId).toList();

      final Map<String, Map<String, int>> stats = {};

      for (var student in studentsInClass) {
        stats[student.uid] = {'hadir': 0, 'izin': 0, 'sakit': 0, 'alpa': 0};
      }

      // Filter sesi 7 hari terakhir
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final weeklySessions = allSessions.where((s) {
        try {
          final sessionDate = DateTime.parse(s.date);
          return sessionDate.isAfter(oneWeekAgo) || s.date == "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        } catch (_) {
          return false;
        }
      }).toList();

      for (var session in weeklySessions) {
        final attendances = await _dbService.getAttendances(session.id);
        for (var student in studentsInClass) {
          final record = attendances.where((a) => a.studentId == student.uid);
          if (stats.containsKey(student.uid)) {
            if (record.isNotEmpty) {
              final status = record.first.status.toLowerCase();
              stats[student.uid]![status] = (stats[student.uid]![status] ?? 0) + 1;
            } else {
              // Jika tidak ada data presensi tapi sesi ada, dianggap Alpa
              stats[student.uid]!['alpa'] = (stats[student.uid]!['alpa'] ?? 0) + 1;
            }
          }
        }
      }

      setState(() {
        _sessions = weeklySessions;
        _students = studentsInClass;
        _studentStats = stats;
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isWali = authProvider.currentUser?.role == 'guru_wali_kelas';

    return Scaffold(
      appBar: AppBar(
        title: Text(isWali ? 'Rekap Mingguan Kelas Saya' : 'Rekap Mingguan Piket'),
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
                    if (isWali)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.meeting_room, color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Text(
                              'Kelas Bimbingan: ${_selectedClassId != null ? adminProvider.classes.firstWhere((c) => c.id == _selectedClassId, orElse: () => adminProvider.classes.first).name : "Tidak ada"}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor),
                            ),
                          ],
                        ),
                      )
                    else
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
                          _loadWeeklyRecap();
                        },
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Statistik Kehadiran 7 Hari Terakhir (${_sessions.length} Sesi)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _students.isEmpty
                          ? const Center(child: Text('Tidak ada siswa di kelas ini.'))
                          : ListView.builder(
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                final stats = _studentStats[student.uid] ?? {'hadir': 0, 'izin': 0, 'sakit': 0, 'alpa': 0};

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor),
                                        ),
                                        const SizedBox(height: 8),
                                        // Baris Rincian (Teks Bersih Tanpa Badge)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Hadir: ${stats['hadir']}', style: const TextStyle(color: AppTheme.hadirColor, fontWeight: FontWeight.w600)),
                                            Text('Izin: ${stats['izin']}', style: const TextStyle(color: AppTheme.izinColor, fontWeight: FontWeight.w600)),
                                            Text('Sakit: ${stats['sakit']}', style: const TextStyle(color: AppTheme.sakitColor, fontWeight: FontWeight.w600)),
                                            Text('Alpa: ${stats['alpa']}', style: const TextStyle(color: AppTheme.alpaColor, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
