import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/siswa_provider.dart';
import '../../app/theme.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<SiswaProvider>(context, listen: false)
          .fetchLeaveRequests(authProvider.currentUser!.uid);
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final siswaProvider = Provider.of<SiswaProvider>(context, listen: false);

    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    try {
      await siswaProvider.submitLeaveRequest(
        studentId: authProvider.currentUser!.uid,
        date: dateStr,
        reason: _reasonController.text.trim(),
      );

      _reasonController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Surat izin digital berhasil diajukan!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengajukan izin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusWidget(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        color = AppTheme.hadirColor;
        icon = Icons.check_circle_outline;
        label = 'Disetujui';
        break;
      case 'rejected':
        color = AppTheme.alpaColor;
        icon = Icons.cancel_outlined;
        label = 'Ditolak';
        break;
      case 'pending':
      default:
        color = AppTheme.sakitColor;
        icon = Icons.hourglass_empty;
        label = 'Menunggu';
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

    final dateStr = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Izin Digital'),
      ),
      body: siswaProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form pengajuan izin
                  Form(
                    key: _formKey,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Formulir Pengajuan Kehadiran',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              title: const Text('Tanggal Izin'),
                              subtitle: Text(dateStr),
                              trailing: const Icon(Icons.calendar_month),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onTap: () => _selectDate(context),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _reasonController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Alasan Tidak Hadir',
                                hintText: 'Contoh: Sakit demam/perjalanan keluarga...',
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Masukkan alasan Anda' : null,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _handleSubmitRequest,
                              child: const Text('Kirim Pengajuan'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Daftar izin terdahulu
                  const Text(
                    'Riwayat Pengajuan Izin',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => siswaProvider.fetchLeaveRequests(authProvider.currentUser!.uid),
                      child: siswaProvider.leaveRequests.isEmpty
                          ? const Center(
                              child: Text('Belum ada pengajuan izin sebelumnya.'),
                            )
                          : ListView.builder(
                              itemCount: siswaProvider.leaveRequests.length,
                              itemBuilder: (context, index) {
                                final req = siswaProvider.leaveRequests[index];

                                 return Container(
                                   margin: const EdgeInsets.only(bottom: 12),
                                   decoration: BoxDecoration(
                                     color: Colors.white,
                                     borderRadius: BorderRadius.circular(16),
                                     border: Border.all(color: Colors.grey.shade200),
                                   ),
                                   child: ListTile(
                                     title: Text(
                                       'Tanggal Izin: ${req.date}',
                                       style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor),
                                     ),
                                     subtitle: Text('Alasan: ${req.reason}', style: const TextStyle(color: AppTheme.textMutedColor)),
                                     trailing: _buildStatusWidget(req.status),
                                   ),
                                 );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
