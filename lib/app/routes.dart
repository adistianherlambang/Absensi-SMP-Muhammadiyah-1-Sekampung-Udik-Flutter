import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/admin/manage_classes_screen.dart';
import '../screens/admin/generate_qr_screen.dart';
import '../screens/admin/reports_screen.dart';
import '../screens/guru_piket/piket_dashboard.dart';
import '../screens/guru_piket/open_session_screen.dart';
import '../screens/guru_piket/validate_attendance_screen.dart';
import '../screens/guru_piket/weekly_recap_screen.dart';
import '../screens/guru_mapel/mapel_dashboard.dart';
import '../screens/guru_mapel/open_mapel_session_screen.dart';
import '../screens/guru_mapel/mapel_attendance_screen.dart';
import '../screens/siswa/siswa_dashboard.dart';
import '../screens/siswa/scan_qr_screen.dart';
import '../screens/siswa/attendance_history_screen.dart';
import '../screens/siswa/leave_request_screen.dart';
import '../screens/guru/scan_class_qr_screen.dart';
import '../screens/guru/input_attendance_screen.dart';
import '../screens/guru/history_screen.dart';

class AppRoutes {
  static const String login = '/login';
  
  // Admin
  static const String adminDashboard = '/admin';
  static const String adminManageUsers = '/admin/users';
  static const String adminManageClasses = '/admin/classes';
  static const String adminGenerateQR = '/admin/qr';
  static const String adminReports = '/admin/reports';

  // Guru Piket
  static const String piketDashboard = '/piket';
  static const String piketOpenSession = '/piket/open-session';
  static const String piketValidate = '/piket/validate';
  static const String piketWeeklyRecap = '/piket/weekly-recap';

  // Guru Mapel
  static const String mapelDashboard = '/mapel';
  static const String mapelOpenSession = '/mapel/open-session';
  static const String mapelAttendance = '/mapel/attendance';

  // Siswa
  static const String siswaDashboard = '/siswa';
  static const String siswaScanQR = '/siswa/scan-qr';
  static const String siswaHistory = '/siswa/history';
  static const String siswaLeaveRequest = '/siswa/leave-request';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginScreen(),
      
      // Admin
      adminDashboard: (context) => const AdminDashboard(),
      adminManageUsers: (context) => const ManageUsersScreen(),
      adminManageClasses: (context) => const ManageClassesScreen(),
      adminGenerateQR: (context) => const GenerateQRScreen(),
      adminReports: (context) => const ReportsScreen(),

      // Piket
      piketDashboard: (context) => const PiketDashboard(),
      piketOpenSession: (context) => const OpenSessionScreen(),
      piketValidate: (context) => const ValidateAttendanceScreen(),
      piketWeeklyRecap: (context) => const WeeklyRecapScreen(),

      // Mapel
      mapelDashboard: (context) => const MapelDashboard(),
      mapelOpenSession: (context) => const OpenMapelSessionScreen(),
      mapelAttendance: (context) => const MapelAttendanceScreen(),

      // Siswa
      siswaDashboard: (context) => const SiswaDashboard(),
      siswaScanQR: (context) => const ScanQRScreen(),
      siswaHistory: (context) => const AttendanceHistoryScreen(),
      siswaLeaveRequest: (context) => const LeaveRequestScreen(),

      // Guru Baru (Scan, Input, Riwayat)
      '/guru/scan-class': (context) => const ScanClassQRScreen(),
      '/guru/input-attendance': (context) => const InputAttendanceScreen(),
      '/guru/history': (context) => const HistoryScreen(),
    };
  }
}
