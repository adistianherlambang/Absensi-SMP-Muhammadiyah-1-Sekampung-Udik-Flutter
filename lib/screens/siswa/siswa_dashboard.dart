import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/siswa_provider.dart';
import '../../providers/admin_provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SiswaDashboard extends StatefulWidget {
  const SiswaDashboard({super.key});

  @override
  State<SiswaDashboard> createState() => _SiswaDashboardState();
}

class _SiswaDashboardState extends State<SiswaDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final siswaProvider = Provider.of<SiswaProvider>(context, listen: false);

      // Load data kelas admin untuk menampilkan nama kelas
      Provider.of<AdminProvider>(context, listen: false).fetchData();

      if (authProvider.currentUser?.classId != null) {
        siswaProvider.fetchActiveSessions(authProvider.currentUser!.classId!);
        siswaProvider.fetchAttendanceHistory(authProvider.currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final siswaProvider = context.watch<SiswaProvider>();
    final adminProvider = context.watch<AdminProvider>();

    final user = authProvider.currentUser;
    final classId = user?.classId ?? '';

    // Hitung metrik kehadiran
    final totalSessions = siswaProvider.history.length;
    final totalHadir = siswaProvider.history.values
        .where((att) => att.status == 'hadir')
        .length;
    final totalIzin = siswaProvider.history.values
        .where((att) => att.status == 'izin')
        .length;
    final totalSakit = siswaProvider.history.values
        .where((att) => att.status == 'sakit')
        .length;
    final totalAlpa = siswaProvider.history.values
        .where((att) => att.status == 'alpa')
        .length;
    final attendanceRate = totalSessions > 0
        ? (totalHadir / totalSessions * 100).toStringAsFixed(0)
        : '0';

    // Ambil nama kelas siswa
    String className = 'Tidak terdaftar kelas';
    if (classId.isNotEmpty) {
      try {
        final cls = adminProvider.classes.firstWhere((c) => c.id == classId);
        className = 'Kelas ${cls.name}';
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Dasbor Siswa',
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
      body: siswaProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (classId.isNotEmpty) {
                  await siswaProvider.fetchActiveSessions(classId);
                  await siswaProvider.fetchAttendanceHistory(user!.uid);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom Header
                    // Row(
                    //   children: [
                    // CircleAvatar(
                    //   radius: 24,
                    //   backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    //   child: Icon(Icons.school_rounded, color: AppTheme.primaryColor, size: 28),
                    // ),
                    // const SizedBox(width: 12),
                    // Expanded(
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Text(
                    //         'Selamat Datang, Siswa',
                    //         style: TextStyle(
                    //           fontSize: 14,
                    //           color: Colors.grey.shade600,
                    //           fontWeight: FontWeight.w500,
                    //         ),
                    //       ),
                    //       Text(
                    //         user?.name ?? '',
                    //         style: const TextStyle(
                    //           fontSize: 16,
                    //           fontWeight: FontWeight.bold,
                    //           color: AppTheme.textColor,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // Container(
                    //   padding: const EdgeInsets.all(10),
                    //   decoration: BoxDecoration(
                    //     color: Colors.grey.shade100,
                    //     shape: BoxShape.circle,
                    //   ),
                    //   child: Icon(
                    //     Icons.notifications_outlined,
                    //     color: AppTheme.textColor,
                    //     size: 22,
                    //   ),
                    // ),
                    //   ],
                    // ).animate().fadeIn(),
                    const SizedBox(height: 24),
                    Text(
                          'Mari Mulai Presensi!\n$className',
                          style: const TextStyle(
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

                    // Ringkasan Kehadiran
                    Text(
                      'Ringkasan Kehadiran Anda',
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
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatItem(
                                      'Kehadiran',
                                      '$attendanceRate%',
                                      AppTheme.hadirColor,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.grey.shade200,
                                  ),
                                  Expanded(
                                    child: _buildStatItem(
                                      'Sakit',
                                      '$totalSakit Hari',
                                      AppTheme.sakitColor,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Divider(
                                  color: Colors.grey.shade200,
                                  height: 1,
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatItem(
                                      'Izin',
                                      '$totalIzin Hari',
                                      AppTheme.izinColor,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.grey.shade200,
                                  ),
                                  Expanded(
                                    child: _buildStatItem(
                                      'Alpa / Tanpa Ket.',
                                      '$totalAlpa Hari',
                                      AppTheme.alpaColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .slideY(begin: 0.05, end: 0, duration: 300.ms)
                        .fadeIn(),
                    const SizedBox(height: 32),

                    // Quick Actions
                    Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.history_rounded),
                                label: const Text('Riwayat Hadir'),
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
                                    AppRoutes.siswaHistory,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.card_travel_rounded),
                                label: const Text('Ajukan Izin'),
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
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.siswaLeaveRequest,
                                  );
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
                    // Sesi Presensi Aktif
                    if (siswaProvider.activeSessions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Sesi Presensi Aktif',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3142),
                            ),
                      ).animate().fadeIn(delay: 75.ms),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: siswaProvider.activeSessions.length,
                        itemBuilder: (context, index) {
                          final session = siswaProvider.activeSessions[index];
                          final hasAttended = siswaProvider.history.containsKey(session.id);
                          final isMapel = session.type == 'mapel';
                          final title = isMapel ? 'Sesi Mapel: ${session.subject ?? ""}' : 'Sesi Harian Kelas';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor),
                              ),
                              subtitle: Text('Dibuka: ${session.timeStart}', style: const TextStyle(color: AppTheme.textMutedColor)),
                              trailing: hasAttended
                                  ? const Icon(Icons.check_circle, color: AppTheme.hadirColor)
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.siswaScanQR,
                                          arguments: {
                                            'session_id': session.id,
                                            'qr_id': user?.qrCodeId ?? '',
                                          },
                                        ).then((_) {
                                          if (classId.isNotEmpty) {
                                            siswaProvider.fetchActiveSessions(classId);
                                            siswaProvider.fetchAttendanceHistory(user!.uid);
                                          }
                                        });
                                      },
                                      child: const Text('Scan QR'),
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      const SizedBox(height: 32),
                    ],

                    // Riwayat Kehadiran Terbaru
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Riwayat Kehadiran Terbaru',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3142),
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.siswaHistory,
                            );
                          },
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 16),
                    siswaProvider.history.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'Belum ada riwayat kehadiran tercatat.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: siswaProvider.history.length > 5
                                ? 5
                                : siswaProvider.history.length,
                            itemBuilder: (context, index) {
                              final entry = siswaProvider.history.entries
                                  .toList()[index];
                              final sessionId = entry.key;
                              final attendance = entry.value;

                              final isMapel = sessionId.contains('MAPEL');
                              String title = isMapel
                                  ? 'Sesi Mapel'
                                  : 'Sesi Harian Kelas';

                              if (isMapel) {
                                final parts = sessionId.split('-');
                                if (parts.length > 3) {
                                  title =
                                      'Sesi Mapel: ${parts[3].replaceAll('_', ' ')}';
                                }
                              }

                              String dateStr = '';
                              try {
                                final dt = DateTime.parse(attendance.timestamp);
                                dateStr =
                                    '${dt.day}/${dt.month}/${dt.year} pukul ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                              } catch (_) {
                                dateStr = attendance.timestamp;
                              }

                              return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          isMapel
                                              ? Icons.menu_book
                                              : Icons.calendar_month,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      title: Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Waktu: $dateStr',
                                        style: const TextStyle(
                                          color: AppTheme.textMutedColor,
                                          fontSize: 11,
                                        ),
                                      ),
                                      trailing: _buildStatusWidget(
                                        attendance.status,
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .slideY(begin: 0.05, end: 0, duration: 300.ms)
                                  .fadeIn();
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
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
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
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
