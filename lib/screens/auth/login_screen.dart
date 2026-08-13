import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../app/routes.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      String rawEmail = _emailController.text.trim();
      String emailToUse = rawEmail.contains('@') ? rawEmail : '$rawEmail@smpm1.sch.id';

      await authProvider.signIn(
        emailToUse,
        _passwordController.text.trim(),
      );

      // Setelah login berhasil, arahkan ke dashboard yang sesuai
      if (!mounted) return;
      final role = authProvider.currentUser?.role;
      _navigateToDashboard(role);
    } catch (e) {
      if (!mounted) return;
      String userFriendlyMessage = 'Terjadi kesalahan. Silakan periksa koneksi internet Anda dan coba lagi.';
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('invalid-email') || 
          errorStr.contains('user-not-found') || 
          errorStr.contains('wrong-password') || 
          errorStr.contains('invalid-credential')) {
        userFriendlyMessage = 'Email atau password salah. Silakan periksa kembali.';
      } else if (errorStr.contains('user-disabled')) {
        userFriendlyMessage = 'Akun Anda telah dinonaktifkan. Hubungi admin sekolah.';
      } else if (errorStr.contains('too-many-requests')) {
        userFriendlyMessage = 'Terlalu banyak percobaan masuk yang gagal. Silakan coba lagi nanti.';
      } else if (errorStr.contains('network-request-failed')) {
        userFriendlyMessage = 'Koneksi internet bermasalah. Pastikan perangkat Anda terhubung ke internet.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _navigateToDashboard(String? role) {
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    } else if (role == 'guru_piket' || role == 'guru_wali_kelas') {
      Navigator.pushReplacementNamed(context, AppRoutes.piketDashboard);
    } else if (role == 'guru_mapel') {
      Navigator.pushReplacementNamed(context, AppRoutes.mapelDashboard);
    } else if (role == 'siswa') {
      Navigator.pushReplacementNamed(context, AppRoutes.siswaDashboard);
    }
  }

  void _quickFill(String emailPrefix, String password) {
    setState(() {
      _emailController.text = emailPrefix;
      _passwordController.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 100,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Sistem Presensi QR',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'SMP Muhammadiyah 1 Sekampung Udik',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                          suffixText: '@smpm1.sch.id',
                          suffixStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Masukkan email Anda';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outlined, color: AppTheme.primaryColor),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppTheme.textMutedColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan password Anda';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              onPressed: _handleLogin,
                              child: const Text(
                                'Login',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),

                      const SizedBox(height: 20),
                      const Text(
                        'Demo Quick Fill:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMutedColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () => _quickFill('admin', 'admin123'),
                            child: const Text('Admin'),
                          ),
                          OutlinedButton(
                            onPressed: () => _quickFill('piket', 'piket123'),
                            child: const Text('Guru Piket'),
                          ),
                          OutlinedButton(
                            onPressed: () => _quickFill('mapel', 'mapel123'),
                            child: const Text('Guru Mapel'),
                          ),
                          OutlinedButton(
                            onPressed: () => _quickFill('wali', 'wali123'),
                            child: const Text('Wali Kelas'),
                          ),
                          OutlinedButton(
                            onPressed: () => _quickFill('siswa1', 'siswa123'),
                            child: const Text('Siswa'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().slideY(
                  begin: 0.05, end: 0, 
                  duration: 400.ms, 
                  curve: Curves.easeOut,
                ).fade(
                  duration: 400.ms,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
