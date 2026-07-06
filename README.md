# 📱 Aplikasi Presensi Siswa Berbasis Mobile
### SMP Muhammadiyah 1 Sekampung Udik

> **Perancangan Aplikasi Presensi Siswa Berbasis Mobile untuk Mendukung Kinerja Guru Piket pada SMP Muhammadiyah 1 Sekampung Udik**
>
> Disusun oleh: **Elen Novita Sari** (NPM 22430117)  
> Program Studi S1 Ilmu Komputer — Universitas Muhammadiyah Metro, 2025  
> Metode Pengembangan: **RAD (Rapid Application Development)**

---

## 📋 Daftar Isi

- [Overview Proyek](#-overview-proyek)
- [Fitur Utama & Keunggulan Sistem](#-fitur-utama--keunggulan-sistem)
- [Struktur Direktori](#-struktur-direktori)
- [Alur Kerja Utama Sistem](#-alur-kerja-utama-sistem)
- [Validasi & Logika Teknis Khusus](#-validasi--logika-teknis-khusus)
- [Dependensi Project](#-dependensi-project)
- [Panduan Instalasi](#-panduan-instalasi)
- [Kredensial Akun Bawaan](#-kredensial-akun-bawaan)
- [Ringkasan Tech Stack](#-ringkasan-tech-stack)

---

## 🏫 Overview Proyek

| Item | Keterangan |
|---|---|
| **Nama Proyek** | Aplikasi Presensi Siswa Berbasis Mobile |
| **Studi Kasus** | SMP Muhammadiyah 1 Sekampung Udik, Kec. Sekampung Udik, Lampung Timur |
| **Akreditasi Sekolah** | B |
| **Jumlah Siswa** | ±304 siswa (kelas VII–IX) |
| **Jumlah Guru/Staf** | 27 orang |
| **Ruang Lingkup Implementasi QR** | **Fokus: Siswa Kelas 9 (IX)** |
| **Versi Aplikasi** | 1.0.0+1 |
| **Platform** | Android (utama), iOS (opsional) |

### Latar Belakang Masalah

Sistem presensi di SMP Muhammadiyah 1 Sekampung Udik sebelumnya masih dilakukan **secara manual berbasis kertas**, yang mengakibatkan berbagai permasalahan:

- 📄 **Data mudah hilang/terselip** — lembar absensi fisik rentan rusak
- 🔄 **Data tidak sinkron** antara absensi harian (wali kelas) dan absensi per mata pelajaran (guru mapel)
- ⏳ **Rekap lambat** — rekapitulasi mingguan/bulanan memakan waktu lama
- 📊 **Laporan tidak real-time** — guru piket dan kepala sekolah tidak dapat memantau kehadiran secara langsung

### Solusi yang Ditawarkan

Aplikasi mobile berbasis **QR Code** dengan:
- ✅ Penyimpanan terpusat & **real-time** di Firebase
- ✅ **RBAC (Role-Based Access Control)** berjenjang untuk 4 peran pengguna
- ✅ Sinkronisasi data lintas peran tanpa konflik
- ✅ Rekap otomatis dari harian → mingguan → bulanan → semesteran

---

## 🌟 Fitur Utama & Keunggulan Sistem

### 👑 Modul Admin

| Fitur | Deskripsi |
|---|---|
| **Kelola Pengguna** | CRUD lengkap semua akun (admin, guru piket, guru mapel, siswa) |
| **Import Bulk Excel** | Upload pengguna massal via file `.xlsx` dengan template yang dapat diunduh |
| **Kelola Kelas** | CRUD kelas beserta penugasan wali kelas |
| **Generate QR Code** | Generate QR unik per siswa kelas 9 dengan tanda tangan digital (`SMP-MUH-1-ABSENSI-SECURE`) |
| **Export QR** | Export kartu QR siswa sebagai gambar (Share) |
| **Laporan Komprehensif** | Rekap presensi harian/mingguan/bulanan/semesteran dengan statistik ringkasan |
| **Filter & Pencarian** | Pencarian pengguna berdasarkan nama, filter berdasarkan kelas |

### 🛡️ Modul Guru Piket

| Fitur | Deskripsi |
|---|---|
| **Dashboard Real-time** | Pantau kehadiran siswa seluruh kelas secara langsung |
| **Buka/Tutup Sesi Harian** | Buat sesi presensi harian per kelas dengan timestamp otomatis |
| **Validasi Kehadiran** | Override status kehadiran siswa (Hadir / Izin / Sakit / Alpa) + catatan |
| **Rekap Mingguan** | Generate rekap akhir minggu dengan statistik per kelas |
| **Unduh Laporan** | Export rekap kehadiran harian |

### 📚 Modul Guru Mata Pelajaran

| Fitur | Deskripsi |
|---|---|
| **Scan QR Kelas** | Scan QR kelas untuk terhubung ke sesi mata pelajaran |
| **Buka/Tutup Sesi Mapel** | Kelola sesi presensi per jam pelajaran yang diampu |
| **Tandai Kehadiran** | Input kehadiran siswa per sesi mapel (manual atau via scan) |
| **Catatan Disiplin** | Tambahkan catatan keterlambatan/pelanggaran ke rekaman kehadiran |
| **Riwayat Sesi** | Lihat histori seluruh sesi mapel yang pernah dibuka |

### 🎓 Modul Siswa

| Fitur | Deskripsi |
|---|---|
| **Scan QR Presensi** | Presensi mandiri dengan scan QR Code diri sendiri dalam sesi aktif |
| **Dashboard Personal** | Tampilan kehadiran hari ini + statistik ringkasan |
| **Riwayat Kehadiran** | Lihat seluruh histori kehadiran dengan filter status |
| **Ajukan Izin Digital** | Submit formulir pengajuan izin/keterangan ketidakhadiran |
| **Status Izin** | Pantau status pengajuan izin (pending / approved / rejected) |

### ⚡ Keunggulan Teknis

- 🔒 **Double-layer Security**: RBAC di level UI (route guard) **dan** di Firebase Security Rules
- ⚡ **Timeout Handling**: Semua query Firestore memiliki timeout 10 detik dengan pesan error yang jelas
- 📦 **QR Signature Validation**: Setiap QR divalidasi tanda tangan `SMP-MUH-1-ABSENSI-SECURE` sebelum diproses
- 🎨 **Animated UI**: Micro-animation menggunakan `flutter_animate` untuk pengalaman pengguna premium
- 📊 **Bulk Operations**: Import pengguna massal via Excel tanpa perlu input satu per satu

---

## 📁 Struktur Direktori

```
flutter_application_1/
├── 📄 pubspec.yaml                    # Konfigurasi dependensi & metadata proyek
├── 📄 firestore.rules                 # Firebase Security Rules (RBAC backend)
├── 📄 database_schema.sql             # Skema MySQL pendukung (untuk ERD & dokumentasi skripsi)
├── 📄 firebase_rules.json             # Firebase Rules dalam format JSON
├── 📄 agent.md                        # Panduan pengembangan & spesifikasi sistem
│
└── lib/
    ├── 📄 main.dart                   # Entry point aplikasi & inisialisasi Firebase
    ├── 📄 firebase_options.dart        # Konfigurasi Firebase (generated by FlutterFire CLI)
    │
    ├── app/
    │   ├── 📄 routes.dart             # Definisi semua named routes (RBAC route guard)
    │   └── 📄 theme.dart              # Design system: warna, tipografi, komponen global
    │
    ├── core/
    │   ├── services/
    │   │   ├── 📄 auth_service.dart       # Wrapper Firebase Auth (login, logout, getUserProfile)
    │   │   ├── 📄 db_service.dart         # Wrapper Firestore (CRUD: users, classes, sessions, dst)
    │   │   ├── 📄 qr_service.dart         # Generator & parser QR Code (encode Base64 + signature)
    │   │   └── 📄 qr_card_renderer.dart   # Renderer kartu QR siswa untuk export/share
    │   └── utils/
    │
    ├── models/
    │   ├── 📄 user_model.dart             # uid, name, role, class_id, subjects, qr_code_id, status
    │   ├── 📄 class_model.dart            # id, name, homeroom_teacher_id, student_ids
    │   ├── 📄 session_model.dart          # id, type, class_id, subject, date, time_start/end, status
    │   ├── 📄 attendance_model.dart       # student_id, status, timestamp, method, recorded_by, note
    │   ├── 📄 leave_request_model.dart    # id, student_id, date, reason, status, reviewed_by
    │   └── 📄 report_model.dart           # id, type, class_id, period_start/end, summary
    │
    ├── providers/                         # State management (Provider pattern)
    │   ├── 📄 auth_provider.dart          # Auth state: login, logout, refreshProfile, RBAC routing
    │   ├── 📄 admin_provider.dart         # State admin: users, classes, QR generate, reports
    │   ├── 📄 piket_provider.dart         # State guru piket: sessions, attendance validation
    │   ├── 📄 mapel_provider.dart         # State guru mapel: mapel sessions, attendance per mapel
    │   └── 📄 siswa_provider.dart         # State siswa: scan QR, history, leave requests
    │
    ├── screens/
    │   ├── auth/
    │   │   └── 📄 login_screen.dart           # Halaman login (shared semua role)
    │   │
    │   ├── admin/
    │   │   ├── 📄 admin_dashboard.dart        # Dashboard admin: statistik global
    │   │   ├── 📄 manage_users_screen.dart    # Kelola pengguna: CRUD + import Excel + filter/search
    │   │   ├── 📄 manage_classes_screen.dart  # Kelola kelas: CRUD kelas & penugasan wali kelas
    │   │   ├── 📄 generate_qr_screen.dart     # Generate & export QR Code siswa kelas 9
    │   │   └── 📄 reports_screen.dart         # Laporan presensi komprehensif
    │   │
    │   ├── guru_piket/
    │   │   ├── 📄 piket_dashboard.dart            # Dashboard guru piket: monitoring real-time
    │   │   ├── 📄 open_session_screen.dart         # Buka/tutup sesi presensi harian
    │   │   ├── 📄 validate_attendance_screen.dart  # Validasi & override status kehadiran
    │   │   └── 📄 weekly_recap_screen.dart         # Rekap mingguan
    │   │
    │   ├── guru_mapel/
    │   │   ├── 📄 mapel_dashboard.dart            # Dashboard guru mapel: daftar sesi mapel
    │   │   ├── 📄 open_mapel_session_screen.dart  # Buka/tutup sesi presensi mapel
    │   │   └── 📄 mapel_attendance_screen.dart    # Input kehadiran per sesi mapel
    │   │
    │   ├── guru/                                  # Modul tambahan guru via scan kelas
    │   │   ├── 📄 scan_class_qr_screen.dart       # Scan QR kelas sebagai entry point
    │   │   ├── 📄 input_attendance_screen.dart    # Input kehadiran setelah scan kelas
    │   │   └── 📄 history_screen.dart             # Riwayat sesi & kehadiran guru
    │   │
    │   └── siswa/
    │       ├── 📄 siswa_dashboard.dart            # Dashboard siswa: kehadiran hari ini + statistik
    │       ├── 📄 scan_qr_screen.dart             # Scan QR Code diri sendiri untuk presensi
    │       ├── 📄 attendance_history_screen.dart  # Riwayat kehadiran pribadi
    │       └── 📄 leave_request_screen.dart       # Form pengajuan izin digital
    │
    └── widgets/
        ├── 📄 glass_card.dart          # Reusable glassmorphism card widget
        └── 📄 searchable_select.dart   # Dropdown dengan fitur pencarian
```

---

## 🔄 Alur Kerja Utama Sistem

### 1. Alur Login & Routing RBAC

```
[User membuka app]
        │
        ▼
[Login Screen] ── (email + password) ──▶ [Firebase Auth]
        │                                       │
        │                           Auth berhasil → getUserProfile(uid)
        │                           Ambil role dari Firestore /users/{uid}
        │
        ▼
[AuthProvider menentukan route]
        │
        ├── role: "admin"       ──▶ /admin   (AdminDashboard)
        ├── role: "guru_piket"  ──▶ /piket   (PiketDashboard)
        ├── role: "guru_mapel"  ──▶ /mapel   (MapelDashboard)
        └── role: "siswa"       ──▶ /siswa   (SiswaDashboard)
```

> ⚠️ Setiap screen dilindungi **route guard** yang memverifikasi `role` dari Firebase sebelum render — akses lintas peran secara otomatis ditolak.

---

### 2. Alur Presensi Harian (QR Code Siswa)

```
[Guru Piket]                      [Sistem]                       [Siswa]
     │                                │                              │
     ▼                                │                              │
Buka Sesi Harian ──────────▶ Buat /sessions/{id}                    │
(pilih kelas, tanggal)         status: "active"                     │
     │                                │              Scan QR Code ◀──┤
     │                                │              (kamera terbuka) │
     │                     ① Decode Base64 QR                        │
     │                     ② Verifikasi app signature                │
     │                     ③ Ambil student_id + qr_code_id          │
     │                     ④ Cek sesi aktif kelas siswa             │
     │                     ⑤ Tulis /attendances/{session}/{student} │
     │                        { status:"hadir", method:"qr_scan" }  │
     │                                │                              ▼
     ▼                                │                    Konfirmasi Berhasil
Validasi Manual (jika perlu)          │
Override status: izin/sakit/alpa      │
     │                                │
     ▼                                │
Tutup Sesi ──────────────▶ Update status: "closed" + time_end
     │
     ▼
Rekap Mingguan ──────────▶ Agregasi 5 hari → summary {hadir, izin, sakit, alpa}
```

---

### 3. Alur Presensi Mata Pelajaran

```
[Guru Mapel]                    [Sistem]
     │                              │
     ▼                              │
Buka Sesi Mapel ──────▶ Buat /sessions/{id}  type:"mapel"
(pilih kelas + mapel)   status: "active"
     │                              │
     ▼                              │
Input Kehadiran Siswa ────▶ Tulis /attendances/{session_id}
(satu per satu)            method: "manual_override"
                           recorded_by: guru_uid
     │                              │
     ▼                              │
Tutup Sesi ──────────────▶ Update status: "closed"
```

---

### 4. Alur Pengajuan Izin Siswa

```
[Siswa]                        [Sistem]                 [Guru Piket/Admin]
   │                               │                            │
   ▼                               │                            │
Isi Form Izin ─────────▶ Buat /leave_requests/{id}             │
(tanggal + alasan)         status: "pending"                   │
   │                               │                            │
   │                    Notifikasi ───────────────────▶ Review pengajuan
   │                               │                   (setujui / tolak)
   │                    Update status ◀─────────────── approved / rejected
   │                               │
   ▼                               │
Pantau Status ◀────────── Real-time update di dashboard siswa
```

---

## 🔐 Validasi & Logika Teknis Khusus

### 1. QR Code — Enkoding & Validasi

**Proses Generate:**
```
{ "app": "SMP-MUH-1-ABSENSI-SECURE", "student_id": "...", "qr_code_id": "..." }
    │
    ▼  jsonEncode → UTF-8 encode → Base64 encode
    │
[String QR yang di-embed ke QR Code image]
```

**Proses Validasi saat Scan:**
1. Decode Base64 → JSON parse
2. Periksa field `app` == `"SMP-MUH-1-ABSENSI-SECURE"` → jika tidak cocok, **tolak**
3. Ambil `student_id` dan `qr_code_id`
4. Cek ada sesi aktif untuk kelas siswa → jika tidak ada, **tolak** dengan pesan jelas
5. Cek siswa belum tercatat di sesi ini → jika sudah, **tolak** (cegah double entry)
6. Semua lolos → tulis record kehadiran `{ status: "hadir", method: "qr_scan" }`

**QR Kelas (untuk Guru Mapel):**
```
{ "app": "SMP-MUH-1-ABSENSI-SECURE", "class_id": "..." }
```
Digunakan guru mapel untuk masuk ke sesi kelas tertentu via scan.

---

### 2. RBAC — Firebase Security Rules

```
Koleksi           │ Admin │ Guru Piket    │ Guru Mapel │ Siswa
──────────────────┼───────┼───────────────┼────────────┼─────────────────
/users            │ R/W   │ Read Only     │ Read Only  │ Read (own only)
/classes          │ R/W   │ Read Only     │ Read Only  │ Read Only
/sessions         │ R/W   │ R/W           │ R/W        │ Read Only
/attendances      │ R/W   │ R/W           │ R/W        │ Write (scan QR)
/leave_requests   │ R/W   │ Read+Update   │ —          │ Read+Create
/reports          │ R/W   │ R/W           │ —          │ —
```

> Rules diimplementasikan menggunakan helper `hasRole(role)` yang membaca field `role` dari Firestore `/users/{uid}` — perubahan role langsung efektif tanpa restart.

---

### 3. Import Pengguna Massal (Excel)

Template kolom yang disediakan sistem:

| Kolom | Keterangan |
|---|---|
| `Nama Lengkap` | Nama penuh pengguna |
| `Email` | Email login (unik) |
| `Password` | Password awal (min. 6 karakter) |
| `Role` | `admin` / `guru_piket` / `guru_mapel` / `siswa` |
| `Info Tambahan` | Kelas (untuk siswa) atau mata pelajaran (untuk guru mapel) |

Sistem akan: (1) Buat akun Firebase Auth per baris, (2) Simpan profil ke Firestore `/users/{uid}`, (3) Tampilkan ringkasan berhasil/gagal per baris.

---

### 4. Status Kehadiran

| Status | Deskripsi | Siapa yang Dapat Set |
|---|---|---|
| `hadir` | Siswa hadir | Scan QR otomatis / Manual guru |
| `izin` | Siswa izin resmi | Guru piket / Admin |
| `sakit` | Siswa sakit | Guru piket / Admin |
| `alpa` | Tanpa keterangan | Guru piket / Admin (default jika tidak hadir) |

---

### 5. Timeout & Error Handling Firestore

Semua query Firestore menggunakan timeout **10 detik**:
```dart
query.get().timeout(
  Duration(seconds: 10),
  onTimeout: () => throw Exception(
    "Koneksi Firestore timeout. Periksa internet atau status database di Firebase Console."
  ),
);
```

---

### 6. Logika Status Sesi

| Status | Deskripsi | Aksi yang Diizinkan |
|---|---|---|
| `active` | Sesi berjalan, input terbuka | Siswa scan QR, guru input kehadiran |
| `closed` | Sesi ditutup | Hanya baca — tidak bisa tambah data baru |

> Siswa hanya bisa scan QR **saat sesi `active`**. Setiap kelas hanya boleh memiliki **1 sesi harian aktif** dalam satu waktu.

---

## 📦 Dependensi Project

### Dependencies

| Package | Versi | Fungsi |
|---|---|---|
| `flutter` | SDK | Framework UI utama |
| `cupertino_icons` | ^1.0.8 | Icon set iOS style |
| `firebase_core` | ^4.11.0 | Inisialisasi Firebase |
| `firebase_auth` | ^6.5.4 | Autentikasi email/password |
| `cloud_firestore` | ^6.6.0 | Database real-time (Firestore) |
| `provider` | ^6.1.5+1 | State management |
| `qr_flutter` | ^4.1.0 | Generate QR Code |
| `mobile_scanner` | ^7.2.0 | Scan QR Code via kamera |
| `intl` | ^0.20.3 | Format tanggal & angka (localization) |
| `excel` | ^4.0.0 | Baca & tulis file Excel (.xlsx) |
| `file_picker` | ^10.3.3 | Pilih file dari storage perangkat |
| `path_provider` | ^2.1.2 | Akses direktori penyimpanan device |
| `flutter_animate` | ^4.5.0 | Animasi & micro-interaction UI |
| `share_plus` | ^12.0.2 | Share file/konten ke aplikasi lain |

### Dev Dependencies

| Package | Versi | Fungsi |
|---|---|---|
| `flutter_test` | SDK | Framework pengujian Flutter |
| `flutter_lints` | ^6.0.0 | Panduan gaya penulisan kode (linting) |

---

## 🚀 Panduan Instalasi

### Prasyarat

| Tool | Versi Minimum | Cek Versi |
|---|---|---|
| Flutter SDK | 3.x (Dart ^3.12.2) | `flutter --version` |
| Android Studio / Xcode | Latest | — |
| VS Code | Latest | — |
| Firebase CLI | Latest | `npx firebase-tools --version` |
| Git | Any | `git --version` |

---

### Langkah 1 — Clone Repository

```bash
git clone <url-repository>
cd flutter_application_1
```

---

### Langkah 2 — Install Dependencies

```bash
flutter pub get
```

---

### Langkah 3 — Konfigurasi Firebase

1. **Buat project di Firebase Console** → [console.firebase.google.com](https://console.firebase.google.com)

2. **Aktifkan layanan berikut:**
   - Firebase Authentication → Email/Password
   - Cloud Firestore → mode produksi

3. **Konfigurasi FlutterFire:**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   File `lib/firebase_options.dart` akan otomatis ter-generate.

4. **Deploy Firestore Security Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

---

### Langkah 4 — Setup MySQL (Opsional — Dokumentasi Skripsi)

> MySQL hanya untuk keperluan **dokumentasi ERD & analisis relasi skripsi**, bukan sumber data operasional.

```bash
# Buka XAMPP → aktifkan Apache & MySQL
# Buka phpMyAdmin → buat database 'db_presensi_muh1'
mysql -u root -p db_presensi_muh1 < database_schema.sql
```

---

### Langkah 5 — Jalankan Aplikasi

```bash
# Cek device tersedia
flutter devices

# Jalankan dalam mode debug
flutter run

# Build APK release
flutter build apk --release
```

---

### Langkah 6 — Buat Akun Admin Pertama

Karena belum ada akun admin, buat secara manual di Firebase Console:

**Langkah A — Firebase Authentication:**
1. Firebase Console → Authentication → Add User
2. Email: `admin@smpmuh1.sch.id`, Password: *(sesuai kebutuhan)*
3. Catat **UID** yang digenerate

**Langkah B — Firestore:**
1. Firestore → Collections → `users` → Add Document
2. Document ID: *(UID dari langkah A)*
3. Fields:
   ```
   name    : "Administrator"
   email   : "admin@smpmuh1.sch.id"
   role    : "admin"
   status  : "active"
   ```

4. Login ke aplikasi dengan kredensial tersebut

---

## 🔑 Kredensial Akun Bawaan

> ⚠️ **Akun di bawah ini adalah contoh untuk environment pengujian (development/testing).** Ganti semua password sebelum deployment ke production.

| Role | Email | Password | Akses |
|---|---|---|---|
| **Admin** | `admin@smpmuh1.sch.id` | *(setup manual via Firebase Console)* | Full access |
| **Guru Piket** | *(dibuat oleh Admin via aplikasi)* | *(diset saat pembuatan akun)* | Sesi harian, validasi, rekap |
| **Guru Mapel** | *(dibuat oleh Admin via aplikasi)* | *(diset saat pembuatan akun)* | Sesi mapel, kehadiran per mapel |
| **Siswa** | *(dibuat oleh Admin via aplikasi)* | *(diset saat pembuatan akun)* | Scan QR, riwayat, izin |

### Catatan Keamanan

- Admin membuat seluruh akun pengguna via UI aplikasi atau import Excel
- Password minimum **6 karakter** (enforced by Firebase Auth)
- Perubahan role berlaku **langsung** tanpa restart (dibaca dari Firestore real-time)
- Akun dapat dinonaktifkan (`status: "inactive"`) tanpa menghapus data histori

---

## 🛠️ Ringkasan Tech Stack

```
┌────────────────────────────────────────────────────────────────┐
│                       APLIKASI MOBILE                          │
│                                                                │
│   ┌────────────────┐    ┌─────────────────────────────────┐   │
│   │  Flutter (UI)  │    │      State Management           │   │
│   │  Dart ^3.12.2  │◄──►│      Provider Pattern           │   │
│   │  Material 3    │    │  (AuthProvider, AdminProvider,  │   │
│   │  flutter_animate│   │   PiketProvider, MapelProvider, │   │
│   │  qr_flutter    │    │   SiswaProvider)                │   │
│   │  mobile_scanner│    └─────────────────────────────────┘   │
│   └───────┬────────┘                                          │
│           │                                                    │
│  ┌────────▼───────────────────────────────────────────────┐   │
│  │                   Core Services                        │   │
│  │  AuthService │ DBService (Firestore) │ QRService       │   │
│  │  (Firebase    │ (CRUD + 10s Timeout) │ (Base64 +       │   │
│  │   Auth)       │                      │  Signature)     │   │
│  └────────────────────────────────────────────────────────┘   │
└──────────────────────────┬─────────────────────────────────────┘
                           │  HTTPS / Firebase SDK
┌──────────────────────────▼─────────────────────────────────────┐
│                     FIREBASE BACKEND                           │
│                                                                │
│  Firebase Auth        Cloud Firestore                          │
│  (Email/Password)     /users, /classes, /sessions,            │
│                       /attendances, /leave_requests, /reports  │
│                                                                │
│  Firestore Security Rules (RBAC per collection)               │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│       MySQL / XAMPP (Pendukung Dokumentasi Skripsi)            │
│  db_presensi_muh1:                                             │
│  users, classes, subjects, teacher_subjects, sessions,         │
│  attendances, leave_requests, reports                          │
│  → Digunakan untuk pemodelan ERD & analisis relasi (Bab IV)    │
└────────────────────────────────────────────────────────────────┘
```

### Tabel Ringkasan Stack

| Layer | Teknologi | Peran |
|---|---|---|
| **Bahasa** | Dart 3 | Logika seluruh aplikasi |
| **UI Framework** | Flutter | Cross-platform mobile UI |
| **State Management** | Provider | Manajemen state reaktif |
| **Autentikasi** | Firebase Authentication | Login email/password |
| **Database Real-time** | Cloud Firestore | Penyimpanan data operasional |
| **QR Generate** | qr_flutter | Render QR Code sebagai widget |
| **QR Scanner** | mobile_scanner | Scan QR via kamera |
| **Excel** | excel + file_picker | Import/export data pengguna massal |
| **Animasi** | flutter_animate | Micro-animation UI |
| **Share/Export** | share_plus | Export kartu QR, laporan |
| **Database Pendukung** | MySQL (XAMPP) | Dokumentasi ERD skripsi |
| **Desain UI/UX** | Figma | Wireframe & prototype |
| **IDE** | Visual Studio Code | Pengembangan kode |
| **Pengujian** | Black Box Testing | Functional & non-functional test |

---

## 👥 Matriks Hak Akses Lengkap

| Aksi | Admin | Guru Piket | Guru Mapel | Siswa |
|---|:---:|:---:|:---:|:---:|
| Kelola user/kelas | ✅ | ❌ | ❌ | ❌ |
| Import pengguna (Excel) | ✅ | ❌ | ❌ | ❌ |
| Generate QR siswa | ✅ | ❌ | ❌ | ❌ |
| Buat sesi presensi harian | ✅ | ✅ | ❌ | ❌ |
| Buat sesi presensi mapel | ✅ | ❌ | ✅ | ❌ |
| Validasi/ubah status kehadiran | ✅ | ✅ (harian) | ✅ (mapel diampu) | ❌ |
| Scan QR untuk presensi diri | ❌ | ❌ | ❌ | ✅ |
| Lihat rekap semua kelas | ✅ | ✅ | ❌ | ❌ |
| Lihat rekap kelas/mapel yang diampu | ❌ | ❌ | ✅ | ❌ |
| Lihat riwayat presensi pribadi | ❌ | ❌ | ❌ | ✅ |
| Ajukan izin digital | ❌ | ❌ | ❌ | ✅ |
| Review pengajuan izin | ✅ | ✅ | ❌ | ❌ |
| Unduh laporan | ✅ | ✅ (harian) | ❌ | ❌ |

---

## 📊 Metode Pengujian — Black Box Testing

| Jenis | Deskripsi |
|---|---|
| **Functional Testing** | Uji setiap fitur per role: login, scan QR, buka/tutup sesi, validasi, laporan |
| **Non-Functional Testing** | Uji performa real-time, keamanan RBAC, kompatibilitas layar & versi Android |
| **Regression Testing** | Setiap fitur baru → uji ulang seluruh skenario sebelumnya |

---

## 📚 Referensi

- Flutter: [flutter.dev](https://flutter.dev)
- Firebase Docs: [firebase.google.com/docs](https://firebase.google.com/docs)
- qr_flutter: [pub.dev/packages/qr_flutter](https://pub.dev/packages/qr_flutter)
- mobile_scanner: [pub.dev/packages/mobile_scanner](https://pub.dev/packages/mobile_scanner)
- Provider: [pub.dev/packages/provider](https://pub.dev/packages/provider)

---

<div align="center">

**Aplikasi Presensi Siswa — SMP Muhammadiyah 1 Sekampung Udik**

Dikembangkan sebagai tugas akhir skripsi oleh **Elen Novita Sari (NPM 22430117)**  
Program Studi S1 Ilmu Komputer — Universitas Muhammadiyah Metro © 2025

</div>
