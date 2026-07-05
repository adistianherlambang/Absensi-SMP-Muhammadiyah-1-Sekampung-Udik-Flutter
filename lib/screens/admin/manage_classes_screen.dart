import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/searchable_select.dart';
import '../../app/theme.dart';

class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  String? _selectedTeacherId;

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  void _showAddClassDialog() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    _classNameController.clear();
    
    // Filter guru untuk dropdown wali kelas
    final teachers = adminProvider.users.where((u) => u.role == 'guru_piket' || u.role == 'guru_mapel').toList();
    setState(() {
      _selectedTeacherId = teachers.isNotEmpty ? teachers.first.uid : null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tambah Kelas Baru',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _classNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kelas',
                        hintText: 'Contoh: IX-A',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Nama kelas tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    if (teachers.isEmpty)
                      const Text(
                        'Peringatan: Belum ada guru terdaftar untuk dipilih sebagai Wali Kelas. Tambahkan guru terlebih dahulu.',
                        style: TextStyle(color: Colors.red),
                      )
                    else
                      SearchableSelect<dynamic>(
                        labelText: 'Wali Kelas',
                        items: teachers,
                        itemLabel: (t) => t.name as String,
                        selectedValue: _selectedTeacherId != null
                            ? teachers.firstWhere((t) => t.uid == _selectedTeacherId, orElse: () => teachers.first)
                            : null,
                        onChanged: (val) {
                          setModalState(() {
                            _selectedTeacherId = val?.uid;
                          });
                        },
                        validator: (v) => v == null ? 'Pilih wali kelas' : null,
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: teachers.isEmpty
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;

                              Navigator.pop(context);
                              try {
                                await adminProvider.createClass(
                                  _classNameController.text.trim(),
                                  _selectedTeacherId!,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Kelas berhasil ditambahkan!')),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal menambah kelas: $e')),
                                );
                              }
                            },
                      child: const Text('Simpan Kelas'),
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
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kelas'),
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => adminProvider.fetchData(),
              child: adminProvider.classes.isEmpty
                  ? const Center(child: Text('Tidak ada kelas.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: adminProvider.classes.length,
                      itemBuilder: (context, index) {
                        final cls = adminProvider.classes[index];

                        // Dapatkan nama wali kelas
                        String teacherName = 'Tidak ada';
                        try {
                          final teacher = adminProvider.users.firstWhere((u) => u.uid == cls.homeroomTeacherId);
                          teacherName = teacher.name;
                        } catch (_) {}

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
                               child: const Icon(Icons.meeting_room, color: AppTheme.primaryColor),
                             ),
                             title: Text(
                               cls.name,
                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textColor),
                             ),
                             subtitle: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 const SizedBox(height: 4),
                                 Text('Wali Kelas: $teacherName', style: const TextStyle(color: AppTheme.textMutedColor)),
                                 const SizedBox(height: 2),
                                 Text(
                                   'Jumlah Siswa: ${cls.studentIds.length}',
                                   style: const TextStyle(
                                     fontWeight: FontWeight.w600,
                                     color: AppTheme.primaryColor,
                                   ),
                                 ),
                               ],
                             ),
                             trailing: IconButton(
                               icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                               onPressed: () => _confirmDeleteClass(cls.id, cls.name),
                             ),
                           ),
                         );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: _showAddClassDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDeleteClass(String classId, String className) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Kelas'),
          content: Text('Apakah Anda yakin ingin menghapus kelas "$className"? Tindakan ini juga akan melepaskan siswa dari kelas ini.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await Provider.of<AdminProvider>(context, listen: false).deleteClass(classId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kelas berhasil dihapus.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus kelas: $e')),
                  );
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
