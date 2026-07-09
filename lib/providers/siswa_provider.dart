import 'package:flutter/material.dart';
import '../core/services/db_service.dart';
import '../core/services/qr_service.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_request_model.dart';

class SiswaProvider with ChangeNotifier {
  final DBService _dbService = DBService();
  final QRService _qrService = QRService();

  List<SessionModel> _activeSessions = [];
  Map<String, AttendanceModel> _history = {};
  List<LeaveRequestModel> _leaveRequests = [];
  bool _isLoading = false;

  List<SessionModel> get activeSessions => _activeSessions;
  Map<String, AttendanceModel> get history => _history;
  List<LeaveRequestModel> get leaveRequests => _leaveRequests;
  bool get isLoading => _isLoading;

  // Memuat sesi presensi aktif untuk kelas siswa
  Future<void> fetchActiveSessions(String classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final sessions = await _dbService.getSessions(classId: classId, activeOnly: true);
      _activeSessions = sessions;
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Memuat riwayat presensi siswa
  Future<void> fetchAttendanceHistory(String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await _dbService.getStudentAttendanceHistory(studentId);
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Memuat pengajuan izin siswa
  Future<void> fetchLeaveRequests(String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _leaveRequests = await _dbService.getLeaveRequests(studentId: studentId);
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Memproses Scan QR untuk Presensi Mandiri Siswa
  Future<void> scanQRForPresence({
    required String qrContent,
    required String currentStudentUid,
    required String currentStudentQRId,
    required String sessionId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Parse konten QR
      final parsed = _qrService.parseQRContent(qrContent);
      if (parsed == null) {
        throw Exception("Format QR Code tidak valid / bukan milik sistem presensi ini.");
      }

      final studentId = parsed['student_id'];
      final qrCodeId = parsed['qr_code_id'];

      // 2. Validasi identitas QR Code vs User Login
      if (studentId != currentStudentUid || qrCodeId != currentStudentQRId) {
        throw Exception("QR Code tidak cocok dengan akun Anda yang sedang login.");
      }

      // 3. Cek apakah ada pengajuan izin/sakit untuk hari ini
      final sessionDoc = await _dbService.getSession(sessionId);
      if (sessionDoc != null) {
        final sessionDate = sessionDoc.date;
        final leaveRequests = await _dbService.getLeaveRequests(studentId: currentStudentUid);
        final todayLeave = leaveRequests.where((r) => r.date == sessionDate).toList();
        if (todayLeave.isNotEmpty) {
          final leave = todayLeave.first;
          final statusLabel = leave.status == 'sakit' ? 'Sakit' : 'Izin';
          throw Exception("Presensi ditolak karena Anda sudah mengajukan $statusLabel untuk hari ini.");
        }
      }

      // 4. Simpan catatan kehadiran ke Firebase
      final attendance = AttendanceModel(
        studentId: currentStudentUid,
        status: 'hadir',
        timestamp: DateTime.now().toIso8601String(),
        method: 'qr_scan',
        recordedBy: currentStudentUid,
        note: 'Presensi Mandiri via Scan QR',
      );

      await _dbService.recordAttendance(sessionId, currentStudentUid, attendance);
      await fetchAttendanceHistory(currentStudentUid);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengajukan izin
  Future<void> submitLeaveRequest({
    required String studentId,
    required String date,
    required String reason,
    required String status,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final reqId = 'REQ-${DateTime.now().millisecondsSinceEpoch}';
      final request = LeaveRequestModel(
        id: reqId,
        studentId: studentId,
        date: date,
        reason: reason,
        status: status,
        submittedAt: DateTime.now().toIso8601String(),
      );

      await _dbService.submitLeaveRequest(request);
      await fetchLeaveRequests(studentId);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengedit pengajuan izin
  Future<void> editLeaveRequest({
    required String requestId,
    required String studentId,
    required String oldDate,
    required String newDate,
    required String reason,
    required String status,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (oldDate != newDate) {
        await _dbService.deleteAttendanceForDate(studentId, oldDate);
      }
      await _dbService.updateLeaveRequest(requestId, newDate, status, reason);
      await fetchLeaveRequests(studentId);
      await fetchAttendanceHistory(studentId);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menghapus pengajuan izin
  Future<void> deleteLeaveRequest({
    required String requestId,
    required String studentId,
    required String date,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.deleteLeaveRequest(requestId);
      await _dbService.deleteAttendanceForDate(studentId, date);
      await fetchLeaveRequests(studentId);
      await fetchAttendanceHistory(studentId);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
