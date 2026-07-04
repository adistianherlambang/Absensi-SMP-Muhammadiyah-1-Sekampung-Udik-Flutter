import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../app/routes.dart';
import '../../widgets/glass_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
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
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => adminProvider.fetchData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Sambutan
                    GlassCard(
                      shadowColor: const Color(0xFF6849EF),
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6849EF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
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
                                  'Selamat Datang, Admin!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authProvider.currentUser?.name ?? 'Admin Sekolah',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms).fadeIn(),
                    const SizedBox(height: 32),

                    // Ringkasan Statistik
                    Text(
                      'Statistik Sistem',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3142),
                          ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Total User',
                            '${adminProvider.users.length}',
                            Icons.people_alt_rounded,
                            const Color(0xFF8E2DE2),
                            0,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Total Kelas',
                            '${adminProvider.classes.length}',
                            Icons.class_rounded,
                            const Color(0xFFF37335),
                            1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Menu Navigasi
                    Text(
                      'Layanan Administrasi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3142),
                          ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                      children: [
                        _buildMenuCard(
                          context,
                          'Kelola Pengguna',
                          'Tambah & edit guru/siswa',
                          Icons.manage_accounts_rounded,
                          AppRoutes.adminManageUsers,
                          const Color(0xFF4A00E0),
                          0,
                        ),
                        _buildMenuCard(
                          context,
                          'Kelola Kelas',
                          'Atur kelas & wali kelas',
                          Icons.door_sliding_rounded,
                          AppRoutes.adminManageClasses,
                          const Color(0xFFFF416C),
                          1,
                        ),
                        _buildMenuCard(
                          context,
                          'Generate QR Siswa',
                          'Buat QR Code kelas IX',
                          Icons.qr_code_2_rounded,
                          AppRoutes.adminGenerateQR,
                          const Color(0xFFFDC830),
                          2,
                        ),
                        _buildMenuCard(
                          context,
                          'Laporan Presensi',
                          'Unduh rekap kehadiran',
                          Icons.summarize_rounded,
                          AppRoutes.adminReports,
                          const Color(0xFF00B4DB),
                          3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, int index) {
    return GlassCard(
      shadowColor: color,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms, delay: Duration(milliseconds: 100 + (index * 100))).fadeIn();
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String route,
    Color color,
    int index,
  ) {
    return GlassCard(
      shadowColor: color,
      onTap: () => Navigator.pushNamed(context, route),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms, delay: Duration(milliseconds: 200 + (index * 100))).fadeIn().scale(begin: const Offset(0.9, 0.9), delay: Duration(milliseconds: 200 + (index * 100)));
  }
}
