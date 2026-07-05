import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/searchable_select.dart';
import '../../app/theme.dart';

class GenerateQRScreen extends StatefulWidget {
  const GenerateQRScreen({super.key});

  @override
  State<GenerateQRScreen> createState() => _GenerateQRScreenState();
}

class _GenerateQRScreenState extends State<GenerateQRScreen> {
  String? _selectedClassId;

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    
    // Ambil kelas yang merupakan kelas 9 (dimulai dengan "IX" atau angka 9)
    final class9List = adminProvider.classes.where((c) {
      final nameUpper = c.name.toUpperCase();
      return nameUpper.startsWith('IX') || nameUpper.contains('9');
    }).toList();

    // Default select class jika belum dipilih
    if (_selectedClassId == null && class9List.isNotEmpty) {
      _selectedClassId = class9List.first.id;
    }

    // Ambil daftar siswa di kelas 9 terpilih
    final List<UserModel> class9Students = adminProvider.users.where((u) {
      return u.role == 'siswa' && u.classId == _selectedClassId;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Siswa Kelas 9'),
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dropdown pilih kelas 9
                  if (class9List.isEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Peringatan: Belum ada kelas 9 (berawalan "IX" atau mengandung "9") yang dibuat di sistem. Hubungi administrator/tambahkan kelas terlebih dahulu.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ),
                    )
                  else ...[
                    SearchableSelect<dynamic>(
                      labelText: 'Pilih Kelas 9',
                      items: class9List,
                      itemLabel: (c) => c.name as String,
                      selectedValue: _selectedClassId != null
                          ? class9List.firstWhere((c) => c.id == _selectedClassId, orElse: () => class9List.first)
                          : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedClassId = val?.id;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: class9Students.isEmpty
                          ? const Center(child: Text('Tidak ada siswa di kelas ini.'))
                          : ListView.builder(
                              itemCount: class9Students.length,
                              itemBuilder: (context, index) {
                                final student = class9Students[index];
                                final qrData = adminProvider.getStudentQRData(student);

                                 return Container(
                                   margin: const EdgeInsets.only(bottom: 12),
                                   decoration: BoxDecoration(
                                     color: Colors.white,
                                     borderRadius: BorderRadius.circular(20),
                                     border: Border.all(color: Colors.grey.shade200),
                                   ),
                                   child: ListTile(
                                     leading: Container(
                                       padding: const EdgeInsets.all(8),
                                       decoration: BoxDecoration(
                                         color: AppTheme.primaryColor.withOpacity(0.15),
                                         borderRadius: BorderRadius.circular(12),
                                       ),
                                       child: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
                                     ),
                                     title: Text(
                                       student.name,
                                       style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor),
                                     ),
                                     subtitle: Text('QR Code ID: ${student.qrCodeId ?? "Belum di-set"}', style: const TextStyle(color: AppTheme.textMutedColor)),
                                     trailing: TextButton.icon(
                                       icon: const Icon(Icons.qr_code, size: 20, color: AppTheme.primaryColor),
                                       label: const Text('Lihat QR', style: TextStyle(color: AppTheme.primaryColor)),
                                       onPressed: qrData.isEmpty
                                           ? null
                                           : () => _showQRDialog(student, qrData),
                                     ),
                                   ),
                                 );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _showQRDialog(UserModel student, String qrData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Text(
                student.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kartu QR Presensi SMPM 1',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ID: ${student.qrCodeId}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Simulasi pencetakan QR Code berhasil disiapkan.')),
                );
              },
              child: const Text('Cetak / Unduh'),
            ),
          ],
        );
      },
    );
  }
}
