import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';
import '../../models/session_model.dart';
import '../../models/attendance_model.dart';
import '../../models/leave_request_model.dart';
import '../../models/report_model.dart';

class DBService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper untuk menambahkan timeout pada query get()
  Future<QuerySnapshot> _getWithTimeout(Query query) async {
    return await query.get().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception("Koneksi Firestore timeout. Periksa internet atau status database di Firebase Console."),
    );
  }

  // Helper untuk menambahkan timeout pada DocumentReference get()
  Future<DocumentSnapshot> _getDocWithTimeout(DocumentReference docRef) async {
    return await docRef.get().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception("Koneksi Firestore timeout. Periksa internet atau status database di Firebase Console."),
    );
  }

  // ==========================================
  // MANAJEMEN PENGGUNA (USERS)
  // ==========================================

  // Simpan / Perbarui profil user
  Future<void> saveUserProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  // Ambil semua pengguna berdasarkan peran
  Future<List<UserModel>> getUsers({String? role}) async {
    Query query = _firestore.collection('users');
    if (role != null) {
      query = query.where('role', isEqualTo: role);
    }
    final snapshot = await _getWithTimeout(query);
    return snapshot.docs.map((doc) {
      return UserModel.fromMap(doc.id, doc.data() as Map<dynamic, dynamic>);
    }).toList();
  }

  // Hapus pengguna
  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // ==========================================
  // MANAJEMEN KELAS (CLASSES)
  // ==========================================

  // Simpan / Perbarui kelas
  Future<void> saveClass(ClassModel classModel) async {
    await _firestore.collection('classes').doc(classModel.id).set(classModel.toMap(), SetOptions(merge: true));
  }

  // Ambil daftar kelas
  Future<List<ClassModel>> getClasses() async {
    final snapshot = await _getWithTimeout(_firestore.collection('classes'));
    return snapshot.docs.map((doc) {
      return ClassModel.fromMap(doc.id, doc.data() as Map<dynamic, dynamic>);
    }).toList();
  }

  // Hapus kelas
  Future<void> deleteClass(String classId) async {
    await _firestore.collection('classes').doc(classId).delete();
  }

  // ==========================================
  // SESI PRESENSI (SESSIONS)
  // ==========================================

  // Buka Sesi Presensi Baru
  Future<void> createSession(SessionModel session) async {
    await _firestore.collection('sessions').doc(session.id).set(session.toMap(), SetOptions(merge: true));
  }

  // Ambil daftar sesi (Filter kelas/tipe jika dibutuhkan)
  Future<List<SessionModel>> getSessions({String? classId, String? type, bool activeOnly = false}) async {
    Query query = _firestore.collection('sessions');
    if (classId != null) {
      query = query.where('class_id', isEqualTo: classId);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    if (activeOnly) {
      query = query.where('status', isEqualTo: 'active');
    }
    final snapshot = await _getWithTimeout(query);
    return snapshot.docs.map((doc) {
      return SessionModel.fromMap(doc.id, doc.data() as Map<dynamic, dynamic>);
    }).toList();
  }

  // Tutup Sesi Presensi
  Future<void> closeSession(String sessionId, String timeEnd) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'status': 'closed',
      'time_end': timeEnd,
    });
  }

  // Hapus Sesi Presensi beserta Catatan Kehadirannya
  Future<void> deleteSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).delete();
    await _firestore.collection('attendances').doc(sessionId).delete();
  }

  // ==========================================
  // CATATAN KEHADIRAN (ATTENDANCES)
  // ==========================================

  // Rekam Kehadiran Siswa
  Future<void> recordAttendance(String sessionId, String studentId, AttendanceModel attendance) async {
    await _firestore
        .collection('attendances')
        .doc(sessionId)
        .set({studentId: attendance.toMap()}, SetOptions(merge: true));
  }

  // Simpan / Perbarui Presensi Massal (Bulk) untuk satu sesi
  Future<void> saveBulkAttendance(String sessionId, Map<String, AttendanceModel> attendances) async {
    final Map<String, dynamic> data = {};
    attendances.forEach((studentId, att) {
      data[studentId] = att.toMap();
    });
    await _firestore.collection('attendances').doc(sessionId).set(data);
  }

  // Ambil Kehadiran per Sesi
  Future<List<AttendanceModel>> getAttendances(String sessionId) async {
    final doc = await _getDocWithTimeout(_firestore.collection('attendances').doc(sessionId));
    if (!doc.exists || doc.data() == null) return [];

    final data = doc.data() as Map<dynamic, dynamic>;
    final List<AttendanceModel> list = [];
    data.forEach((key, value) {
      list.add(AttendanceModel.fromMap(key.toString(), value as Map<dynamic, dynamic>));
    });
    return list;
  }

  // Ambil Kehadiran Siswa di Semua Sesi
  Future<Map<String, AttendanceModel>> getStudentAttendanceHistory(String studentId) async {
    final snapshot = await _getWithTimeout(_firestore.collection('attendances'));
    final Map<String, AttendanceModel> history = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<dynamic, dynamic>? ?? {};
      if (data.containsKey(studentId)) {
        history[doc.id] = AttendanceModel.fromMap(
          studentId,
          data[studentId] as Map<dynamic, dynamic>,
        );
      }
    }
    return history;
  }

  // ==========================================
  // PENGAJUAN IZIN SISWA (LEAVE REQUESTS)
  // ==========================================

  // Ajukan Izin
  Future<void> submitLeaveRequest(LeaveRequestModel request) async {
    await _firestore.collection('leave_requests').doc(request.id).set(request.toMap());
  }

  // Ambil Semua Pengajuan Izin
  Future<List<LeaveRequestModel>> getLeaveRequests({String? studentId}) async {
    Query query = _firestore.collection('leave_requests');
    if (studentId != null) {
      query = query.where('student_id', isEqualTo: studentId);
    }
    final snapshot = await _getWithTimeout(query);
    return snapshot.docs.map((doc) {
      return LeaveRequestModel.fromMap(doc.id, doc.data() as Map<dynamic, dynamic>);
    }).toList();
  }

  // Tinjau Pengajuan Izin (Setujui / Tolak)
  Future<void> reviewLeaveRequest(String requestId, String status, String reviewedBy) async {
    await _firestore.collection('leave_requests').doc(requestId).update({
      'status': status,
      'reviewed_by': reviewedBy,
    });
  }

  // ==========================================
  // MANAJEMEN LAPORAN (REPORTS)
  // ==========================================

  // Simpan Laporan
  Future<void> saveReport(ReportModel report) async {
    await _firestore.collection('reports').doc(report.id).set(report.toMap());
  }

  // Ambil Daftar Laporan
  Future<List<ReportModel>> getReports({String? classId}) async {
    Query query = _firestore.collection('reports');
    if (classId != null) {
      query = query.where('class_id', isEqualTo: classId);
    }
    final snapshot = await _getWithTimeout(query);
    return snapshot.docs.map((doc) {
      return ReportModel.fromMap(doc.id, doc.data() as Map<dynamic, dynamic>);
    }).toList();
  }
}
