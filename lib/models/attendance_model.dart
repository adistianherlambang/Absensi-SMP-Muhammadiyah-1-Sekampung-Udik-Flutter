class AttendanceModel {
  final String studentId;
  final String status; // 'hadir' | 'izin' | 'sakit' | 'alpa'
  final String timestamp; // ISO 8601
  final String method; // 'qr_scan' | 'manual_override'
  final String recordedBy;
  final String? note;

  AttendanceModel({
    required this.studentId,
    required this.status,
    required this.timestamp,
    required this.method,
    required this.recordedBy,
    this.note,
  });

  factory AttendanceModel.fromMap(String studentId, Map<dynamic, dynamic> map) {
    return AttendanceModel(
      studentId: studentId,
      status: map['status'] ?? 'alpa',
      timestamp: map['timestamp'] ?? '',
      method: map['method'] ?? 'manual_override',
      recordedBy: map['recorded_by'] ?? '',
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'timestamp': timestamp,
      'method': method,
      'recorded_by': recordedBy,
      'note': note,
    };
  }
}
