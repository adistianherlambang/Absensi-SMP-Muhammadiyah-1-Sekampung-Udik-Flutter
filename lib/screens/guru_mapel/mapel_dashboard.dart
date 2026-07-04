import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mapel_provider.dart';
import '../../providers/admin_provider.dart';
import '../../app/routes.dart';
import '../../widgets/glass_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MapelDashboard extends StatefulWidget {
  const MapelDashboard({super.key});

  @override
  State<MapelDashboard> createState() => _MapelDashboardState();
}

class _MapelDashboardState extends State<MapelDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<MapelProvider>(context, listen: false).fetchSessions(authProvider.currentUser!.uid);
      Provider.of<AdminProvider>(context, listen: false).fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final mapelProvider = context.watch<MapelProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final teacherUid = authProvider.currentUser?.uid ?? '';

    // Hitung metrik Guru Mapel
    final totalSessions = mapelProvider.sessions.length;
    final activeSessionsCount = mapelProvider.sessions.where((s) => s.status == 'active').length;
    final totalClasses = mapelProvider.sessions.map((s) => s.classId).toSet().length;
    final subjectCount = authProvider.currentUser?.subjects?.length ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Dashboard Guru Mapel', style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold)),
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
          )
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
                    // Banner Sambutan (GlassCard)
                    GlassCard(
                      shadowColor: const Color(0xFF6849EF),
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6849EF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 40,
                              color: Color(0xFF6849EF),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selamat Datang, Guru Mapel!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authProvider.currentUser?.name ?? '',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                if (authProvider.currentUser?.subjects != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mengampu: ${authProvider.currentUser!.subjects!.join(', ')}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: 0.05, end: 0, duration: 300.ms).fadeIn(),
                    const SizedBox(height: 24),

                    // Ringkasan Statistik Guru Mapel
                    Text(
                      'Overview Pengajaran',
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
                              Expanded(child: _buildStatItem('Sesi Mapel', '$totalSessions', const Color(0xFF6849EF))),
                              Container(width: 1, height: 40, color: Colors.grey.shade200),
                              Expanded(child: _buildStatItem('Sesi Aktif', '$activeSessionsCount', Colors.green)),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Colors.grey.shade200, height: 1),
                          ),
                          Row(
                            children: [
                              Expanded(child: _buildStatItem('Kelas Diajar', '$totalClasses Kelas', Colors.blue)),
                              Container(width: 1, height: 40, color: Colors.grey.shade200),
                              Expanded(child: _buildStatItem('Mapel Diampu', '$subjectCount Mapel', Colors.orange)),
                            ],
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: 0.05, end: 0, duration: 300.ms).fadeIn(),
                    const SizedBox(height: 24),

                    // Tombol Buka Sesi Baru
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Buka Sesi Presensi Mapel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6849EF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.mapelOpenSession);
                      },
                    ).animate().slideY(begin: 0.05, end: 0, duration: 300.ms, delay: 50.ms).fadeIn(),
                    const SizedBox(height: 32),

                    // Daftar Sesi
                    Text(
                      'Sesi Presensi Mapel Terbuka',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3142),
                          ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 16),
                    mapelProvider.sessions.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'Belum ada sesi presensi mata pelajaran.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: mapelProvider.sessions.length,
                            itemBuilder: (context, index) {
                              final session = mapelProvider.sessions[index];
                              final isActive = session.status == 'active';
                              final color = isActive ? Colors.green : Colors.grey;

                              // Ambil nama kelas
                              String className = 'Tidak diketahui';
                              try {
                                final cls = adminProvider.classes.firstWhere((c) => c.id == session.classId);
                                className = cls.name;
                              } catch (_) {}

                              return GlassCard(
                                shadowColor: color,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(8.0),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.mapelAttendance,
                                    arguments: {
                                      'session_id': session.id,
                                      'class_id': session.classId,
                                      'class_name': className,
                                      'subject': session.subject,
                                      'status': session.status,
                                    },
                                  );
                                },
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isActive ? Icons.play_arrow_rounded : Icons.lock_rounded,
                                      color: color,
                                    ),
                                  ),
                                  title: Text(
                                    'Kelas $className — ${session.subject}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('Tanggal: ${session.date}', style: TextStyle(color: Colors.grey.shade600)),
                                      Text('Mulai: ${session.timeStart} ${session.timeEnd != null ? " s/d " + session.timeEnd! : ""}', style: TextStyle(color: Colors.grey.shade600)),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isActive ? 'SESI AKTIF' : 'DITUTUP',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                ),
                              ).animate().slideY(begin: 0.05, end: 0, duration: 300.ms).fadeIn();
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
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
