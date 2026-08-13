import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/searchable_select.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';
import '../../app/theme.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _subjectController = TextEditingController();

  late TabController _tabController;
  String _selectedRole =
      'admin'; // 'admin' | 'guru_piket' | 'guru_mapel' | 'siswa'
  String? _selectedClassId;

  // Filter properties
  String _searchQuery = '';
  String? _filterClassId;
  String? _filterTeacherRole;

  // Set untuk menyimpan UID dari pengguna yang dipilih (checkbox)
  final Set<UserModel> _selectedUsers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        if (_tabController.index == 0) {
          _selectedRole = 'admin';
        } else if (_tabController.index == 1) {
          _selectedRole = 'guru_mapel';
        } else {
          _selectedRole = 'siswa';
        }
        _searchQuery = '';
        _filterClassId = null;
        _filterTeacherRole = null;
        _selectedUsers.clear();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        TextCellValue('Info Tambahan'),
      ]);

      // Memberikan contoh isi
      sheetObject.appendRow([
        TextCellValue('Siswa Contoh'),
        TextCellValue('siswa@contoh.com'),
        TextCellValue('123456'),
        TextCellValue('siswa'),
        TextCellValue('ID_KELAS_DISINI'),
      ]);

      var fileBytes = excel.save();
      if (fileBytes != null) {
        if (Platform.isAndroid || Platform.isIOS) {
          final directory = await getTemporaryDirectory();
          final path = '${directory.path}/Template_Pengguna.xlsx';
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
          await file.create(recursive: true);
          await file.writeAsBytes(fileBytes);

          // Native share sheet
          await Share.shareXFiles([
            XFile(path),
          ], text: 'Template Pengguna Excel');
        } else {
          String? outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Pilih lokasi penyimpanan template:',
            fileName: 'Template_Pengguna.xlsx',
          );
          if (outputFile != null) {
            final file = File(outputFile);
            await file.create(recursive: true);
            await file.writeAsBytes(fileBytes);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Template tersimpan di: $outputFile')),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat template: $e')));
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
          const SnackBar(content: Text('Memproses import pengguna...')),
        );

        var fileBytes = result.files.single.bytes;
        if (fileBytes == null) {
          File file = File(result.files.single.path!);
          fileBytes = file.readAsBytesSync();
        }

        var excel = Excel.decodeBytes(fileBytes);
        final adminProvider = Provider.of<AdminProvider>(
          context,
          listen: false,
        );

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

            String? classId;
            if (role == 'siswa') {
              try {
                final matchedClass = adminProvider.classes.firstWhere(
                  (c) =>
                      c.name.trim().toLowerCase() == info.trim().toLowerCase(),
                );
                classId = matchedClass.id;
              } catch (_) {
                classId = info;
              }
            }
            List<String>? subjects = (role == 'guru_mapel')
                ? info.split(',').map((e) => e.trim()).toList()
                : null;

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
          SnackBar(content: Text('$importedCount pengguna berhasil diimport!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal import file: $e')));
    }
  }

  void _showAddUserDialog() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _subjectController.clear();
    setState(() {
      if (_tabController.index == 0) {
        _selectedRole = 'admin';
      } else if (_tabController.index == 1) {
        _selectedRole = 'guru_mapel';
      } else {
        _selectedRole = 'siswa';
      }
      _selectedClassId = adminProvider.classes.isNotEmpty
          ? adminProvider.classes.first.id
          : null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pilihuna Baru (${_selectedRole == "admin"
                              ? "Administrator"
                              : _selectedRole == "siswa"
                              ? "Siswa"
                              : _selectedRole == "guru_piket"
                              ? "Pilih"
                              : _selectedRole == "guru_mapel"
                              ? "Guru Mapel"
                              : "Guru Wali Kelas"})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),

                        if (_tabController.index == 1) ...[
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Tipe Guru',
                            ),
                            value: _selectedRole.startsWith('guru_')
                                ? _selectedRole
                                : 'guru_mapel',
                            items: const [
                              DropdownMenuItem(
                                value: 'guru_mapel',
                                child: Text('Guru Mata Pelajaran'),
                              ),
                              DropdownMenuItem(
                                value: 'guru_piket',
                                child: Text('Pilih'),
                              ),
                              DropdownMenuItem(
                                value: 'guru_wali_kelas',
                                child: Text('Guru Wali Kelas'),
                              ),
                            ],
                            onChanged: (val) {
                              setModalState(() {
                                if (val != null) {
                                  _selectedRole = val;
                                  _selectedClassId = null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Input Nama
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Nama tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Input Email dengan template Suffix @smpm1.sch.id
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            suffixText: '@smpm1.sch.id',
                            suffixStyle: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Email tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Input Password
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Password minimal 6 karakter'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Kondisional khusus Siswa: Pilih Kelas
                        if (_selectedRole == 'siswa') ...[
                          SearchableSelect<dynamic>(
                            labelText: 'Pilih Kelas (Khusus Siswa)',
                            items: adminProvider.classes,
                            itemLabel: (c) => c.name as String,
                            selectedValue: _selectedClassId != null
                                ? adminProvider.classes.firstWhere(
                                    (c) => c.id == _selectedClassId,
                                    orElse: () => adminProvider.classes.first,
                                  )
                                : null,
                            onChanged: (val) {
                              setModalState(() {
                                _selectedClassId = val?.id;
                              });
                            },
                            validator: (v) =>
                                _selectedRole == 'siswa' && v == null
                                ? 'Pilih kelas siswa'
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Kondisional khusus Wali Kelas: Pilih Kelas yang diampu (atau tidak sama sekali)
                        if (_selectedRole == 'guru_wali_kelas') ...[
                          SearchableSelect<ClassModel>(
                            labelText: 'Kelas Bimbingan',
                            items: [
                              ClassModel(
                                id: 'none',
                                name: 'Tidak Mengampu Kelas',
                                homeroomTeacherId: '',
                                studentIds: const [],
                              ),
                              ...adminProvider.classes,
                            ],
                            itemLabel: (c) => c.name,
                            selectedValue: _selectedClassId != null
                                ? adminProvider.classes.firstWhere(
                                    (c) => c.id == _selectedClassId,
                                    orElse: () => ClassModel(
                                      id: 'none',
                                      name: 'Tidak Mengampu Kelas',
                                      homeroomTeacherId: '',
                                      studentIds: const [],
                                    ),
                                  )
                                : ClassModel(
                                    id: 'none',
                                    name: 'Tidak Mengampu Kelas',
                                    homeroomTeacherId: '',
                                    studentIds: const [],
                                  ),
                            onChanged: (val) {
                              setModalState(() {
                                _selectedClassId =
                                    (val == null || val.id == 'none')
                                    ? null
                                    : val.id;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Kondisional khusus Guru Mapel: Masukkan Mapel
                        if (_selectedRole == 'guru_mapel') ...[
                          TextFormField(
                            controller: _subjectController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Mata Pelajaran (pisahkan dengan koma)',
                              helperText: 'Contoh: Matematika, Fisika, IPA',
                            ),
                            validator: (v) =>
                                _selectedRole == 'guru_mapel' &&
                                    (v == null || v.isEmpty)
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
                              const SnackBar(
                                content: Text(
                                  'Memproses penambahan user baru...',
                                ),
                              ),
                            );

                            try {
                              List<String>? subjectsList;
                              if (_selectedRole == 'guru_mapel' &&
                                  _subjectController.text.isNotEmpty) {
                                subjectsList = _subjectController.text
                                    .split(',')
                                    .map((s) => s.trim())
                                    .where((s) => s.isNotEmpty)
                                    .toList();
                              }

                              String rawEmail = _emailController.text.trim();
                              String fullEmail = rawEmail.contains('@')
                                  ? rawEmail
                                  : '$rawEmail@smpm1.sch.id';

                              await adminProvider.createUser(
                                name: _nameController.text.trim(),
                                email: fullEmail,
                                password: _passwordController.text.trim(),
                                role: _selectedRole,
                                classId:
                                    (_selectedRole == 'siswa' ||
                                        _selectedRole == 'guru_wali_kelas')
                                    ? _selectedClassId
                                    : null,
                                subjects: subjectsList,
                              );

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User berhasil ditambahkan!'),
                                ),
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showEditUserDialog(UserModel user) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    _nameController.text = user.name;
    _emailController.text = user.email;
    _passwordController.clear();
    _subjectController.text = user.subjects?.join(', ') ?? '';

    // Temukan kelas bimbingan jika user adalah guru_wali_kelas
    String? initialClassId = user.classId;
    if (user.role == 'guru_wali_kelas') {
      try {
        final cl = adminProvider.classes.firstWhere(
          (c) => c.homeroomTeacherId == user.uid,
        );
        initialClassId = cl.id;
      } catch (_) {
        initialClassId = null;
      }
    }

    setState(() {
      _selectedClassId = initialClassId;
      _selectedRole = user.role;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Edit Pengguna: ${user.name}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),

                        if (user.role.startsWith('guru_')) ...[
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Tipe Guru',
                            ),
                            value: _selectedRole.startsWith('guru_')
                                ? _selectedRole
                                : user.role,
                            items: const [
                              DropdownMenuItem(
                                value: 'guru_mapel',
                                child: Text('Guru Mata Pelajaran'),
                              ),
                              DropdownMenuItem(
                                value: 'guru_piket',
                                child: Text('Pilih'),
                              ),
                              DropdownMenuItem(
                                value: 'guru_wali_kelas',
                                child: Text('Guru Wali Kelas'),
                              ),
                            ],
                            onChanged: (val) {
                              setModalState(() {
                                if (val != null) {
                                  _selectedRole = val;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Input Nama
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Nama tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Input Email (Read-only)
                        TextFormField(
                          controller: _emailController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Email (Tidak dapat diubah)',
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Kondisional khusus Siswa: Pilih Kelas
                        if (user.role == 'siswa') ...[
                          SearchableSelect<dynamic>(
                            labelText: 'Pilih Kelas (Khusus Siswa)',
                            items: adminProvider.classes,
                            itemLabel: (c) => c.name as String,
                            selectedValue: _selectedClassId != null
                                ? adminProvider.classes.firstWhere(
                                    (c) => c.id == _selectedClassId,
                                    orElse: () => adminProvider.classes.first,
                                  )
                                : null,
                            onChanged: (val) {
                              setModalState(() {
                                _selectedClassId = val?.id;
                              });
                            },
                            validator: (v) => user.role == 'siswa' && v == null
                                ? 'Pilih kelas siswa'
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Kondisional khusus Wali Kelas: Pilih Kelas yang diampu (atau tidak sama sekali)
                        if (_selectedRole == 'guru_wali_kelas') ...[
                          SearchableSelect<ClassModel>(
                            labelText: 'Kelas Bimbingan',
                            items: [
                              ClassModel(
                                id: 'none',
                                name: 'Tidak Mengampu Kelas',
                                homeroomTeacherId: '',
                                studentIds: const [],
                              ),
                              ...adminProvider.classes,
                            ],
                            itemLabel: (c) => c.name,
                            selectedValue: _selectedClassId != null
                                ? adminProvider.classes.firstWhere(
                                    (c) => c.id == _selectedClassId,
                                    orElse: () => ClassModel(
                                      id: 'none',
                                      name: 'Tidak Mengampu Kelas',
                                      homeroomTeacherId: '',
                                      studentIds: const [],
                                    ),
                                  )
                                : ClassModel(
                                    id: 'none',
                                    name: 'Tidak Mengampu Kelas',
                                    homeroomTeacherId: '',
                                    studentIds: const [],
                                  ),
                            onChanged: (val) {
                              setModalState(() {
                                _selectedClassId =
                                    (val == null || val.id == 'none')
                                    ? null
                                    : val.id;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Kondisional khusus Guru Mapel: Masukkan Mapel
                        if (_selectedRole == 'guru_mapel') ...[
                          TextFormField(
                            controller: _subjectController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Mata Pelajaran (pisahkan dengan koma)',
                              helperText: 'Contoh: Matematika, Fisika, IPA',
                            ),
                            validator: (v) =>
                                _selectedRole == 'guru_mapel' &&
                                    (v == null || v.isEmpty)
                                ? 'Masukkan minimal 1 mata pelajaran'
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Memproses pembaruan data user...',
                                ),
                              ),
                            );

                            try {
                              List<String>? subjectsList;
                              if (_selectedRole == 'guru_mapel' &&
                                  _subjectController.text.isNotEmpty) {
                                subjectsList = _subjectController.text
                                    .split(',')
                                    .map((s) => s.trim())
                                    .where((s) => s.isNotEmpty)
                                    .toList();
                              }

                              await adminProvider.updateUser(
                                uid: user.uid,
                                name: _nameController.text.trim(),
                                role: _selectedRole,
                                classId:
                                    (_selectedRole == 'siswa' ||
                                        _selectedRole == 'guru_wali_kelas')
                                    ? _selectedClassId
                                    : null,
                                subjects: _selectedRole == 'guru_mapel'
                                    ? subjectsList
                                    : null,
                              );

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User berhasil diperbarui!'),
                                ),
                              );
                              setState(() {
                                _selectedUsers.clear();
                              });
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal memperbarui user: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showBatchEditUserDialog() {
    if (_selectedUsers.isEmpty) return;

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    // Inisialisasi daftar item edit batch untuk setiap user yang dipilih
    final List<_BatchUserEditItem> editItems = _selectedUsers.map((u) {
      String? initialClassId = u.classId;
      if (u.role == 'guru_wali_kelas') {
        try {
          final cl = adminProvider.classes.firstWhere(
            (c) => c.homeroomTeacherId == u.uid,
          );
          initialClassId = cl.id;
        } catch (_) {
          initialClassId = null;
        }
      }
      return _BatchUserEditItem(user: u, initialClassId: initialClassId);
    }).toList();

    final batchFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Modal
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Edit Batch (${editItems.length} Pengguna)',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              for (var item in editItems) {
                                item.dispose();
                              }
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // List formulir edit per user (stacked ke bawah)
                    Expanded(
                      child: Form(
                        key: batchFormKey,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: editItems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 24),
                          itemBuilder: (context, index) {
                            final item = editItems[index];
                            final u = item.user;

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Edit Pengguna: ${u.name}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Tipe Guru (jika role guru)
                                  if (u.role.startsWith('guru_')) ...[
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Tipe Guru',
                                      ),
                                      value: item.role.startsWith('guru_')
                                          ? item.role
                                          : u.role,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'guru_mapel',
                                          child: Text('Guru Mata Pelajaran'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'guru_piket',
                                          child: Text('Guru Piket'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'guru_wali_kelas',
                                          child: Text('Guru Wali Kelas'),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        setModalState(() {
                                          if (val != null) {
                                            item.role = val;
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Input Nama
                                  TextFormField(
                                    controller: item.nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nama Lengkap',
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Nama tidak boleh kosong'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Input Email (Read-only)
                                  TextFormField(
                                    controller: item.emailController,
                                    enabled: false,
                                    decoration: const InputDecoration(
                                      labelText: 'Email (Tidak dapat diubah)',
                                      filled: true,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Kondisional khusus Siswa: Pilih Kelas
                                  if (u.role == 'siswa') ...[
                                    SearchableSelect<dynamic>(
                                      labelText: 'Pilih Kelas (Khusus Siswa)',
                                      items: adminProvider.classes,
                                      itemLabel: (c) => c.name as String,
                                      selectedValue: item.classId != null
                                          ? adminProvider.classes.firstWhere(
                                              (c) => c.id == item.classId,
                                              orElse: () =>
                                                  adminProvider.classes.first,
                                            )
                                          : null,
                                      onChanged: (val) {
                                        setModalState(() {
                                          item.classId = val?.id;
                                        });
                                      },
                                      validator: (v) =>
                                          u.role == 'siswa' && v == null
                                              ? 'Pilih kelas siswa'
                                              : null,
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Kondisional khusus Wali Kelas: Kelas Bimbingan
                                  if (item.role == 'guru_wali_kelas') ...[
                                    SearchableSelect<ClassModel>(
                                      labelText: 'Kelas Bimbingan',
                                      items: [
                                        ClassModel(
                                          id: 'none',
                                          name: 'Tidak Mengampu Kelas',
                                          homeroomTeacherId: '',
                                          studentIds: const [],
                                        ),
                                        ...adminProvider.classes,
                                      ],
                                      itemLabel: (c) => c.name,
                                      selectedValue: item.classId != null
                                          ? adminProvider.classes.firstWhere(
                                              (c) => c.id == item.classId,
                                              orElse: () => ClassModel(
                                                id: 'none',
                                                name: 'Tidak Mengampu Kelas',
                                                homeroomTeacherId: '',
                                                studentIds: const [],
                                              ),
                                            )
                                          : ClassModel(
                                              id: 'none',
                                              name: 'Tidak Mengampu Kelas',
                                              homeroomTeacherId: '',
                                              studentIds: const [],
                                            ),
                                      onChanged: (val) {
                                        setModalState(() {
                                          item.classId =
                                              (val == null || val.id == 'none')
                                                  ? null
                                                  : val.id;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Kondisional khusus Guru Mapel: Masukkan Mapel
                                  if (item.role == 'guru_mapel') ...[
                                    TextFormField(
                                      controller: item.subjectController,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Mata Pelajaran (pisahkan dengan koma)',
                                        helperText:
                                            'Contoh: Matematika, Fisika, IPA',
                                      ),
                                      validator: (v) =>
                                          item.role == 'guru_mapel' &&
                                              (v == null || v.isEmpty)
                                              ? 'Masukkan minimal 1 mata pelajaran'
                                              : null,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Tombol Simpan
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            if (!batchFormKey.currentState!.validate()) return;

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Memproses pembaruan data user...',
                                ),
                              ),
                            );

                            try {
                              for (var item in editItems) {
                                List<String>? subjectsList;
                                if (item.role == 'guru_mapel' &&
                                    item.subjectController.text.isNotEmpty) {
                                  subjectsList = item.subjectController.text
                                      .split(',')
                                      .map((s) => s.trim())
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                }

                                await adminProvider.updateUser(
                                  uid: item.user.uid,
                                  name: item.nameController.text.trim(),
                                  role: item.role,
                                  classId: (item.role == 'siswa' ||
                                          item.role == 'guru_wali_kelas')
                                      ? item.classId
                                      : null,
                                  subjects: item.role == 'guru_mapel'
                                      ? subjectsList
                                      : null,
                                );
                              }

                              for (var item in editItems) {
                                item.dispose();
                              }

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User berhasil diperbarui!'),
                                ),
                              );
                              setState(() {
                                _selectedUsers.clear();
                              });
                            } catch (e) {
                              for (var item in editItems) {
                                item.dispose();
                              }
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal memperbarui user: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
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
          content: Text(
            'Apakah Anda yakin ingin menghapus ${_selectedUsers.length} pengguna terpilih?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final adminProvider = Provider.of<AdminProvider>(
                  context,
                  listen: false,
                );
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
          content: Text(
            'Apakah Anda yakin ingin menghapus "${user.name}"? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await Provider.of<AdminProvider>(
                    context,
                    listen: false,
                  ).deleteUser(user.uid, user.role, user.classId);
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

  Widget _buildUserList(
    List<UserModel> users,
    AdminProvider adminProvider,
    String role,
  ) {
    // 1. Filter local users berdasarkan search query, filter kelas, & filter tipe guru
    final filteredUsers = users.where((u) {
      final matchesSearch =
          u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesClass =
          role != 'siswa' ||
          _filterClassId == null ||
          u.classId == _filterClassId;

      final matchesTeacherRole =
          role != 'guru' ||
          _filterTeacherRole == null ||
          u.role == _filterTeacherRole;

      return matchesSearch && matchesClass && matchesTeacherRole;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total count & Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${filteredUsers.length} pengguna tersedia',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau email...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                          _selectedUsers.clear();
                        });
                      },
                    ),
                  ),
                  if (role == 'siswa') ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 135,
                      child: SearchableSelect<ClassModel>(
                        labelText: 'Kelas',
                        items: [
                          ClassModel(
                            id: 'all',
                            name: 'Pilih',
                            homeroomTeacherId: '',
                            studentIds: const [],
                          ),
                          ...adminProvider.classes,
                        ],
                        itemLabel: (c) => c.name,
                        selectedValue: _filterClassId != null
                            ? adminProvider.classes.firstWhere(
                                (c) => c.id == _filterClassId,
                                orElse: () => ClassModel(
                                  id: 'all',
                                  name: 'Pilih',
                                  homeroomTeacherId: '',
                                  studentIds: const [],
                                ),
                              )
                            : ClassModel(
                                id: 'all',
                                name: 'Pilih',
                                homeroomTeacherId: '',
                                studentIds: const [],
                              ),
                        onChanged: (val) {
                          setState(() {
                            _filterClassId = (val == null || val.id == 'all')
                                ? null
                                : val.id;
                            _selectedUsers.clear();
                          });
                        },
                      ),
                    ),
                  ],
                  if (role == 'guru') ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 135,
                      child: SearchableSelect<TeacherTypeFilter>(
                        labelText: 'Tipe Guru',
                        items: const [
                          TeacherTypeFilter(null, 'Pilih'),
                          TeacherTypeFilter('guru_mapel', 'Guru Mapel'),
                          TeacherTypeFilter('guru_piket', 'Pilih'),
                          TeacherTypeFilter('guru_wali_kelas', 'Wali Kelas'),
                        ],
                        itemLabel: (t) => t.name,
                        selectedValue:
                            const [
                              TeacherTypeFilter(null, 'Pilih'),
                              TeacherTypeFilter('guru_mapel', 'Guru Mapel'),
                              TeacherTypeFilter('guru_piket', 'Pilih'),
                              TeacherTypeFilter(
                                'guru_wali_kelas',
                                'Wali Kelas',
                              ),
                            ].firstWhere(
                              (t) => t.role == _filterTeacherRole,
                              orElse: () =>
                                  const TeacherTypeFilter(null, 'Pilih'),
                            ),
                        onChanged: (val) {
                          setState(() {
                            _filterTeacherRole = val?.role;
                            _selectedUsers.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: filteredUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada pengguna ditemukan.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];

                    String roleDisplayText = '';
                    if (user.role == 'admin') {
                      roleDisplayText = 'Admin';
                    } else if (user.role == 'siswa') {
                      String classInfo = '';
                      if (user.classId != null) {
                        try {
                          final cl = adminProvider.classes.firstWhere(
                            (c) => c.id == user.classId,
                          );
                          classInfo = ' (${cl.name})';
                        } catch (_) {
                          classInfo = ' (Kelas ?)';
                        }
                      }
                      roleDisplayText = 'Siswa$classInfo';
                    } else if (user.role == 'guru_piket') {
                      roleDisplayText = 'Guru Piket';
                    } else if (user.role == 'guru_mapel') {
                      if (user.subjects != null && user.subjects!.isNotEmpty) {
                        roleDisplayText =
                            'Guru Mapel (${user.subjects!.join(', ')})';
                      } else {
                        roleDisplayText = 'Guru Mapel';
                      }
                    } else if (user.role == 'guru_wali_kelas') {
                      String classInfo = '';
                      try {
                        final cl = adminProvider.classes.firstWhere(
                          (c) => c.homeroomTeacherId == user.uid,
                        );
                        classInfo = ' (${cl.name})';
                      } catch (_) {}
                      roleDisplayText = 'Wali Kelas$classInfo';
                    } else {
                      roleDisplayText = user.role;
                    }

                    final isSelected = _selectedUsers.contains(user);

                    final colors = [
                      [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)],
                      [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
                      [const Color(0xFFFDC830), const Color(0xFFF37335)],
                      [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
                    ];
                    final colorPair = colors[user.name.length % colors.length];

                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withOpacity(0.06)
                            : Colors.white,
                        border: Border(
                          top: index == 0
                              ? BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                )
                              : BorderSide.none,
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedUsers.remove(user);
                              } else {
                                _selectedUsers.add(user);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                // Checkbox Lingkaran (seperti pada contoh UI)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedUsers.remove(user);
                                      } else {
                                        _selectedUsers.add(user);
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Avatar Bulat khas desain modern
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colorPair[0].withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0] : 'U',
                                      style: TextStyle(
                                        color: colorPair[0],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Info Pengguna
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppTheme.textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        roleDisplayText,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                          color: colorPair[0],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Tombol aksi individual
                                if (_selectedUsers.isEmpty) ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    color: Colors.grey.shade600,
                                    onPressed: () => _showEditUserDialog(user),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    color: Colors.red.shade400,
                                    onPressed: () => _confirmDeleteUser(user),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final adminUsers = adminProvider.users
        .where((u) => u.role == 'admin')
        .toList();
    final guruUsers = adminProvider.users
        .where((u) => u.role.startsWith('guru_'))
        .toList();
    final siswaUsers = adminProvider.users
        .where((u) => u.role == 'siswa')
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kelola Pengguna',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // Tombol Tambah di kanan atas seperti contoh "+ ADD MORE"
          // Padding(
          //   padding: const EdgeInsets.only(right: 4),
          //   child: ElevatedButton.icon(
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: AppTheme.primaryColor,
          //       elevation: 0,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(20),
          //       ),
          //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          //       minimumSize: Size.zero,
          //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //     ),
          //     icon: const Icon(Icons.add, size: 16, color: Colors.white),
          //     label: const Text(
          //       'TAMBAH',
          //       style: TextStyle(
          //         color: Colors.white,
          //         fontWeight: FontWeight.bold,
          //         fontSize: 12,
          //       ),
          //     ),
          //     onPressed: _showAddUserDialog,
          //   ),
          // ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) {
              if (value == 'download') {
                _downloadTemplate();
              } else if (value == 'import') {
                _importExcel();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'download',
                child: Text(
                  Platform.isAndroid || Platform.isIOS
                      ? 'Bagikan Template Excel'
                      : 'Unduh Template Excel',
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Text('Import Data Excel'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Admin'),
                Tab(text: 'Guru'),
                Tab(text: 'Siswa'),
              ],
            ),
          ),
        ),
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(adminUsers, adminProvider, 'admin'),
                _buildUserList(guruUsers, adminProvider, 'guru'),
                _buildUserList(siswaUsers, adminProvider, 'siswa'),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedUsers.isEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              shape: const StadiumBorder(),
              onPressed: _showAddUserDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Pilihuna Baru',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            )
          : Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: FloatingActionButton.extended(
                      heroTag: 'edit_selected',
                      backgroundColor: Colors.amber.shade700,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      onPressed: _selectedUsers.length == 1
                          ? () => _showEditUserDialog(_selectedUsers.first)
                          : _showBatchEditUserDialog,
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: Text(
                        'Edit (${_selectedUsers.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FloatingActionButton.extended(
                      heroTag: 'delete_selected',
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      onPressed: _confirmDeleteSelectedUsers,
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: Text(
                        'Hapus (${_selectedUsers.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class TeacherTypeFilter {
  final String? role;
  final String name;
  const TeacherTypeFilter(this.role, this.name);
}

class _BatchUserEditItem {
  final UserModel user;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController subjectController;
  String role;
  String? classId;

  _BatchUserEditItem({
    required this.user,
    required String? initialClassId,
  })  : nameController = TextEditingController(text: user.name),
        emailController = TextEditingController(text: user.email),
        subjectController =
            TextEditingController(text: user.subjects?.join(', ') ?? ''),
        role = user.role,
        classId = initialClassId;

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    subjectController.dispose();
  }
}
