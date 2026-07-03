import 'package:firebase_database/firebase_database.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';
import '../../models/session_model.dart';
import '../../models/attendance_model.dart';
import '../../models/leave_request_model.dart';
import '../../models/report_model.dart';

class DBService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // ==========================================
  // MANAJEMEN PENGGUNA (USERS)
  // ==========================================

  // Simpan / Perbarui profil user
  Future<void> saveUserProfile(UserModel user) async {
    await _dbRef.child('users').child(user.uid).set(user.toMap());
  }

  // Ambil semua pengguna berdasarkan peran
  Future<List<UserModel>> getUsers({String? role}) async {
    final snapshot = await _dbRef.child('users').get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final List<UserModel> list = [];
    data.forEach((key, value) {
      final user = UserModel.fromMap(key.toString(), value as Map<dynamic, dynamic>);
      if (role == null || user.role == role) {
        list.add(user);
      }
    });
    return list;
  }

  // Hapus pengguna
  Future<void> deleteUser(String uid) async {
    await _dbRef.child('users').child(uid).remove();
  }

  // ==========================================
  // MANAJEMEN KELAS (CLASSES)
  // ==========================================

  // Simpan / Perbarui kelas
  Future<void> saveClass(ClassModel classModel) async {
    await _dbRef.child('classes').child(classModel.id).set(classModel.toMap());
  }

  // Ambil daftar kelas
  Future<List<ClassModel>> getClasses() async {
    final snapshot = await _dbRef.child('classes').get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final List<ClassModel> list = [];
    data.forEach((key, value) {
      list.add(ClassModel.fromMap(key.toString(), value as Map<dynamic, dynamic>));
    });
    return list;
  }

  // Hapus kelas
  Future<void> deleteClass(String classId) async {
    await _dbRef.child('classes').child(classId).remove();
  }

  // ==========================================
  // SESI PRESENSI (SESSIONS)
  // ==========================================

  // Buka Sesi Presensi Baru
  Future<void> createSession(SessionModel session) async {
    await _dbRef.child('sessions').child(session.id).set(session.toMap());
  }

  // Ambil daftar sesi (Filter kelas/tipe jika dibutuhkan)
  Future<List<SessionModel>> getSessions({String? classId, String? type, bool activeOnly = false}) async {
    final snapshot = await _dbRef.child('sessions').get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final List<SessionModel> list = [];
    data.forEach((key, value) {
      final session = SessionModel.fromMap(key.toString(), value as Map<dynamic, dynamic>);
      bool match = true;
      if (classId != null && session.classId != classId) match = false;
      if (type != null && session.type != type) match = false;
      if (activeOnly && session.status != 'active') match = false;
      if (match) {
        list.add(session);
      }
    });
    return list;
  }

  // Tutup Sesi Presensi
  Future<void> closeSession(String sessionId, String timeEnd) async {
    await _dbRef.child('sessions').child(sessionId).update({
      'status': 'closed',
      'time_end': timeEnd,
    });
  }

  // ==========================================
  // CATATAN KEHADIRAN (ATTENDANCES)
  // ==========================================

  // Rekam Kehadiran Siswa
  Future<void> recordAttendance(String sessionId, String studentId, AttendanceModel attendance) async {
    await _dbRef
        .child('attendances')
        .child(sessionId)
        .child(studentId)
        .set(attendance.toMap());
  }

  // Ambil Kehadiran per Sesi
  Future<List<AttendanceModel>> getAttendances(String sessionId) async {
    final snapshot = await _dbRef.child('attendances').child(sessionId).get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final List<AttendanceModel> list = [];
    data.forEach((key, value) {
      list.add(AttendanceModel.fromMap(key.toString(), value as Map<dynamic, dynamic>));
    });
    return list;
  }

  // Ambil Kehadiran Siswa di Semua Sesi
  Future<Map<String, AttendanceModel>> getStudentAttendanceHistory(String studentId) async {
    final snapshot = await _dbRef.child('attendances').get();
    if (!snapshot.exists || snapshot.value == null) return {};

    final data = snapshot.value as Map<dynamic, dynamic>;
    final Map<String, AttendanceModel> history = {};
    data.forEach((sessionId, value) {
      final sessionData = value as Map<dynamic, dynamic>;
      if (sessionData.containsKey(studentId)) {
        history[sessionId.toString()] = AttendanceModel.fromMap(
          studentId,
          sessionData[studentId] as Map<dynamic, dynamic>,
        );
      }
    });
    return history;
  }

  // ==========================================
  // PENGAJUAN IZIN SISWA (LEAVE REQUESTS)
  // ==========================================

  // Ajukan Izin
  Future<void> submitLeaveRequest(LeaveRequestModel request) async {
    await _dbRef.child('leave_requests').child(request.id).set(request.toMap());
  }

  // Ambil Semua Pengajuan Izin
  Future<List<LeaveRequestModel>> getLeaveRequests({String? studentId}) async {
    final snapshot = await _dbRef.child('leave_requests').get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final List<LeaveRequestModel> list = [];
    data.forEach((key, value) {
      final req = LeaveRequestModel.fromMap(key.toString(), value as Map<dynamic, dynamic>);
      if (studentId == null || req.studentId == studentId) {
        list.add(req);
      }
    });
    return list;
  }

  // Tinjau Pengajuan Izin (Setujui / Tolak)
  Future<void> reviewLeaveRequest(String requestId, String status, String reviewedBy) async {
    await _dbRef.child('leave_requests').child(requestId).update({
      'status': status,
      'reviewed_by': reviewedBy,
    });
  }

  // ==========================================
  // MANAJEMEN LAPORAN (REPORTS)
  // ==========================================

  // Simpan Laporan
  Future<void> saveReport(ReportModel report) async {
    await _dbRef.child('reports').child(report.id).set(report.toMap());
  }

  // Ambil Daftar Laporan
  Future<List<ReportModel>> getReports({String? classId}) async {
    final snapshot = await _dbRef.child('reports').get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final List<ReportModel> list = [];
    data.forEach((key, value) {
      final report = ReportModel.fromMap(key.toString(), value as Map<dynamic, dynamic>);
      if (classId == null || report.classId == classId) {
        list.add(report);
      }
    });
    return list;
  }
}
