import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/piket_provider.dart';
import 'providers/mapel_provider.dart';
import 'providers/siswa_provider.dart';

// Config
import 'app/routes.dart';
import 'app/theme.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/guru_piket/piket_dashboard.dart';
import 'screens/guru_mapel/mapel_dashboard.dart';
import 'screens/siswa/siswa_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization info: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => PiketProvider()),
        ChangeNotifierProvider(create: (_) => MapelProvider()),
        ChangeNotifierProvider(create: (_) => SiswaProvider()),
      ],
      child: MaterialApp(
        title: 'Presensi SMP Muhammadiyah 1',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        routes: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Arahkan ke dashboard berdasarkan peran pengguna
    switch (auth.currentUser?.role) {
      case 'admin':
        return const AdminDashboard();
      case 'guru_piket':
        return const PiketDashboard();
      case 'guru_mapel':
        return const MapelDashboard();
      case 'siswa':
        return const SiswaDashboard();
      default:
        return const LoginScreen();
    }
  }
}
