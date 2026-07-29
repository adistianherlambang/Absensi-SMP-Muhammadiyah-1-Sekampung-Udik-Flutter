import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mapel_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/searchable_select.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';

class OpenMapelSessionScreen extends StatefulWidget {
  const OpenMapelSessionScreen({super.key});

  @override
  State<OpenMapelSessionScreen> createState() => _OpenMapelSessionScreenState();
}

class _OpenMapelSessionScreenState extends State<OpenMapelSessionScreen> {
  String? _selectedClassId;
  String? _selectedSubject;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_selectedClassId == null && adminProvider.classes.isNotEmpty) {
      _selectedClassId = adminProvider.classes.first.id;
    }

    final subjects = authProvider.currentUser?.subjects ?? [];
    if (_selectedSubject == null && subjects.isNotEmpty) {
      _selectedSubject = subjects.first;
    }
  }

  Future<void> _handleOpenSession() async {
    if (_selectedClassId == null || _selectedSubject == null) return;

    final mapelProvider = Provider.of<MapelProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final className = adminProvider.classes.firstWhere((c) => c.id == _selectedClassId).name;

      final sessionId = await mapelProvider.openMapelSession(
        classId: _selectedClassId!,
        subject: _selectedSubject!,
        creatorUid: authProvider.currentUser!.uid,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi presensi mata pelajaran berhasil dibuka & dicatat ke histori!')),
      );

      // Navigasi langsung ke layar presensi & scan QR siswa
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.mapelAttendance,
        arguments: {
          'session_id': sessionId,
          'class_id': _selectedClassId!,
          'class_name': className,
          'subject': _selectedSubject!,
          'status': 'active',
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka sesi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();
    final mapelProvider = context.watch<MapelProvider>();

    final subjects = authProvider.currentUser?.subjects ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buka Sesi Presensi Pelajaran'),
      ),
      body: mapelProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.school_rounded,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Buka Sesi Presensi Kelas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih kelas dan mata pelajaran. Sesi akan langsung dicatat ke histori database dengan status default Tidak Hadir (Alpa) untuk seluruh siswa di kelas tersebut.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMutedColor),
                  ),
                  const SizedBox(height: 32),
                  if (adminProvider.classes.isEmpty)
                    const Text(
                      'Tidak ada kelas terdaftar di sistem. Hubungi administrator.',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    // Dropdown Kelas
                    SearchableSelect<dynamic>(
                      labelText: 'Pilih Kelas',
                      items: adminProvider.classes,
                      itemLabel: (c) => c.name as String,
                      selectedValue: _selectedClassId != null
                          ? adminProvider.classes.firstWhere((c) => c.id == _selectedClassId, orElse: () => adminProvider.classes.first)
                          : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedClassId = val?.id;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Mata Pelajaran
                    if (subjects.isEmpty)
                      const Text(
                        'Peringatan: Anda belum terdaftar mengampu mata pelajaran apa pun. Hubungi admin.',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      )
                    else
                      SearchableSelect<String>(
                        labelText: 'Pilih Mata Pelajaran',
                        items: subjects,
                        itemLabel: (s) => s,
                        selectedValue: _selectedSubject,
                        onChanged: (val) {
                          setState(() {
                            _selectedSubject = val;
                          });
                        },
                      ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Buka Sesi & Mulai Scan QR Siswa'),
                      onPressed: subjects.isEmpty ? null : _handleOpenSession,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
