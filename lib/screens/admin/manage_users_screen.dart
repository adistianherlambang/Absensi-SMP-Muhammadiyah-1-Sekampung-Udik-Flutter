import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _subjectController = TextEditingController();
  
  String _selectedRole = 'siswa'; // 'admin' | 'guru_piket' | 'guru_mapel' | 'siswa'
  String? _selectedClassId;

  // Set untuk menyimpan UID dari pengguna yang dipilih (checkbox)
  final Set<UserModel> _selectedUsers = {};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _downloadTemplate() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];
      sheetObject.appendRow([
        TextCellValue('Nama Lengkap'), 
        TextCellValue('Email'), 
        TextCellValue('Password'), 
        TextCellValue('Role'), 
        TextCellValue('Info Tambahan')
      ]);
      
      // Memberikan contoh isi
      sheetObject.appendRow([
        TextCellValue('Siswa Contoh'), 
        TextCellValue('siswa@contoh.com'), 
        TextCellValue('123456'), 
        TextCellValue('siswa'), 
        TextCellValue('ID_KELAS_DISINI')
      ]);

      var fileBytes = excel.save();
      if (fileBytes != null) {
        if (Platform.isAndroid || Platform.isIOS) {
          Directory? directory = await getExternalStorageDirectory();
          directory ??= await getApplicationDocumentsDirectory();
          
          String path = '${directory.path}/Template_Pengguna.xlsx';
          File(path)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
            
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Template tersimpan di: $path')));
        } else {
          String? outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Pilih lokasi penyimpanan template:',
            fileName: 'Template_Pengguna.xlsx',
          );
          if (outputFile != null) {
            File(outputFile)
              ..createSync(recursive: true)
              ..writeAsBytesSync(fileBytes);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Template tersimpan di: $outputFile')));
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat template: $e')));
    }
  }

  Future<void> _importExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memproses import pengguna...'))
        );

        var fileBytes = result.files.single.bytes;
        if (fileBytes == null) {
          File file = File(result.files.single.path!);
          fileBytes = file.readAsBytesSync();
        }
        
        var excel = Excel.decodeBytes(fileBytes);
        final adminProvider = Provider.of<AdminProvider>(context, listen: false);
        
        int importedCount = 0;
        
        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table]!;
          for (int i = 1; i < sheet.maxRows; i++) {
            var row = sheet.rows[i];
            if (row.isEmpty) continue;
            
            String name = row[0]?.value.toString() ?? '';
            String email = row[1]?.value.toString() ?? '';
            String password = row[2]?.value.toString() ?? '';
            String role = row[3]?.value.toString().toLowerCase() ?? 'siswa';
            String info = row[4]?.value.toString() ?? '';
            
            if (name.isEmpty || email.isEmpty || password.isEmpty) continue;
            
            String? classId = (role == 'siswa') ? info : null;
            List<String>? subjects = (role == 'guru_mapel') ? info.split(',').map((e) => e.trim()).toList() : null;
            
            try {
              await adminProvider.createUser(
                name: name,
                email: email,
                password: password,
                role: role,
                classId: classId,
                subjects: subjects,
              );
              importedCount++;
            } catch (e) {
              debugPrint("Error importing row $i: $e");
            }
          }
        }
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$importedCount pengguna berhasil diimport!'))
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal import file: $e')));
    }
  }

  void _showAddUserDialog() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _subjectController.clear();
    setState(() {
      _selectedRole = 'siswa';
      _selectedClassId = adminProvider.classes.isNotEmpty ? adminProvider.classes.first.id : null;
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
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tambah Pengguna Baru',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),

                      // Input Nama
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                        validator: (v) => v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),

                      // Input Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) => v == null || v.isEmpty ? 'Email tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),

                      // Input Password
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
                      ),
                      const SizedBox(height: 16),

                      // Pilihan Peran / Role (Teks biasa dalam Dropdown)
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(labelText: 'Peran / Role'),
                        items: const [
                          DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                          DropdownMenuItem(value: 'guru_piket', child: Text('Guru Piket')),
                          DropdownMenuItem(value: 'guru_mapel', child: Text('Guru Mata Pelajaran')),
                          DropdownMenuItem(value: 'siswa', child: Text('Siswa')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              _selectedRole = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Kondisional khusus Siswa: Pilih Kelas
                      if (_selectedRole == 'siswa') ...[
                        DropdownButtonFormField<String>(
                          value: _selectedClassId,
                          decoration: const InputDecoration(labelText: 'Pilih Kelas (Khusus Siswa)'),
                          items: adminProvider.classes.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              _selectedClassId = val;
                            });
                          },
                          validator: (v) => _selectedRole == 'siswa' && v == null ? 'Pilih kelas siswa' : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Kondisional khusus Guru Mapel: Masukkan Mapel
                      if (_selectedRole == 'guru_mapel') ...[
                        TextFormField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Mata Pelajaran (pisahkan dengan koma)',
                            helperText: 'Contoh: Matematika, Fisika, IPA',
                          ),
                          validator: (v) => _selectedRole == 'guru_mapel' && (v == null || v.isEmpty)
                              ? 'Masukkan minimal 1 mata pelajaran'
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Memproses penambahan user baru...')),
                          );

                          try {
                            List<String>? subjectsList;
                            if (_selectedRole == 'guru_mapel' && _subjectController.text.isNotEmpty) {
                              subjectsList = _subjectController.text
                                  .split(',')
                                  .map((s) => s.trim())
                                  .where((s) => s.isNotEmpty)
                                  .toList();
                            }

                            await adminProvider.createUser(
                              name: _nameController.text.trim(),
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                              role: _selectedRole,
                              classId: _selectedRole == 'siswa' ? _selectedClassId : null,
                              subjects: subjectsList,
                            );

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User berhasil ditambahkan!')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menambah user: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text('Simpan Pengguna'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSelectedUsers() {
    if (_selectedUsers.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Pengguna Terpilih'),
          content: Text('Apakah Anda yakin ingin menghapus ${_selectedUsers.length} pengguna terpilih?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                try {
                  await adminProvider.deleteUsersBatch(_selectedUsers.toList());
                  setState(() {
                    _selectedUsers.clear();
                  });
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pengguna berhasil dihapus.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus pengguna: $e')),
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

  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Pengguna'),
          content: Text('Apakah Anda yakin ingin menghapus "${user.name}"? Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await Provider.of<AdminProvider>(context, listen: false).deleteUser(
                    user.uid,
                    user.role,
                    user.classId,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pengguna berhasil dihapus.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus pengguna: $e')),
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

  Widget _buildUserList(List<UserModel> users, AdminProvider adminProvider) {
    if (users.isEmpty) {
      return const Center(child: Text('Tidak ada pengguna.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isSiswa = user.role == 'siswa';
        final isMapel = user.role == 'guru_mapel';

        String extraInfo = '';
        if (isSiswa && user.classId != null) {
          try {
            final cl = adminProvider.classes.firstWhere((c) => c.id == user.classId);
            extraInfo = ' • Kelas: ${cl.name}';
          } catch (e) {
            extraInfo = ' • Kelas: Tidak diketahui';
          }
        } else if (isMapel && user.subjects != null) {
          extraInfo = ' • Mapel: ${user.subjects!.join(', ')}';
        }

        final isSelected = _selectedUsers.contains(user);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (bool? checked) {
              setState(() {
                if (checked == true) {
                  _selectedUsers.add(user);
                } else {
                  _selectedUsers.remove(user);
                }
              });
            },
            secondary: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDeleteUser(user),
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                const SizedBox(height: 4),
                Text(
                  'Peran: ${user.role}$extraInfo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final adminUsers = adminProvider.users.where((u) => u.role == 'admin').toList();
    final guruPiketUsers = adminProvider.users.where((u) => u.role == 'guru_piket').toList();
    final guruMapelUsers = adminProvider.users.where((u) => u.role == 'guru_mapel').toList();
    final siswaUsers = adminProvider.users.where((u) => u.role == 'siswa').toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Pengguna'),
          actions: [
            if (_selectedUsers.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Hapus Terpilih',
                onPressed: _confirmDeleteSelectedUsers,
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'download') {
                  _downloadTemplate();
                } else if (value == 'import') {
                  _importExcel();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'download',
                  child: Text('Unduh Template Excel'),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Text('Import Data (Excel)'),
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Admin'),
              Tab(text: 'Guru Piket'),
              Tab(text: 'Guru Mapel'),
              Tab(text: 'Siswa'),
            ],
          ),
        ),
        body: adminProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildUserList(adminUsers, adminProvider),
                  _buildUserList(guruPiketUsers, adminProvider),
                  _buildUserList(guruMapelUsers, adminProvider),
                  _buildUserList(siswaUsers, adminProvider),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddUserDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
