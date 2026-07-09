import 'package:flutter/material.dart';
import '../core/services/db_service.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_request_model.dart';

class PiketProvider with ChangeNotifier {
  final DBService _dbService = DBService();
  
  List<SessionModel> _sessions = [];
  List<UserModel> _students = [];
  Map<String, AttendanceModel> _sessionAttendances = {};
  List<LeaveRequestModel> _classLeaveRequests = [];
  Map<String, Map<String, AttendanceModel>> _leavesAttendances = {};
  bool _isLoading = false;

  List<SessionModel> get sessions => _sessions;
  List<UserModel> get students => _students;
  Map<String, AttendanceModel> get sessionAttendances => _sessionAttendances;
  List<LeaveRequestModel> get classLeaveRequests => _classLeaveRequests;
  Map<String, Map<String, AttendanceModel>> get leavesAttendances => _leavesAttendances;
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

  // Memuat riwayat pengajuan izin siswa kelas (Wali Kelas)
  Future<void> fetchClassLeaveRequests(List<String> studentIds) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (studentIds.isEmpty) {
        _classLeaveRequests = [];
        _leavesAttendances = {};
        return;
      }
      final allLeaves = await _dbService.getLeaveRequests();
      _classLeaveRequests = allLeaves.where((l) => studentIds.contains(l.studentId)).toList();
      _classLeaveRequests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      // Ambil data user untuk mendapatkan classId
      final allUsers = await _dbService.getUsers(role: 'siswa');

      // Ambil kehadiran untuk setiap tanggal di leave requests
      _leavesAttendances = {};
      for (var req in _classLeaveRequests) {
        final student = allUsers.firstWhere(
          (u) => u.uid == req.studentId,
          orElse: () => UserModel(uid: req.studentId, name: '', email: '', role: 'siswa', classId: ''),
        );
        final classId = student.classId;
        if (classId != null && classId.isNotEmpty) {
          final sessionId = 'SESS-HARIAN-$classId-${req.date}';
          if (!_leavesAttendances.containsKey(sessionId)) {
            final list = await _dbService.getAttendances(sessionId);
            _leavesAttendances[sessionId] = {
              for (var att in list) att.studentId: att
            };
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

      // 3. Ambil pengajuan izin/sakit siswa untuk tanggal sesi ini
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

  // Memperbarui status presensi harian siswa (Hadir, Izin, Sakit, Alpa) untuk tanggal tertentu dari leave requests
  Future<void> updateAttendanceForLeaveRequest({
    required String studentId,
    required String classId,
    required String date,
    required String status, // 'hadir' | 'izin' | 'sakit' | 'alpa'
    required String recorderUid,
    String? note,
  }) async {
    try {
      final sessionId = 'SESS-HARIAN-$classId-$date';
      
      // Pastikan sesi harian ini ada
      final sessionExists = await _dbService.getSession(sessionId);
      if (sessionExists == null) {
        final newSession = SessionModel(
          id: sessionId,
          type: 'harian',
          classId: classId,
          createdBy: recorderUid,
          date: date,
          timeStart: '07:00',
          status: 'closed', // default closed
        );
        await _dbService.createSession(newSession);
      }

      final attendance = AttendanceModel(
        studentId: studentId,
        status: status,
        timestamp: DateTime.now().toIso8601String(),
        method: 'manual_override',
        recordedBy: recorderUid,
        note: note,
      );

      await _dbService.recordAttendance(sessionId, studentId, attendance);
      
      // Update local state map
      if (!_leavesAttendances.containsKey(sessionId)) {
        _leavesAttendances[sessionId] = {};
      }
      _leavesAttendances[sessionId]![studentId] = attendance;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
