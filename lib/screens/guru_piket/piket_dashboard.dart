import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/piket_provider.dart';
import '../../providers/admin_provider.dart';
import '../../app/routes.dart';

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
      Provider.of<PiketProvider>(context, listen: false).fetchSessions();
      Provider.of<AdminProvider>(context, listen: false).fetchData(); // Load classes info
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final piketProvider = context.watch<PiketProvider>();
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Guru Piket'),
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
      body: piketProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => piketProvider.fetchSessions(),
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
                              Icons.assignment_ind_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat Datang, Guru Piket!',
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_box_outlined),
                            label: const Text('Buka Sesi Harian'),
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.piketOpenSession);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.analytics_outlined),
                            label: const Text('Rekap Mingguan'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.piketWeeklyRecap);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Daftar Sesi Presensi Harian Aktif/Tutup
                    Text(
                      'Sesi Presensi Hari Ini',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    piketProvider.sessions.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text('Belum ada sesi presensi harian dibuka hari ini.'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: piketProvider.sessions.length,
                            itemBuilder: (context, index) {
                              final session = piketProvider.sessions[index];
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
                                      isActive ? Icons.alarm_on : Icons.alarm_off,
                                      color: isActive ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                  title: Text(
                                    'Kelas $className',
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
                                  trailing: Icon(isActive ? Icons.chevron_right : Icons.lock_outline),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.piketValidate,
                                      arguments: {
                                        'session_id': session.id,
                                        'class_id': session.classId,
                                        'class_name': className,
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
