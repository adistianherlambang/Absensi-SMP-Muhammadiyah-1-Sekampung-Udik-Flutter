import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/siswa_provider.dart';
import '../../app/theme.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<SiswaProvider>(context, listen: false)
          .fetchAttendanceHistory(authProvider.currentUser!.uid);
    });
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
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final siswaProvider = context.watch<SiswaProvider>();
    final authProvider = context.watch<AuthProvider>();

    final historyList = siswaProvider.history.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Kehadiran Saya'),
      ),
      body: siswaProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => siswaProvider.fetchAttendanceHistory(authProvider.currentUser!.uid),
              child: historyList.isEmpty
                  ? const Center(child: Text('Belum ada riwayat kehadiran tercatat.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: historyList.length,
                      itemBuilder: (context, index) {
                        final entry = historyList[index];
                        final sessionId = entry.key;
                        final attendance = entry.value;

                        // Tentukan jenis sesi (Harian / Mapel) dari ID sesi
                        final isMapel = sessionId.contains('MAPEL');
                        String title = isMapel ? 'Sesi Mapel' : 'Sesi Harian Kelas';
                        
                        // Parse nama mapel jika sesi mapel
                        if (isMapel) {
                          final parts = sessionId.split('-');
                          if (parts.length > 3) {
                            title = 'Sesi Mapel: ${parts[3].replaceAll('_', ' ')}';
                          }
                        }

                        // Format tanggal/waktu dari ISO
                        String dateStr = '';
                        try {
                          final dt = DateTime.parse(attendance.timestamp);
                          dateStr = '${dt.day}/${dt.month}/${dt.year} pukul ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                        } catch (_) {
                          dateStr = attendance.timestamp;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              isMapel ? Icons.menu_book : Icons.calendar_month,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Waktu: $dateStr'),
                                if (attendance.note != null) ...[
                                  const SizedBox(height: 2),
                                  Text('Catatan: ${attendance.note}'),
                                ],
                              ],
                            ),
                            trailing: _buildStatusWidget(attendance.status),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
