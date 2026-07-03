class SessionModel {
  final String id;
  final String type; // 'harian' | 'mapel'
  final String classId;
  final String? subject; // Hanya jika type = 'mapel'
  final String createdBy;
  final String date; // YYYY-MM-DD
  final String timeStart;
  final String? timeEnd;
  final String status; // 'active' | 'closed'

  SessionModel({
    required this.id,
    required this.type,
    required this.classId,
    this.subject,
    required this.createdBy,
    required this.date,
    required this.timeStart,
    this.timeEnd,
    this.status = 'active',
  });

  factory SessionModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return SessionModel(
      id: id,
      type: map['type'] ?? 'harian',
      classId: map['class_id'] ?? '',
      subject: map['subject'],
      createdBy: map['created_by'] ?? '',
      date: map['date'] ?? '',
      timeStart: map['time_start'] ?? '',
      timeEnd: map['time_end'],
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'class_id': classId,
      'subject': subject,
      'created_by': createdBy,
      'date': date,
      'time_start': timeStart,
      'time_end': timeEnd,
      'status': status,
    };
  }
}
