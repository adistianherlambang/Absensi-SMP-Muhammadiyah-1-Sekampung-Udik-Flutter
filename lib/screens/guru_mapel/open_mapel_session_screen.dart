import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mapel_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/searchable_select.dart';

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await mapelProvider.openMapelSession(
        classId: _selectedClassId!,
        subject: _selectedSubject!,
        creatorUid: authProvider.currentUser!.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi presensi mata pelajaran berhasil dibuka!')),
      );
      Navigator.pop(context);
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
        title: const Text('Buka Sesi Mapel'),
      ),
      body: mapelProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.history_edu_outlined,
                    size: 80,
                    color: Color(0xFF2C5E8A),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Buka Sesi Presensi Mapel Baru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih kelas dan mata pelajaran yang sedang diampu untuk memulai pencatatan absensi jam pelajaran.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
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

                    // Dropdown Mata Pelajaran yang Diampu
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
                    ElevatedButton(
                      onPressed: subjects.isEmpty ? null : _handleOpenSession,
                      child: const Text('Buka Sesi Mapel Sekarang'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
