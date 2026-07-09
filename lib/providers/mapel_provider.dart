import 'package:flutter/material.dart';
import '../core/services/db_service.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_request_model.dart';

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

      // Cek pengajuan izin/sakit siswa untuk tanggal sesi ini
      final session = await _dbService.getSession(sessionId);
      final dateStr = session?.date ?? '';
      final leaveRequests = await _dbService.getLeaveRequests();
      final todayLeaves = leaveRequests.where((l) => l.date == dateStr).toList();

      for (var student in _students) {
        if (!_sessionAttendances.containsKey(student.uid)) {
          LeaveRequestModel? studentLeave;
          for (var l in todayLeaves) {
            if (l.studentId == student.uid) {
              studentLeave = l;
              break;
            }
          }

          if (studentLeave != null) {
            final autoAttendance = AttendanceModel(
              studentId: student.uid,
              status: studentLeave.status, // 'sakit' or 'izin'
              timestamp: DateTime.now().toIso8601String(),
              method: 'leave_request',
              recordedBy: 'system',
              note: studentLeave.reason,
            );

            await _dbService.recordAttendance(sessionId, student.uid, autoAttendance);
            _sessionAttendances[student.uid] = autoAttendance;
          }
        }
      }
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

  // Kirim presensi kelas secara massal (bulk)
  Future<void> submitClassAttendance({
    required String classId,
    required String subject,
    required String teacherUid,
    required Map<String, String> studentStatuses,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      
      final sessionId = 'SESS-MAPEL-$classId-${subject.replaceAll(' ', '_')}-${now.millisecondsSinceEpoch}';

      final session = SessionModel(
        id: sessionId,
        type: 'mapel',
        classId: classId,
        subject: subject,
        createdBy: teacherUid,
        date: dateStr,
        timeStart: timeStr,
        timeEnd: timeStr,
        status: 'closed',
      );
      await _dbService.createSession(session);

      // Cek pengajuan izin hari ini untuk presensi massal
      final leaveRequests = await _dbService.getLeaveRequests();
      final todayLeaves = leaveRequests.where((l) => l.date == dateStr).toList();

      final Map<String, AttendanceModel> attendances = {};
      studentStatuses.forEach((studentId, status) {
        LeaveRequestModel? studentLeave;
        for (var l in todayLeaves) {
          if (l.studentId == studentId) {
            studentLeave = l;
            break;
          }
        }

        attendances[studentId] = AttendanceModel(
          studentId: studentId,
          status: status,
          timestamp: now.toIso8601String(),
          method: studentLeave != null ? 'leave_request' : 'manual_override',
          recordedBy: teacherUid,
          note: studentLeave != null ? studentLeave.reason : 'Presensi Massal oleh Guru Mapel',
        );
      });

      await _dbService.saveBulkAttendance(sessionId, attendances);
      await fetchSessions(teacherUid);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Perbarui presensi kelas secara massal (bulk)
  Future<void> updateClassAttendance({
    required String sessionId,
    required String teacherUid,
    required Map<String, String> studentStatuses,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final Map<String, AttendanceModel> attendances = {};
      studentStatuses.forEach((studentId, status) {
        attendances[studentId] = AttendanceModel(
          studentId: studentId,
          status: status,
          timestamp: now.toIso8601String(),
          method: 'manual_override',
          recordedBy: teacherUid,
        );
      });

      await _dbService.saveBulkAttendance(sessionId, attendances);
      _sessionAttendances = attendances;
      await fetchSessions(teacherUid);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hapus sesi presensi kelas beserta catatannya
  Future<void> deleteClassAttendance({
    required String sessionId,
    required String teacherUid,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.deleteSession(sessionId);
      await fetchSessions(teacherUid);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
