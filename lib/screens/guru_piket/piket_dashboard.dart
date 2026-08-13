import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mapel_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/piket_provider.dart';
import '../../models/class_model.dart';
import '../../models/user_model.dart';
import '../../models/session_model.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PiketDashboard extends StatefulWidget {
  const PiketDashboard({super.key});

  @override
  State<PiketDashboard> createState() => _PiketDashboardState();
}

class _PiketDashboardState extends State<PiketDashboard> {
  String _dateFilter = 'Hari Ini'; // 'Hari Ini' | 'Pilih Tanggal' | 'Semua'
  DateTime? _customFilterDate;

  Future<void> _selectFilterDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _customFilterDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _dateFilter = 'Pilih Tanggal';
        _customFilterDate = picked;
      });
    }
  }

  void _showClassSessionsModal(
      BuildContext context, ClassModel cls, List<SessionModel> sessions) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sesi Presensi Kelas ${cls.name}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Dari Seluruh Guru Mapel & Piket',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Expanded(
                    child: sessions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada sesi presensi dari guru manapun untuk Kelas ${cls.name}.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              final isActive = session.status == 'active';

                              String teacherName = 'Guru';
                              try {
                                final teacher = adminProvider.users.firstWhere(
                                  (u) => u.uid == session.createdBy,
                                );
                                teacherName = teacher.name;
                              } catch (_) {}

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (session.type == 'mapel') {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.mapelAttendance,
                                        arguments: {
                                          'session_id': session.id,
                                          'class_id': session.classId,
                                          'class_name': cls.name,
                                          'subject': session.subject,
                                          'status': session.status,
                                          'auto_scan': false,
                                        },
                                      );
                                    } else {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.piketValidate,
                                        arguments: {
                                          'session_id': session.id,
                                          'class_id': session.classId,
                                          'class_name': cls.name,
                                          'status': session.status,
                                          'auto_scan': false,
                                        },
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isActive
                                              ? AppTheme.hadirColor
                                                  .withOpacity(0.15)
                                              : AppTheme.primaryColor
                                                  .withOpacity(0.12),
                                          child: Icon(
                                            session.type == 'mapel'
                                                ? Icons.menu_book_rounded
                                                : Icons.badge_outlined,
                                            color: isActive
                                                ? AppTheme.hadirColor
                                                : AppTheme.primaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      session.subject ?? 'Presensi Harian',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                        color:
                                                            AppTheme.textColor,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: isActive
                                                          ? AppTheme.hadirColor
                                                              .withOpacity(0.15)
                                                          : Colors.grey
                                                              .shade200,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(
                                                      isActive
                                                          ? 'Sesi Buka'
                                                          : 'Ditutup',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isActive
                                                            ? AppTheme.hadirColor
                                                            : Colors.grey
                                                                .shade700,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Guru: $teacherName Tanggal: ${session.date} (${session.timeStart})',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppTheme.primaryColor,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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

      piketProvider.fetchSessions();

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
    final piketProvider = context.watch<PiketProvider>();
    final mapelProvider = context.watch<MapelProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final teacherUid = authProvider.currentUser?.uid ?? '';

    // Hitung metrik Guru Piket
    final totalSessions = piketProvider.sessions.length;
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
              onRefresh: () async {
                await mapelProvider.fetchSessions(teacherUid);
                await Provider.of<PiketProvider>(context, listen: false).fetchSessions();
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

                    // Ringkasan Statistik Guru Piket/Wali Kelas
                    Text(
                      authProvider.currentUser?.role == 'guru_piket'
                          ? 'Overview Presensi Guru Piket'
                          : 'Overview Presensi Wali Kelas',
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
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: const Text('Buka Presensi Harian'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.piketOpenSession,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.history_rounded, size: 18),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Riwayat Presensi'),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  side: const BorderSide(
                                    color: AppTheme.primaryColor,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 8,
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
                            if (authProvider.currentUser?.role == 'guru_piket') ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.view_week_outlined, size: 18),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Rekap Mingguan'),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    side: const BorderSide(
                                      color: AppTheme.primaryColor,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.piketWeeklyRecap,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
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
                    const SizedBox(height: 24),

                    // Riwayat Sesi Presensi Terbaru (Langsung di Dashboard)
                    Builder(
                      builder: (context) {
                        final piketProvider = context.watch<PiketProvider>();
                        final mapelProvider = context.watch<MapelProvider>();

                        final allSessionsMap = <String, SessionModel>{};
                        for (var s in piketProvider.sessions) {
                          allSessionsMap[s.id] = s;
                        }
                        for (var s in mapelProvider.sessions) {
                          allSessionsMap[s.id] = s;
                        }
                        final currentUid = authProvider.currentUser?.uid ?? '';
                        final now = DateTime.now();
                        final todayYMD =
                            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                        final todayDMY =
                            "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

                        final recentSessions = allSessionsMap.values.where((s) {
                          if (s.createdBy != currentUid) return false;
                          final d = s.date.trim();
                          if (d == todayYMD || d == todayDMY) return true;
                          try {
                            if (d.contains('-')) {
                              final parts = d.split('-');
                              if (parts[0].length == 4) {
                                final yr = int.parse(parts[0]);
                                final mo = int.parse(parts[1]);
                                final dy = int.parse(parts[2]);
                                return yr == now.year &&
                                    mo == now.month &&
                                    dy == now.day;
                              } else {
                                final dy = int.parse(parts[0]);
                                final mo = int.parse(parts[1]);
                                final yr = int.parse(parts[2]);
                                return yr == now.year &&
                                    mo == now.month &&
                                    dy == now.day;
                              }
                            }
                          } catch (_) {}
                          return true;
                        }).toList();
                        recentSessions.sort((a, b) => b.id.compareTo(a.id));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Riwayat Sesi Saya Hari Ini',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: const Color(0xFF2D3142),
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/guru/history'),
                                  child: const Text('Lihat Semua'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            recentSessions.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: Text(
                                        'Belum ada sesi presensi yang dibuka.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: recentSessions.length > 5
                                        ? 5
                                        : recentSessions.length,
                                    itemBuilder: (context, index) {
                                      final session = recentSessions[index];
                                      final isActive = session.status == 'active';

                                      String className = 'Kelas';
                                      try {
                                        final cls = adminProvider.classes.firstWhere(
                                          (c) =>
                                              c.id == session.classId ||
                                              c.name == session.classId,
                                        );
                                        className = cls.name;
                                      } catch (_) {
                                        className = session.classId;
                                      }

                                      String teacherName = 'Guru';
                                      try {
                                        final teacher = adminProvider.users.firstWhere(
                                          (u) => u.uid == session.createdBy,
                                        );
                                        teacherName = teacher.name;
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
                                            if (session.type == 'mapel') {
                                              Navigator.pushNamed(
                                                context,
                                                AppRoutes.mapelAttendance,
                                                arguments: {
                                                  'session_id': session.id,
                                                  'class_id': session.classId,
                                                  'class_name': className,
                                                  'subject':
                                                      session.subject ?? 'Presensi',
                                                  'status': session.status,
                                                  'auto_scan': false,
                                                },
                                              );
                                            } else {
                                              Navigator.pushNamed(
                                                context,
                                                AppRoutes.piketValidate,
                                                arguments: {
                                                  'session_id': session.id,
                                                  'class_id': session.classId,
                                                  'class_name': className,
                                                  'status': session.status,
                                                  'auto_scan': false,
                                                },
                                              );
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: isActive
                                                        ? AppTheme.hadirColor
                                                        : AppTheme.primaryColor
                                                            .withOpacity(0.12),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    session.type == 'mapel'
                                                        ? Icons.menu_book_rounded
                                                        : Icons.badge_outlined,
                                                    color: isActive
                                                        ? Colors.white
                                                        : AppTheme.primaryColor,
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
                                                        'Kelas $className ${session.subject ?? "Presensi Harian"}',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                          color: AppTheme.textColor,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Guru: $teacherName Tanggal: ${session.date} (${session.timeStart})',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey.shade600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isActive
                                                        ? AppTheme.hadirColor
                                                            .withOpacity(0.15)
                                                        : Colors.grey.shade200,
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    isActive ? 'Aktif' : 'Tutup',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: isActive
                                                          ? AppTheme.hadirColor
                                                          : Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
                    // Sesi Presensi Harian Section (Per Kelas)
                    Builder(
                      builder: (context) {
                        final piketProvider = context.watch<PiketProvider>();
                        final classes = adminProvider.classes;

                        if (authProvider.currentUser?.role != 'guru_piket' &&
                            authProvider.currentUser?.role != 'guru_wali_kelas') {
                          return const SizedBox.shrink();
                        }

                        List<ClassModel> displayClasses = classes;

                        const title = 'Sesi Presensi Per Kelas Hari Ini (Seluruh Guru)';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2D3142),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            displayClasses.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Text(
                                        'Belum ada data kelas terdaftar.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: displayClasses.length,
                                    itemBuilder: (context, index) {
                                      final cls = displayClasses[index];
                                      final allSessionsMap = <String, SessionModel>{};
                                      for (var s in piketProvider.sessions) {
                                        allSessionsMap[s.id] = s;
                                      }
                                      for (var s in mapelProvider.sessions) {
                                        allSessionsMap[s.id] = s;
                                      }

                                      final now = DateTime.now();
                                      final todayYMD =
                                          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                                      final todayDMY =
                                          "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

                                      final allSessionsList =
                                          allSessionsMap.values.where((s) {
                                        final d = s.date.trim();
                                        if (d == todayYMD || d == todayDMY) {
                                          return true;
                                        }
                                        try {
                                          if (d.contains('-')) {
                                            final parts = d.split('-');
                                            if (parts[0].length == 4) {
                                              final yr = int.parse(parts[0]);
                                              final mo = int.parse(parts[1]);
                                              final dy = int.parse(parts[2]);
                                              return yr == now.year &&
                                                  mo == now.month &&
                                                  dy == now.day;
                                            } else {
                                              final dy = int.parse(parts[0]);
                                              final mo = int.parse(parts[1]);
                                              final yr = int.parse(parts[2]);
                                              return yr == now.year &&
                                                  mo == now.month &&
                                                  dy == now.day;
                                            }
                                          }
                                        } catch (_) {}
                                        return true;
                                      }).toList();

                                      final sessionsForClass =
                                          allSessionsList.where((s) {
                                        if (s.classId == cls.id ||
                                            s.classId == cls.name) return true;
                                        final sClean = s.classId
                                            .toLowerCase()
                                            .replaceAll('class-', '')
                                            .replaceAll('kelas', '')
                                            .trim();
                                        final cIdClean = cls.id
                                            .toLowerCase()
                                            .replaceAll('class-', '')
                                            .replaceAll('kelas', '')
                                            .trim();
                                        final cNameClean = cls.name
                                            .toLowerCase()
                                            .replaceAll('kelas', '')
                                            .trim();
                                        return sClean == cIdClean ||
                                            sClean == cNameClean;
                                      }).toList();
                                      final hasActiveSession = sessionsForClass
                                          .any((s) => s.status == 'active');

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
                                          onTap: () => _showClassSessionsModal(
                                              context, cls, sessionsForClass),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: hasActiveSession
                                                        ? AppTheme.hadirColor
                                                        : AppTheme.primaryColor
                                                            .withOpacity(0.12),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.class_outlined,
                                                    color: hasActiveSession
                                                        ? Colors.white
                                                        : AppTheme.primaryColor,
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
                                                        'Kelas ${cls.name}',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          color: AppTheme.textColor,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '${sessionsForClass.length} Sesi Presensi Guru' +
                                                            (hasActiveSession
                                                                ? ' (Ada Sesi Buka)'
                                                                : ''),
                                                        style: TextStyle(
                                                          color: hasActiveSession
                                                              ? AppTheme.hadirColor
                                                              : Colors.grey.shade600,
                                                          fontSize: 12,
                                                          fontWeight: hasActiveSession
                                                              ? FontWeight.bold
                                                              : FontWeight.normal,
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
                                      );
                                    },
                                  ),
                          ],
                        );
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

                        // Logika Filter Tanggal
                        final now = DateTime.now();
                        final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                        
                        final filteredRequests = piketProvider.classLeaveRequests.where((req) {
                          if (_dateFilter == 'Hari Ini') {
                            return req.date == todayStr;
                          } else if (_dateFilter == 'Pilih Tanggal' && _customFilterDate != null) {
                            final selectedStr = "${_customFilterDate!.year}-${_customFilterDate!.month.toString().padLeft(2, '0')}-${_customFilterDate!.day.toString().padLeft(2, '0')}";
                            return req.date == selectedStr;
                          }
                          return true; // 'Semua'
                        }).toList();
                        
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
                            // Filter UI
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('Hari Ini', _dateFilter == 'Hari Ini', () {
                                    setState(() {
                                      _dateFilter = 'Hari Ini';
                                    });
                                  }),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    _dateFilter == 'Pilih Tanggal' && _customFilterDate != null
                                        ? "${_customFilterDate!.day}/${_customFilterDate!.month}/${_customFilterDate!.year}"
                                        : 'Pilih Tanggal',
                                    _dateFilter == 'Pilih Tanggal',
                                    () => _selectFilterDate(context),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Semua', _dateFilter == 'Semua', () {
                                    setState(() {
                                      _dateFilter = 'Semua';
                                    });
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            filteredRequests.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _dateFilter == 'Hari Ini'
                                          ? 'Belum ada pengajuan izin hari ini.'
                                          : _dateFilter == 'Pilih Tanggal'
                                              ? 'Belum ada pengajuan izin untuk tanggal terpilih.'
                                              : 'Belum ada pengajuan izin dari siswa Anda.',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredRequests.length,
                                    itemBuilder: (context, idx) {
                                      final req = filteredRequests[idx];
                                      
                                      UserModel? studentUser;
                                      try {
                                        studentUser = adminProvider.users.firstWhere((u) => u.uid == req.studentId);
                                      } catch (_) {}
                                      final studentName = studentUser?.name ?? 'Siswa';
                                      
                                      final isSakit = req.status.toLowerCase() == 'sakit';
                                      final statusColor = isSakit ? AppTheme.sakitColor : AppTheme.izinColor;
                                      
                                      // Dapatkan status presensi saat ini
                                      final sessionId = 'SESS-HARIAN-${myClass!.id}-${req.date}';
                                      final attendance = piketProvider.leavesAttendances[sessionId]?[req.studentId];
                                      final displayStatus = attendance?.status ?? req.status;

                                      Color attColor;
                                      String attLabel;
                                      switch (displayStatus.toLowerCase()) {
                                        case 'hadir':
                                          attColor = AppTheme.hadirColor;
                                          attLabel = 'Hadir';
                                          break;
                                        case 'izin':
                                          attColor = AppTheme.izinColor;
                                          attLabel = 'Izin';
                                          break;
                                        case 'sakit':
                                          attColor = AppTheme.sakitColor;
                                          attLabel = 'Sakit';
                                          break;
                                        case 'alpa':
                                        default:
                                          attColor = AppTheme.alpaColor;
                                          attLabel = 'Alpa';
                                          break;
                                      }
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: ListTile(
                                          onTap: () {
                                            if (studentUser != null) {
                                              _showChangeAttendanceDialog(
                                                context: context,
                                                student: studentUser,
                                                classId: myClass!.id,
                                                date: req.date,
                                                currentStatus: displayStatus,
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Data siswa tidak ditemukan.')),
                                              );
                                            }
                                          },
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
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: attColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: attColor.withOpacity(0.3), width: 1),
                                                ),
                                                child: Text(
                                                  attLabel,
                                                  style: TextStyle(
                                                    color: attColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.edit_outlined,
                                                size: 16,
                                                color: Colors.grey.shade400,
                                              ),
                                            ],
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

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textMutedColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (label == 'Pilih Tanggal' || (isSelected && _dateFilter == 'Pilih Tanggal')) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: isSelected ? Colors.white : AppTheme.textMutedColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showChangeAttendanceDialog({
    required BuildContext context,
    required UserModel student,
    required String classId,
    required String date,
    required String currentStatus,
  }) {
    final piketProvider = Provider.of<PiketProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Ubah Presensi: ${student.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubah status presensi untuk tanggal $date.',
                style: const TextStyle(color: AppTheme.textMutedColor, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildAttendanceOptionTile(
                context,
                label: 'Hadir',
                color: AppTheme.hadirColor,
                isSelected: currentStatus.toLowerCase() == 'hadir',
                onTap: () => _updateAttendance(context, piketProvider, student.uid, classId, date, 'hadir', authProvider.currentUser!.uid),
              ),
              const SizedBox(height: 8),
              _buildAttendanceOptionTile(
                context,
                label: 'Izin',
                color: AppTheme.izinColor,
                isSelected: currentStatus.toLowerCase() == 'izin',
                onTap: () => _updateAttendance(context, piketProvider, student.uid, classId, date, 'izin', authProvider.currentUser!.uid),
              ),
              const SizedBox(height: 8),
              _buildAttendanceOptionTile(
                context,
                label: 'Sakit',
                color: AppTheme.sakitColor,
                isSelected: currentStatus.toLowerCase() == 'sakit',
                onTap: () => _updateAttendance(context, piketProvider, student.uid, classId, date, 'sakit', authProvider.currentUser!.uid),
              ),
              const SizedBox(height: 8),
              _buildAttendanceOptionTile(
                context,
                label: 'Alpa',
                color: AppTheme.alpaColor,
                isSelected: currentStatus.toLowerCase() == 'alpa',
                onTap: () => _updateAttendance(context, piketProvider, student.uid, classId, date, 'alpa', authProvider.currentUser!.uid),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceOptionTile(
    BuildContext context, {
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAttendance(
    BuildContext context,
    PiketProvider piketProvider,
    String studentId,
    String classId,
    String date,
    String status,
    String recorderUid,
  ) async {
    Navigator.pop(context); // Tutup dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memperbarui presensi...')),
    );
    try {
      await piketProvider.updateAttendanceForLeaveRequest(
        studentId: studentId,
        classId: classId,
        date: date,
        status: status,
        recorderUid: recorderUid,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presensi berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui presensi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
