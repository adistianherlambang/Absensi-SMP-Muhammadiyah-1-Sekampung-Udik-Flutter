import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/mapel_provider.dart';
import '../../models/session_model.dart';
import '../../app/theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoadingData = false;
  SessionModel? _editingSession;
  final Map<String, String> _editStatuses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mapelProvider = Provider.of<MapelProvider>(context, listen: false);
    await mapelProvider.fetchSessions(authProvider.currentUser!.uid);
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

  void _startEditing(SessionModel session) async {
    final mapelProvider = Provider.of<MapelProvider>(context, listen: false);
    setState(() {
      _isLoadingData = true;
      _editingSession = session;
    });

    try {
      await mapelProvider.loadSessionDetails(session.id, session.classId);
      
      // Salin status absensi saat ini ke lokal
      _editStatuses.clear();
      for (final student in mapelProvider.students) {
        final att = mapelProvider.sessionAttendances[student.uid];
        _editStatuses[student.uid] = att?.status ?? 'alpa';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat detail absensi: $e')),
      );
      _editingSession = null;
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _saveEdits() async {
    if (_editingSession == null) return;
    
    final mapelProvider = Provider.of<MapelProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await mapelProvider.updateClassAttendance(
        sessionId: _editingSession!.id,
        teacherUid: authProvider.currentUser!.uid,
        studentStatuses: _editStatuses,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absensi berhasil diperbarui!'), backgroundColor: Colors.green),
      );
      setState(() {
        _editingSession = null;
      });
      _loadHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui absensi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDelete(SessionModel session) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Sesi Presensi'),
          content: Text('Apakah Anda yakin ingin menghapus sesi ${session.subject} pada tanggal ${session.date}? Catatan kehadiran siswa pada sesi ini juga akan dihapus.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final mapelProvider = Provider.of<MapelProvider>(context, listen: false);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);

                try {
                  await mapelProvider.deleteClassAttendance(
                    sessionId: session.id,
                    teacherUid: authProvider.currentUser!.uid,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sesi presensi berhasil dihapus.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus sesi: $e'), backgroundColor: Colors.red),
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

  Widget _buildStatusButton(String studentId, String status, String label) {
    final isSelected = _editStatuses[studentId] == status;
    final statusColor = _getStatusColor(status);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _editStatuses[studentId] = status;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? statusColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? statusColor : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapelProvider = context.watch<MapelProvider>();
    final adminProvider = context.watch<AdminProvider>();

    if (_editingSession != null) {
      // Tampilan EDIT Presensi
      String className = 'Tidak Diketahui';
      try {
        final cls = adminProvider.classes.firstWhere((c) => c.id == _editingSession!.classId);
        className = cls.name;
      } catch (_) {}

      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Kehadiran $className'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _editingSession = null;
              });
            },
          ),
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mata Pelajaran: ${_editingSession!.subject}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Tanggal: ${_editingSession!.date} - Mulai: ${_editingSession!.timeStart}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(height: 8, color: Colors.grey.shade100),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: mapelProvider.students.length,
                      itemBuilder: (context, index) {
                        final student = mapelProvider.students[index];
                        final currentStatus = _editStatuses[student.uid] ?? 'hadir';
                        final isHadir = currentStatus == 'hadir';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      student.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _editStatuses[student.uid] = 'hadir';
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: isHadir ? AppTheme.hadirColor : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isHadir ? AppTheme.hadirColor : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            'Hadir',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isHadir ? Colors.white : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isHadir) {
                                              _editStatuses[student.uid] = 'alpa';
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: !isHadir ? Colors.redAccent : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: !isHadir ? Colors.redAccent : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            'Tidak Hadir',
                                            style: TextStyle(
                                              fontSize: 11,
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
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text(
                                      'Status: ',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMutedColor),
                                    ),
                                    const SizedBox(width: 6),
                                    _buildStatusButton(student.uid, 'izin', 'Izin'),
                                    const SizedBox(width: 4),
                                    _buildStatusButton(student.uid, 'sakit', 'Sakit'),
                                    const SizedBox(width: 4),
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _saveEdits,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
      );
    }

    // Tampilan UTAMA Riwayat/Histori
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histori Presensi'),
      ),
      body: mapelProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: mapelProvider.sessions.isEmpty
                  ? const Center(child: Text('Belum ada riwayat presensi yang dicatat.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: mapelProvider.sessions.length,
                      itemBuilder: (context, index) {
                        final session = mapelProvider.sessions[index];

                        // Dapatkan nama kelas
                        String className = 'Tidak Diketahui';
                        try {
                          final cls = adminProvider.classes.firstWhere((c) => c.id == session.classId);
                          className = cls.name;
                        } catch (_) {}

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.history_edu, color: AppTheme.primaryColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kelas $className - ${session.subject}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tanggal: ${session.date} • Jam: ${session.timeStart}',
                                        style: const TextStyle(color: AppTheme.textMutedColor, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                                      onPressed: () => _startEditing(session),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _confirmDelete(session),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
