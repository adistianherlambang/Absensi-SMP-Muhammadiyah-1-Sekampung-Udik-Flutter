class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' | 'guru_piket' | 'guru_mapel' | 'siswa'
  final String? classId; // Khusus siswa/wali kelas
  final List<String>? subjects; // Khusus guru mapel
  final String? qrCodeId; // Khusus siswa
  final String status; // 'active' | 'inactive'

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.classId,
    this.subjects,
    this.qrCodeId,
    this.status = 'active',
  });

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'siswa',
      classId: map['class_id'],
      subjects: map['subjects'] != null ? List<String>.from(map['subjects']) : null,
      qrCodeId: map['qr_code_id'],
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'class_id': classId,
      'subjects': subjects,
      'qr_code_id': qrCodeId,
      'status': status,
    };
  }
}
