import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/db_service.dart';
import '../core/services/qr_service.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';

class AdminProvider with ChangeNotifier {
  final DBService _dbService = DBService();
  final QRService _qrService = QRService();

  List<UserModel> _users = [];
  List<ClassModel> _classes = [];
  bool _isLoading = false;

  List<UserModel> get users => _users;
  List<ClassModel> get classes => _classes;
  bool get isLoading => _isLoading;

  // Ambil data User dan Kelas dari Firebase
  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _users = await _dbService.getUsers();
      _classes = await _dbService.getClasses();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tambah User baru (Admin/Guru/Siswa)
  // Menggunakan secondary Firebase App agar tidak memutus sesi login Admin saat ini
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? classId,
    List<String>? subjects,
  }) async {
    _isLoading = true;
    notifyListeners();

    FirebaseApp? tempApp;
    try {
      // 1. Buat user di Firebase Auth via Secondary App
      tempApp = await Firebase.initializeApp(
        name: 'TempRegisterApp',
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2. Buat QR Code ID khusus jika perannya siswa
      String? qrCodeId;
      if (role == 'siswa') {
        qrCodeId = 'QR-$uid';
      }

      // 3. Simpan data lengkap ke Realtime Database
      final newUser = UserModel(
        uid: uid,
        name: name,
        email: email,
        role: role,
        classId: classId,
        subjects: subjects,
        qrCodeId: qrCodeId,
        status: 'active',
      );

      await _dbService.saveUserProfile(newUser);

      // Jika role siswa, update list siswa di model Kelas bersangkutan
      if (role == 'siswa' && classId != null) {
        final cl = _classes.firstWhere((c) => c.id == classId);
        final updatedStudentIds = List<String>.from(cl.studentIds)..add(uid);
        final updatedClass = ClassModel(
          id: cl.id,
          name: cl.name,
          homeroomTeacherId: cl.homeroomTeacherId,
          studentIds: updatedStudentIds,
        );
        await _dbService.saveClass(updatedClass);
      }

      // Refresh list lokal
      await fetchData();
    } catch (e) {
      rethrow;
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hapus User
  Future<void> deleteUser(String uid, String role, String? classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.deleteUser(uid);

      // Jika siswa, hapus juga dari list siswa di kelasnya
      if (role == 'siswa' && classId != null) {
        try {
          final cl = _classes.firstWhere((c) => c.id == classId);
          final updatedStudentIds = List<String>.from(cl.studentIds)..remove(uid);
          final updatedClass = ClassModel(
            id: cl.id,
            name: cl.name,
            homeroomTeacherId: cl.homeroomTeacherId,
            studentIds: updatedStudentIds,
          );
          await _dbService.saveClass(updatedClass);
        } catch (e) {
          // Abaikan jika kelas tidak ditemukan
        }
      }

      if (role == 'guru_wali_kelas') {
        for (final cl in _classes) {
          if (cl.homeroomTeacherId == uid) {
            try {
              final updatedClass = ClassModel(
                id: cl.id,
                name: cl.name,
                homeroomTeacherId: '',
                studentIds: cl.studentIds,
              );
              await _dbService.saveClass(updatedClass);
            } catch (_) {}
          }
        }
      }

      await fetchData();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hapus Beberapa User (Batch)
  Future<void> deleteUsersBatch(List<UserModel> usersToDelete) async {
    _isLoading = true;
    notifyListeners();

    try {
      for (final user in usersToDelete) {
        await _dbService.deleteUser(user.uid);

        // Jika siswa, hapus juga dari list siswa di kelasnya
        if (user.role == 'siswa' && user.classId != null) {
          try {
            final cl = _classes.firstWhere((c) => c.id == user.classId);
            final updatedStudentIds = List<String>.from(cl.studentIds)..remove(user.uid);
            final updatedClass = ClassModel(
              id: cl.id,
              name: cl.name,
              homeroomTeacherId: cl.homeroomTeacherId,
              studentIds: updatedStudentIds,
            );
            await _dbService.saveClass(updatedClass);
          } catch (e) {
            // Abaikan jika kelas tidak ditemukan
          }
        }

        if (user.role == 'guru_wali_kelas') {
          for (final cl in _classes) {
            if (cl.homeroomTeacherId == user.uid) {
              try {
                final updatedClass = ClassModel(
                  id: cl.id,
                  name: cl.name,
                  homeroomTeacherId: '',
                  studentIds: cl.studentIds,
                );
                await _dbService.saveClass(updatedClass);
              } catch (_) {}
            }
          }
        }
      }

      await fetchData();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tambah Kelas baru
  Future<void> createClass(String name, String homeroomTeacherId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final classId = 'CLASS-${DateTime.now().millisecondsSinceEpoch}';
      final newClass = ClassModel(
        id: classId,
        name: name,
        homeroomTeacherId: homeroomTeacherId,
        studentIds: const [],
      );

      await _dbService.saveClass(newClass);
      await fetchData();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hapus Kelas
  Future<void> deleteClass(String classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbService.deleteClass(classId);
      await fetchData();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Perbarui User
  Future<void> updateUser({
    required String uid,
    required String name,
    required String role,
    String? classId,
    List<String>? subjects,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final existingUser = _users.firstWhere((u) => u.uid == uid);

      // 1. Update list kelas jika role siswa dan kelasnya berubah
      if (existingUser.role == 'siswa' && existingUser.classId != classId) {
        // Hapus dari kelas lama
        if (existingUser.classId != null) {
          try {
            final oldCl = _classes.firstWhere((c) => c.id == existingUser.classId);
            final updatedStudentIds = List<String>.from(oldCl.studentIds)..remove(uid);
            final updatedClass = ClassModel(
              id: oldCl.id,
              name: oldCl.name,
              homeroomTeacherId: oldCl.homeroomTeacherId,
              studentIds: updatedStudentIds,
            );
            await _dbService.saveClass(updatedClass);
          } catch (_) {}
        }
        // Tambah ke kelas baru
        if (classId != null) {
          try {
            final newCl = _classes.firstWhere((c) => c.id == classId);
            final updatedStudentIds = List<String>.from(newCl.studentIds)..add(uid);
            final updatedClass = ClassModel(
              id: newCl.id,
              name: newCl.name,
              homeroomTeacherId: newCl.homeroomTeacherId,
              studentIds: updatedStudentIds,
            );
            await _dbService.saveClass(updatedClass);
          } catch (_) {}
        }
      }

      // 2. Simpan data user ke database
      final updatedUser = UserModel(
        uid: uid,
        name: name,
        email: existingUser.email,
        role: role,
        classId: classId,
        subjects: subjects,
        qrCodeId: existingUser.qrCodeId,
        status: existingUser.status,
      );

      await _dbService.saveUserProfile(updatedUser);
      await fetchData();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Dapatkan String Data QR untuk Siswa
  String getStudentQRData(UserModel student) {
    if (student.qrCodeId == null) return '';
    return _qrService.generateQRContent(student.uid, student.qrCodeId!);
  }
}
