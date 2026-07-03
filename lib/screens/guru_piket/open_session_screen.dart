import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/piket_provider.dart';
import '../../providers/admin_provider.dart';

class OpenSessionScreen extends StatefulWidget {
  const OpenSessionScreen({super.key});

  @override
  State<OpenSessionScreen> createState() => _OpenSessionScreenState();
}

class _OpenSessionScreenState extends State<OpenSessionScreen> {
  String? _selectedClassId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    if (_selectedClassId == null && adminProvider.classes.isNotEmpty) {
      _selectedClassId = adminProvider.classes.first.id;
    }
  }

  Future<void> _handleOpenSession() async {
    if (_selectedClassId == null) return;

    final piketProvider = Provider.of<PiketProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await piketProvider.openHarianSession(_selectedClassId!, authProvider.currentUser!.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi presensi harian berhasil dibuka!')),
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
    final piketProvider = context.watch<PiketProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buka Sesi Presensi'),
      ),
      body: piketProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.add_alarm,
                    size: 80,
                    color: Color(0xFF2C5E8A),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Buka Sesi Presensi Harian Baru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sesi ini memungkinkan siswa memindai QR Code untuk presensi mandiri atau diinput manual oleh Guru Piket.',
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
                    DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Kelas',
                        prefixIcon: Icon(Icons.class_outlined),
                      ),
                      items: adminProvider.classes.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedClassId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _handleOpenSession,
                      child: const Text('Buka Sesi Sekarang'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
