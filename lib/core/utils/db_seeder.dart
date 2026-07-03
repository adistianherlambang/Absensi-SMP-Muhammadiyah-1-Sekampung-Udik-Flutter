import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';

class DatabaseSeeder {
  static Future<void> seedTestData() async {
    final FirebaseApp primaryApp = Firebase.app();
    
    // Gunakan secondary app agar tidak merusak session login aktif pada primary app
    final FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'TempSeederApp',
      options: primaryApp.options,
    );

    final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
    final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
      app: primaryApp, // Hubungkan ke database utama
    ).ref();

    // Data Pengguna yang Akan Dibuat
    final List<Map<String, dynamic>> testUsers = [
      {
        'email': 'admin@smpm1.sch.id',
        'password': 'admin123',
        'name': 'Elen (Admin)',
        'role': 'admin',
      },
      {
        'email': 'piket@smpm1.sch.id',
        'password': 'piket123',
        'name': 'Budi Hartono (Piket)',
        'role': 'guru_piket',
      },
      {
        'email': 'mapel@smpm1.sch.id',
        'password': 'mapel123',
        'name': 'Siti Rahma (Guru Mapel)',
        'role': 'guru_mapel',
        'subjects': ['Matematika', 'IPA'],
      },
      {
        'email': 'siswa1@smpm1.sch.id',
        'password': 'siswa123',
        'name': 'Ahmad Fauzi (Siswa IX-A)',
        'role': 'siswa',
        'class_id': 'CLASS-IX-A',
      },
      {
        'email': 'siswa2@smpm1.sch.id',
        'password': 'siswa123',
        'name': 'Lestari Putri (Siswa IX-A)',
        'role': 'siswa',
        'class_id': 'CLASS-IX-A',
      }
    ];

    try {
      // 1. Buat data Kelas IX-A terlebih dahulu
      final classModel = ClassModel(
        id: 'CLASS-IX-A',
        name: 'IX-A',
        homeroomTeacherId: '', // Diisi setelah uid guru piket diketahui
        studentIds: [],
      );
      await dbRef.child('classes').child('CLASS-IX-A').set(classModel.toMap()).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException(
          'Koneksi ke Firebase Realtime Database timeout. Pastikan Anda telah membuat/mengaktifkan Realtime Database di Firebase Console dan aturan keamanan (Rules) mengizinkan penulisan.',
        ),
      );

      String guruPiketUid = '';
      List<String> studentUids = [];

      // 2. Buat akun Auth dan tulis profil pengguna di Realtime Database
      for (var u in testUsers) {
        UserCredential creds;
        try {
          creds = await tempAuth.createUserWithEmailAndPassword(
            email: u['email'],
            password: u['password'],
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // Jika akun sudah ada di Auth, kita coba login untuk mendapatkan UID nya
            creds = await tempAuth.signInWithEmailAndPassword(
              email: u['email'],
              password: u['password'],
            );
          } else {
            rethrow;
          }
        }

        final uid = creds.user!.uid;

        if (u['role'] == 'guru_piket') {
          guruPiketUid = uid;
        } else if (u['role'] == 'siswa') {
          studentUids.add(uid);
        }

        final userProfile = UserModel(
          uid: uid,
          name: u['name'],
          email: u['email'],
          role: u['role'],
          classId: u['class_id'],
          subjects: u['subjects'] != null ? List<String>.from(u['subjects']) : null,
          qrCodeId: u['role'] == 'siswa' ? 'QR-$uid' : null,
          status: 'active',
        );

        await dbRef.child('users').child(uid).set(userProfile.toMap()).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException(
            'Gagal menyimpan profil pengguna ke database (Timeout).',
          ),
        );
      }

      // 3. Update Kelas IX-A dengan data wali kelas dan daftar siswa yang valid
      final updatedClass = ClassModel(
        id: 'CLASS-IX-A',
        name: 'IX-A',
        homeroomTeacherId: guruPiketUid,
        studentIds: studentUids,
      );
      await dbRef.child('classes').child('CLASS-IX-A').set(updatedClass.toMap()).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException(
          'Gagal memperbarui data kelas ke database (Timeout).',
        ),
      );

    } finally {
      await tempApp.delete();
    }
  }
}
