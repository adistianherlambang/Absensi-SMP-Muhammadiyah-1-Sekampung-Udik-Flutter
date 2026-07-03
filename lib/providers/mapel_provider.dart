import 'package:flutter/material.dart';
import '../core/services/db_service.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';

class MapelProvider with ChangeNotifier {
  final DBService _dbService = DBService();

  List<SessionModel> _sessions = [];
  List<UserModel> _students = [];
  Map<String, AttendanceModel> _sessionAttendances = {};
  bool _isLoading = false;

  List<SessionModel> get sessions => _sessions;
  List<UserModel> get students => _students;
  Map<String, AttendanceModel> get sessionAttendances => _sessionAttendances;
  bool get isLoading => _isLoading;

  // Memuat daftar sesi presensi mapel yang dibuat oleh guru bersangkutan
  Future<void> fetchSessions(String teacherUid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final allSessions = await _dbService.getSessions(type: 'mapel');
      _sessions = allSessions.where((s) => s.createdBy == teacherUid).toList();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Buka Sesi Mapel Baru
  Future<void> openMapelSession({
    required String classId,
    required String subject,
    required String creatorUid,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      final sessionId = 'SESS-MAPEL-$classId-${subject.replaceAll(' ', '_')}-$dateStr';

      final newSession = SessionModel(
        id: sessionId,
        type: 'mapel',
        classId: classId,
        subject: subject,
        createdBy: creatorUid,
        date: dateStr,
        timeStart: timeStr,
        status: 'active',
      );

      await _dbService.createSession(newSession);
      await fetchSessions(creatorUid);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tutup Sesi Mapel
  Future<void> closeMapelSession(String sessionId, String teacherUid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      await _dbService.closeSession(sessionId, timeStr);
      await fetchSessions(teacherUid);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Memuat data siswa dan absensi untuk sesi tertentu
  Future<void> loadSessionDetails(String sessionId, String classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final allUsers = await _dbService.getUsers(role: 'siswa');
      _students = allUsers.where((u) => u.classId == classId).toList();

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

  // Update kehadiran siswa oleh Guru Mapel
  Future<void> updateAttendance({
    required String sessionId,
    required String studentId,
    required String status,
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
      _sessionAttendances[studentId] = attendance;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
