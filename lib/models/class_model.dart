class ClassModel {
  final String id;
  final String name;
  final String homeroomTeacherId;
  final List<String> studentIds;

  ClassModel({
    required this.id,
    required this.name,
    required this.homeroomTeacherId,
    this.studentIds = const [],
  });

  factory ClassModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return ClassModel(
      id: id,
      name: map['name'] ?? '',
      homeroomTeacherId: map['homeroom_teacher_id'] ?? '',
      studentIds: map['student_ids'] != null 
          ? List<String>.from(map['student_ids']) 
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'homeroom_teacher_id': homeroomTeacherId,
      'student_ids': studentIds,
    };
  }
}
