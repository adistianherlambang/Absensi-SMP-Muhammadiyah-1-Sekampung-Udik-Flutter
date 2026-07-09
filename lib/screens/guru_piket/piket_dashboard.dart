import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mapel_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/piket_provider.dart';
import '../../models/class_model.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PiketDashboard extends StatefulWidget {
  const PiketDashboard({super.key});

  @override
  State<PiketDashboard> createState() => _PiketDashboardState();
}

class _PiketDashboardState extends State<PiketDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final piketProvider = Provider.of<PiketProvider>(context, listen: false);
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);

      Provider.of<MapelProvider>(
        context,
        listen: false,
      ).fetchSessions(authProvider.currentUser!.uid);

      adminProvider.fetchData().then((_) {
        ClassModel? myClass;
        for (var c in adminProvider.classes) {
          if (c.homeroomTeacherId == authProvider.currentUser?.uid) {
            myClass = c;
            break;
          }
        }
        if (myClass != null) {
          final studentIds = adminProvider.users
              .where((u) => u.role == 'siswa' && u.classId == myClass!.id)
              .map((u) => u.uid)
              .toList();
          piketProvider.fetchClassLeaveRequests(studentIds);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final mapelProvider = context.watch<MapelProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final teacherUid = authProvider.currentUser?.uid ?? '';

    // Hitung metrik Guru Piket
    final totalSessions = mapelProvider.sessions.length;
    final totalClasses = adminProvider.classes.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Dashboard Guru Piket',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: mapelProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => mapelProvider.fetchSessions(teacherUid),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom Header
                    // Row(
                    //   children: [
                    //     CircleAvatar(
                    //       radius: 24,
                    //       backgroundColor: AppTheme.primaryColor.withOpacity(
                    //         0.2,
                    //       ),
                    //       child: Icon(
                    //         Icons.person_pin_rounded,
                    //         color: AppTheme.primaryColor,
                    //         size: 28,
                    //       ),
                    //     ),
                    //     const SizedBox(width: 12),
                    //     Expanded(
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           Text(
                    //             'Selamat Datang,',
                    //             style: TextStyle(
                    //               fontSize: 14,
                    //               color: Colors.grey.shade600,
                    //               fontWeight: FontWeight.w500,
                    //             ),
                    //           ),
                    //           Text(
                    //             authProvider.currentUser?.name ?? 'Guru Piket',
                    //             style: const TextStyle(
                    //               fontSize: 16,
                    //               fontWeight: FontWeight.bold,
                    //               color: AppTheme.textColor,
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //     Container(
                    //       padding: const EdgeInsets.all(10),
                    //       decoration: BoxDecoration(
                    //         color: Colors.grey.shade100,
                    //         shape: BoxShape.circle,
                    //       ),
                    //       child: Icon(
                    //         Icons.notifications_outlined,
                    //         color: AppTheme.textColor,
                    //         size: 22,
                    //       ),
                    //     ),
                    //   ],
                    // ).animate().fadeIn(),
                    const SizedBox(height: 24),
                    const Text(
                          'Kelola Absensi Harian\n& Rekapitulasi Kelas',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textColor,
                            height: 1.2,
                          ),
                        )
                        .animate()
                        .slideY(begin: 0.1, end: 0, duration: 300.ms)
                        .fadeIn(),
                    const SizedBox(height: 28),
                    const SizedBox(height: 24),

                    // Ringkasan Statistik Guru Piket
                    Text(
                      'Overview Presensi Guru Piket',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3142),
                      ),
                    ).animate().fadeIn(delay: 50.ms),
                    const SizedBox(height: 16),
                    Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'Total Sesi Saya',
                                  '$totalSessions Sesi',
                                  AppTheme.primaryColor,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade200,
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  'Total Kelas',
                                  '$totalClasses Kelas',
                                  AppTheme.izinColor,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .slideY(begin: 0.05, end: 0, duration: 300.ms)
                        .fadeIn(),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Scan Meja Kelas'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/guru/scan-class',
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.history),
                                label: const Text('Riwayat Presensi'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  side: const BorderSide(
                                    color: AppTheme.primaryColor,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/guru/history');
                                },
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 300.ms,
                          delay: 50.ms,
                        )
                        .fadeIn(),
                    const SizedBox(height: 32),

                    // Daftar Sesi Presensi Harian Aktif/Tutup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Riwayat Presensi Terbaru',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3142),
                              ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/guru/history'),
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 16),
                    mapelProvider.sessions.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'Belum ada sesi presensi dicatat.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: mapelProvider.sessions.length > 5
                                ? 5
                                : mapelProvider.sessions.length,
                            itemBuilder: (context, index) {
                              final session = mapelProvider.sessions[index];

                              // Ambil nama kelas
                              String className = 'Tidak diketahui';
                              try {
                                final cls = adminProvider.classes.firstWhere(
                                  (c) => c.id == session.classId,
                                );
                                className = cls.name;
                              } catch (_) {}

                              return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/guru/history',
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: const BoxDecoration(
                                                color: AppTheme.primaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.history_edu,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Kelas $className — ${session.subject}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: AppTheme.textColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Tanggal: ${session.date} • Jam: ${session.timeStart}',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .slideY(begin: 0.05, end: 0, duration: 300.ms)
                                  .fadeIn();
                            },
                          ),
                    // Riwayat Pengajuan Izin Siswa Kelas (Wali Kelas)
                    Builder(
                      builder: (context) {
                        final piketProvider = context.watch<PiketProvider>();
                        
                        ClassModel? myClass;
                        for (var c in adminProvider.classes) {
                          if (c.homeroomTeacherId == authProvider.currentUser?.uid) {
                            myClass = c;
                            break;
                          }
                        }
                        
                        if (myClass == null) return const SizedBox.shrink();
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32),
                            Text(
                              'Riwayat Pengajuan Izin Siswa (Kelas ${myClass.name})',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2D3142),
                                  ),
                            ).animate().fadeIn(delay: 150.ms),
                            const SizedBox(height: 16),
                            piketProvider.classLeaveRequests.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Belum ada pengajuan izin dari siswa Anda.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: piketProvider.classLeaveRequests.length,
                                    itemBuilder: (context, idx) {
                                      final req = piketProvider.classLeaveRequests[idx];
                                      
                                      String studentName = 'Siswa';
                                      try {
                                        studentName = adminProvider.users
                                            .firstWhere((u) => u.uid == req.studentId)
                                            .name;
                                      } catch (_) {}
                                      
                                      final isSakit = req.status.toLowerCase() == 'sakit';
                                      final statusColor = isSakit ? AppTheme.sakitColor : AppTheme.izinColor;
                                      final statusLabel = isSakit ? 'Sakit' : 'Izin';
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: statusColor.withOpacity(0.15),
                                            child: Icon(
                                              isSakit ? Icons.sick_outlined : Icons.assignment_turned_in_outlined,
                                              color: statusColor,
                                            ),
                                          ),
                                          title: Text(
                                            studentName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textColor,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Text('Alasan: ${req.reason}'),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Tanggal Izin: ${req.date}',
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textMutedColor),
                                              ),
                                            ],
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.circle, color: color, size: 8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
