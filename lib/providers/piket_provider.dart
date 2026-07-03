import 'package:flutter/material.dart';
import '../core/services/db_service.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';

class PiketProvider with ChangeNotifier {
  final DBService _dbService = DBService();
  
  List<SessionModel> _sessions = [];
  List<UserModel> _students = [];
  Map<String, AttendanceModel> _sessionAttendances = {};
  bool _isLoading = false;

  List<SessionModel> get sessions => _sessions;
  List<UserModel> get students => _students;
  Map<String, AttendanceModel> get sessionAttendances => _sessionAttendances;
  bool get isLoading => _isLoading;

  // Memuat daftar sesi presensi
  Future<void> fetchSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _dbService.getSessions(type: 'harian');
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Buka Sesi Harian Baru
  Future<void> openHarianSession(String classId, String creatorUid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      final sessionId = 'SESS-HARIAN-$classId-$dateStr';

      final newSession = SessionModel(
        id: sessionId,
        type: 'harian',
        classId: classId,
        createdBy: creatorUid,
        date: dateStr,
        timeStart: timeStr,
        status: 'active',
      );

      await _dbService.createSession(newSession);
      await fetchSessions();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tutup Sesi Harian
  Future<void> closeHarianSession(String sessionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      await _dbService.closeSession(sessionId, timeStr);
      await fetchSessions();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Memuat data siswa dan catatan kehadiran sesi
  Future<void> loadSessionDetails(String sessionId, String classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Ambil semua siswa di kelas bersangkutan
      final allUsers = await _dbService.getUsers(role: 'siswa');
      _students = allUsers.where((u) => u.classId == classId).toList();

      // 2. Ambil catatan kehadiran pada sesi bersangkutan
      final attendances = await _dbService.getAttendances(sessionId);
      _sessionAttendances = {
        for (var att in attendances) att.studentId: att
      };
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Validasi manual status kehadiran oleh guru piket
  Future<void> updateAttendanceManual({
    required String sessionId,
    required String studentId,
    required String status, // 'hadir' | 'izin' | 'sakit' | 'alpa'
    required String recorderUid,
    String? note,
  }) async {
    try {
      final attendance = AttendanceModel(
        studentId: studentId,
        status: status,
        timestamp: DateTime.now().toIso8601String(),
        method: 'manual_override',
        recordedBy: recorderUid,
        note: note,
      );

      await _dbService.recordAttendance(sessionId, studentId, attendance);
      
      // Update local state
      _sessionAttendances[studentId] = attendance;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
