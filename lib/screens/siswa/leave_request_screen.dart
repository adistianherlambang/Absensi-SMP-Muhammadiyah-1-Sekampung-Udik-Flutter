import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/siswa_provider.dart';
import '../../models/leave_request_model.dart';
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
  String _selectedStatus = 'izin';

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
        status: _selectedStatus,
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
      case 'sakit':
        color = AppTheme.sakitColor;
        icon = Icons.warning_amber_outlined;
        label = 'Sakit';
        break;
      case 'izin':
      default:
        color = AppTheme.izinColor;
        icon = Icons.info_outline;
        label = 'Izin';
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

  Future<void> _confirmDeleteLeave(LeaveRequestModel req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengajuan'),
        content: Text('Apakah Anda yakin ingin menghapus pengajuan izin untuk tanggal ${req.date}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final siswaProvider = Provider.of<SiswaProvider>(context, listen: false);

      try {
        await siswaProvider.deleteLeaveRequest(
          requestId: req.id,
          studentId: authProvider.currentUser!.uid,
          date: req.date,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan izin berhasil dihapus!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus pengajuan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditLeaveDialog(LeaveRequestModel req) async {
    final editFormKey = GlobalKey<FormState>();
    final editReasonController = TextEditingController(text: req.reason);
    DateTime editDate;
    try {
      editDate = DateTime.parse(req.date);
    } catch (_) {
      editDate = DateTime.now();
    }
    String editStatus = req.status;

    Future<void> selectEditDate(BuildContext context, StateSetter setState) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: editDate,
        firstDate: DateTime.now().subtract(const Duration(days: 7)),
        lastDate: DateTime.now().add(const Duration(days: 30)),
      );
      if (picked != null) {
        setState(() {
          editDate = picked;
        });
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final formattedDate = "${editDate.day}/${editDate.month}/${editDate.year}";

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: editFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Edit Pengajuan Izin',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textColor),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      title: const Text('Tanggal Izin'),
                      subtitle: Text(formattedDate),
                      trailing: const Icon(Icons.calendar_month),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () => selectEditDate(context, setModalState),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih Status Kehadiran',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textColor),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: editStatus,
                      items: const [
                        DropdownMenuItem(value: 'izin', child: Text('Izin')),
                        DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            editStatus = val;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: editReasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Alasan Tidak Hadir',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Masukkan alasan Anda' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (!editFormKey.currentState!.validate()) return;
                        Navigator.pop(context);

                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final siswaProvider = Provider.of<SiswaProvider>(context, listen: false);

                        final newDateStr = "${editDate.year}-${editDate.month.toString().padLeft(2, '0')}-${editDate.day.toString().padLeft(2, '0')}";

                        try {
                          await siswaProvider.editLeaveRequest(
                            requestId: req.id,
                            studentId: authProvider.currentUser!.uid,
                            oldDate: req.date,
                            newDate: newDateStr,
                            reason: editReasonController.text.trim(),
                            status: editStatus,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pengajuan izin berhasil diubah!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal mengubah pengajuan: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Simpan Perubahan'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
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
          : RefreshIndicator(
              onRefresh: () => siswaProvider.fetchLeaveRequests(authProvider.currentUser!.uid),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
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
                            const Text(
                              'Pilih Status Kehadiran',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textColor),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              items: const [
                                DropdownMenuItem(value: 'izin', child: Text('Izin')),
                                DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedStatus = val;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
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
                  siswaProvider.leaveRequests.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0),
                            child: Text('Belum ada pengajuan izin sebelumnya.'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildStatusWidget(req.status),
                                    const SizedBox(width: 4),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textMutedColor),
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          _showEditLeaveDialog(req);
                                        } else if (action == 'delete') {
                                          _confirmDeleteLeave(req);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 16, color: AppTheme.primaryColor),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, size: 16, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Hapus', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
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
    );
  }
}
