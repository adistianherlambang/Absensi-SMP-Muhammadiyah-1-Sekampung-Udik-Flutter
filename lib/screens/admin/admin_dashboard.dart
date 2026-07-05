import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
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
          ),
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
                    // Custom Header
                    // Row(
                    //   children: [
                    //     CircleAvatar(
                    //       radius: 24,
                    //       backgroundColor: AppTheme.primaryColor.withOpacity(
                    //         0.2,
                    //       ),
                    //       child: Icon(
                    //         Icons.person_rounded,
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
                    //             authProvider.currentUser?.name ??
                    //                 'Admin Sekolah',
                    //             style: TextStyle(
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
                    Text(
                          'Kelola Sekolah dan Lihat Presensi Hari Ini',
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
                                  'Total User',
                                  '${adminProvider.users.length}',
                                  const Color(0xFF8E2DE2),
                                ),
                              ),
                              // Container(
                              //   width: 1,
                              //   height: 40,
                              //   color: Colors.grey.shade200,
                              // ),
                              Expanded(
                                child: _buildStatItem(
                                  'Total Kelas',
                                  '${adminProvider.classes.length}',
                                  const Color(0xFFF37335),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              color: Colors.grey.shade200,
                              height: 1,
                              indent: 80,
                              endIndent: 80,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'Siswa Terdaftar',
                                  '${adminProvider.users.where((u) => u.role == 'siswa').length}',
                                  const Color(0xFF00B4DB),
                                ),
                              ),
                              // Container(
                              //   width: 1,
                              //   height: 40,
                              //   color: Colors.grey.shade200,
                              // ),
                              Expanded(
                                child: _buildStatItem(
                                  'Guru / Staf',
                                  '${adminProvider.users.where((u) => u.role == 'guru_mapel' || u.role == 'guru_piket').length}',
                                  const Color(0xFFFF416C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: 0.05, end: 0, duration: 300.ms).fadeIn(),
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
                    _buildMenuCard(
                      context,
                      'Kelola Pengguna',
                      'Tambah, edit, dan kelola guru serta siswa secara massal',
                      Icons.manage_accounts_rounded,
                      AppRoutes.adminManageUsers,
                      AppTheme.primaryColor,
                      0,
                      isFullWidth: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMenuCard(
                            context,
                            'Kelola Kelas',
                            'Atur kelas & wali kelas',
                            Icons.door_sliding_rounded,
                            AppRoutes.adminManageClasses,
                            AppTheme.secondaryColor,
                            1,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMenuCard(
                            context,
                            'Laporan Presensi',
                            'Unduh rekap kehadiran',
                            Icons.summarize_rounded,
                            AppRoutes.adminReports,
                            AppTheme.blueColor,
                            2,
                          ),
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
                  color: Color(0xFF2D3142),
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

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String route,
    Color color,
    int index, {
    bool isFullWidth = false,
  }) {
    final cardContent = Padding(
      padding: const EdgeInsets.all(20.0),
      child: isFullWidth
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: color,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );

    return Container(
      height: isFullWidth ? 100 : 160,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          child: cardContent,
        ),
      ),
    )
        .animate()
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
          delay: Duration(milliseconds: index * 50),
        )
        .fadeIn();
  }
}
