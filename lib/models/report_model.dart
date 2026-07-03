class ReportModel {
  final String id;
  final String type; // 'harian' | 'mingguan' | 'bulanan' | 'semesteran'
  final String classId;
  final String periodStart;
  final String periodEnd;
  final String generatedBy;
  final String generatedAt;
  final Map<String, int> summary; // { 'hadir': x, 'izin': y, 'sakit': z, 'alpa': w }

  ReportModel({
    required this.id,
    required this.type,
    required this.classId,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedBy,
    required this.generatedAt,
    required this.summary,
  });

  factory ReportModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final summaryMap = map['summary'] as Map<dynamic, dynamic>? ?? {};
    return ReportModel(
      id: id,
      type: map['type'] ?? 'harian',
      classId: map['class_id'] ?? '',
      periodStart: map['period_start'] ?? '',
      periodEnd: map['period_end'] ?? '',
      generatedBy: map['generated_by'] ?? '',
      generatedAt: map['generated_at'] ?? '',
      summary: {
        'hadir': summaryMap['hadir'] ?? 0,
        'izin': summaryMap['izin'] ?? 0,
        'sakit': summaryMap['sakit'] ?? 0,
        'alpa': summaryMap['alpa'] ?? 0,
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'class_id': classId,
      'period_start': periodStart,
      'period_end': periodEnd,
      'generated_by': generatedBy,
      'generated_at': generatedAt,
      'summary': summary,
    };
  }
}
