class LeaveRequestModel {
  final String id;
  final String studentId;
  final String date; // YYYY-MM-DD
  final String reason;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String submittedAt;
  final String? reviewedBy;

  LeaveRequestModel({
    required this.id,
    required this.studentId,
    required this.date,
    required this.reason,
    this.status = 'pending',
    required this.submittedAt,
    this.reviewedBy,
  });

  factory LeaveRequestModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return LeaveRequestModel(
      id: id,
      studentId: map['student_id'] ?? '',
      date: map['date'] ?? '',
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      submittedAt: map['submitted_at'] ?? '',
      reviewedBy: map['reviewed_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'date': date,
      'reason': reason,
      'status': status,
      'submitted_at': submittedAt,
      'reviewed_by': reviewedBy,
    };
  }
}
