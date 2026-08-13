import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mapel_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/searchable_select.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';

class OpenSessionScreen extends StatefulWidget {
  const OpenSessionScreen({super.key});

  @override
  State<OpenSessionScreen> createState() => _OpenSessionScreenState();
}

class _OpenSessionScreenState extends State<OpenSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClassId;
  final TextEditingController _subjectController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_selectedClassId == null && adminProvider.classes.isNotEmpty) {
      _selectedClassId = adminProvider.classes.first.id;
    }

    if (_subjectController.text.isEmpty) {
      final subjects = authProvider.currentUser?.subjects ?? [];
      if (subjects.isNotEmpty) {
        _subjectController.text = subjects.first;
      } else {
        _subjectController.text = 'Presensi Harian';
      }
    }
  }

  Future<void> _handleOpenSession() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kelas terlebih dahulu!')),
      );
      return;
    }

    final mapelProvider = Provider.of<MapelProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final className = adminProvider.classes
          .firstWhere((c) => c.id == _selectedClassId)
          .name;
      final subjectText = _subjectController.text.trim();

      final sessionId = await mapelProvider.openMapelSession(
        classId: _selectedClassId!,
        subject: subjectText,
        creatorUid: authProvider.currentUser!.uid,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi presensi harian berhasil dibuka!'),
        ),
      );

      // Navigasi langsung ke layar presensi & otomatis buka QR Scanner Kamera
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.mapelAttendance,
        arguments: {
          'session_id': sessionId,
          'class_id': _selectedClassId!,
          'class_name': className,
          'subject': subjectText,
          'status': 'active',
          'auto_scan': true,
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

    final userSubjects = authProvider.currentUser?.subjects ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buka Presensi Harian'),
      ),
      body: mapelProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Buka Presensi Harian',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih kelas dan masukkan mata pelajaran, lalu tekan Buka Sesi Sekarang untuk langsung menuju ke scanner QR code.',
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
                      // Dropdown Pilih Kelas
                      SearchableSelect<dynamic>(
                        labelText: 'Pilih Kelas',
                        items: adminProvider.classes,
                        itemLabel: (c) => c.name as String,
                        selectedValue: _selectedClassId != null
                            ? adminProvider.classes.firstWhere(
                                (c) => c.id == _selectedClassId,
                                orElse: () => adminProvider.classes.first,
                              )
                            : null,
                        onChanged: (val) {
                          setState(() {
                            _selectedClassId = val?.id;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Input Mata Pelajaran
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          labelText: 'Mata Pelajaran',
                          hintText:
                              'Contoh: Matematika, IPA, atau Presensi Harian',
                          prefixIcon: const Icon(
                            Icons.menu_book_rounded,
                            color: AppTheme.primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Mata pelajaran tidak boleh kosong'
                            : null,
                      ),

                      // Choice Chips untuk Mapel terdaftar jika ada
                      if (userSubjects.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: userSubjects.map((subj) {
                            final isSelected =
                                _subjectController.text.trim() == subj;
                            return ChoiceChip(
                              label: Text(subj),
                              selected: isSelected,
                              selectedColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _subjectController.text = subj;
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 36),

                      // Tombol Buka Sesi Sekarang
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Buka Sesi Sekarang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: _handleOpenSession,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
