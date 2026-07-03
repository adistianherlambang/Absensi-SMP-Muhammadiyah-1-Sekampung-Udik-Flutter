import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _subjectController.dispose();
    super.dispose();
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

  String _formatRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'guru_piket':
        return 'Guru Piket';
      case 'guru_mapel':
        return 'Guru Mapel';
      case 'siswa':
        return 'Siswa';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => adminProvider.fetchData(),
              child: adminProvider.users.isEmpty
                  ? const Center(child: Text('Tidak ada pengguna.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: adminProvider.users.length,
                      itemBuilder: (context, index) {
                        final user = adminProvider.users[index];
                        final isSiswa = user.role == 'siswa';
                        final isMapel = user.role == 'guru_mapel';

                        // Mengambil nama kelas jika siswa
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

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
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
                                // Menampilkan teks peran yang bersih tanpa styling badge
                                Text(
                                  'Peran: ${_formatRoleText(user.role)}$extraInfo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDeleteUser(user),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
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
}
