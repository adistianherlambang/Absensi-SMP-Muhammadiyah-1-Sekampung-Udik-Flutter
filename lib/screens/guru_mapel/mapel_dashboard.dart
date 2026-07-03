import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mapel_provider.dart';
import '../../providers/admin_provider.dart';
import '../../app/routes.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Guru Mapel'),
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Sambutan
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    authProvider.currentUser?.name ?? '',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  if (authProvider.currentUser?.subjects != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Mengampu: ${authProvider.currentUser!.subjects!.join(', ')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                                      ),
                                    )
                                  ]
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Buka Sesi Baru
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Buka Sesi Presensi Mapel'),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.mapelOpenSession);
                      },
                    ),
                    const SizedBox(height: 32),

                    // Daftar Sesi
                    Text(
                      'Sesi Presensi Mapel Terbuka',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    mapelProvider.sessions.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text('Belum ada sesi presensi mata pelajaran.'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: mapelProvider.sessions.length,
                            itemBuilder: (context, index) {
                              final session = mapelProvider.sessions[index];
                              final isActive = session.status == 'active';

                              // Ambil nama kelas
                              String className = 'Tidak diketahui';
                              try {
                                final cls = adminProvider.classes.firstWhere((c) => c.id == session.classId);
                                className = cls.name;
                              } catch (_) {}

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isActive
                                        ? Colors.green.shade50
                                        : Colors.grey.shade100,
                                    child: Icon(
                                      isActive ? Icons.play_arrow_outlined : Icons.lock_outline,
                                      color: isActive ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                  title: Text(
                                    'Kelas $className — ${session.subject}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Tanggal: ${session.date}'),
                                      Text('Mulai: ${session.timeStart} ${session.timeEnd != null ? " s/d " + session.timeEnd! : ""}'),
                                      const SizedBox(height: 4),
                                      Text(
                                        isActive ? 'Status: Sesi Aktif' : 'Status: Ditutup',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isActive ? Colors.green : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
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
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
