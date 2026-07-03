import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/siswa_provider.dart';
import '../../providers/admin_provider.dart';
import '../../app/routes.dart';

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

    // Ambil nama kelas siswa
    String className = 'Tidak terdaftar kelas';
    if (classId.isNotEmpty) {
      try {
        final cls = adminProvider.classes.firstWhere((c) => c.id == classId);
        className = 'Kelas ${cls.name}';
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dasbor Siswa'),
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kartu Profil Siswa (No badge style)
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 36,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? '',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    className,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
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
                            icon: const Icon(Icons.history),
                            label: const Text('Riwayat Hadir'),
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.siswaHistory);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.card_travel),
                            label: const Text('Ajukan Izin'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.siswaLeaveRequest);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Sesi Presensi Aktif
                    Text(
                      'Sesi Presensi Tersedia',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    siswaProvider.activeSessions.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'Tidak ada sesi presensi aktif untuk kelas Anda saat ini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: siswaProvider.activeSessions.length,
                            itemBuilder: (context, index) {
                              final session = siswaProvider.activeSessions[index];
                              final isMapel = session.type == 'mapel';

                              // Cek jika siswa sudah absen di sesi ini
                              final hasAttended = siswaProvider.history.containsKey(session.id);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isMapel ? Icons.book : Icons.alarm,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              isMapel
                                                  ? 'Presensi Mapel: ${session.subject}'
                                                  : 'Presensi Pagi (Harian Kelas)',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Tanggal: ${session.date}'),
                                      Text('Waktu Mulai: ${session.timeStart}'),
                                      const SizedBox(height: 16),
                                      hasAttended
                                          ? Text(
                                              'Anda Sudah Mengisi Presensi',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : ElevatedButton.icon(
                                              icon: const Icon(Icons.qr_code_scanner),
                                              label: const Text('Scan QR Code Kehadiran'),
                                              onPressed: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  AppRoutes.siswaScanQR,
                                                  arguments: {
                                                    'session_id': session.id,
                                                    'qr_id': user?.qrCodeId ?? '',
                                                  },
                                                );
                                              },
                                            ),
                                    ],
                                  ),
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
