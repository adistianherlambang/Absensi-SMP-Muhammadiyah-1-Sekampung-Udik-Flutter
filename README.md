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
- [Paradigma Pengembangan & Arsitektur Sistem](#-paradigma-pengembangan--arsitektur-sistem)
- [Fitur Utama & Keunggulan Sistem](#-fitur-utama--keunggulan-sistem)
- [Struktur Direktori](#-struktur-direktori)
- [Alur Kerja Utama Sistem](#-alur-kerja-utama-sistem)
- [Validasi & Logika Teknis Khusus](#-validasi--logika-teknis-khusus)
- [Dependensi Project](#-dependensi-project)
- [Panduan Instalasi](#-panduan-instalasi)
- [Kredensial Akun Bawaan](#-kredensial-akun-bawaan)
- [Ringkasan Tech Stack](#-ringkasan-tech-stack)
- [Matriks Hak Akses Lengkap](#-matriks-hak-akses-lengkap)
- [Metode Pengujian](#-metode-pengujian)

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

- 📄 **Data mudah hilang/terselip** — lembar absensi fisik rentan rusak.
- 🔄 **Data tidak sinkron** antara absensi harian (wali kelas) dan absensi per mata pelajaran (guru mapel).
- ⏳ **Rekap lambat** — rekapitulasi mingguan/bulanan memakan waktu lama.
- 📊 **Laporan tidak real-time** — guru piket dan kepala sekolah tidak dapat memantau kehadiran secara langsung.

### Solusi yang Ditawarkan

Aplikasi mobile berbasis **QR Code** dengan:
- ✅ Penyimpanan terpusat & **real-time** di Firebase.
- ✅ **RBAC (Role-Based Access Control)** berjenjang untuk 4 peran pengguna.
- ✅ Sinkronisasi data lintas peran tanpa konflik.
- ✅ Rekap otomatis dari harian → mingguan → bulanan → semesteran.

---

## ⚙️ Paradigma Pengembangan & Arsitektur Sistem

Aplikasi ini dirancang dengan mematuhi paradigma rekayasa perangkat lunak modern untuk menjamin performa, keamanan, dan kemudahan pemeliharaan (*maintainability*).

### 1. Metodologi RAD (Rapid Application Development)
Proyek dikembangkan menggunakan metodologi RAD yang berfokus pada kecepatan pengembangan melalui siklus iteratif dan umpan balik pengguna yang cepat:
- **Requirements Planning**: Identifikasi kendala presensi manual di SMP Muhammadiyah 1 Sekampung Udik.
- **User Design**: Pemodelan diagram UML (Use Case, Activity, Class, Sequence) dan perancangan antarmuka Glassmorphism premium di Figma.
- **Construction**: Pengodean modular dengan Flutter & Firebase, menggabungkan fitur presensi mandiri QR Code siswa dan presensi massal guru secara iteratif.
- **Cutover**: Pengujian menyeluruh dengan *Black Box Testing* sebelum sistem diimplementasikan di lingkungan sekolah.

### 2. Arsitektur MVVM (Model-View-ViewModel) dengan Provider
Untuk memisahkan antara tampilan (UI) dan logika bisnis, proyek ini menggunakan arsitektur **MVVM**:

```
 ┌───────────────────────┐        ┌─────────────────────────┐        ┌───────────────────────┐
 │       VIEW (UI)       │        │   VIEWMODEL (Provider)  │        │         MODEL         │
 │                       │        │                         │        │                       │
 │  • Screens (UI screens)│ ◀────  │  • AuthProvider         │ ◀────  │  • UserModel          │
 │  • Widgets (Reusable) │  State │  • AdminProvider        │  Data  │  • SessionModel       │
 │                       │  Update│  • PiketProvider        │        │  • AttendanceModel    │
 │  (Merespon input user │        │  • MapelProvider        │        │  • LeaveRequestModel  │
 │   & render state)     │  ────▶ │                         │  ────▶ │                       │
 └───────────────────────┘  Event │  (Mengelola state,      │ Action └───────────────────────┘
                                  │   proses bisnis, &      │
                                  │   panggil services)     │
                                  └────────────┬────────────┘
                                               │
                                               ▼
                                  ┌─────────────────────────┐
                                  │      SERVICE LAYER      │
                                  │                         │
                                  │  • AuthService (Auth)   │
                                  │  • DBService (Firestore)│
                                  │  • QRService (Encoder)  │
                                  └─────────────────────────┘
```

- **Model (`lib/models/`)**: Representasi struktur data murni dalam bentuk kelas Dart. Dilengkapi dengan fungsi serialisasi (`toMap()` dan `fromMap()`) untuk integrasi Cloud Firestore.
- **View (`lib/screens/` & `lib/widgets/`)**: Berisi komponen antarmuka pengguna. View murni merepresentasikan state yang dikirimkan oleh ViewModel dan mengirimkan interaksi user kembali ke ViewModel.
- **ViewModel/Provider (`lib/providers/`)**: Menggunakan library `provider` untuk mengelola *state* aplikasi. Ketika data berubah, ViewModel memanggil `notifyListeners()`, yang memicu render ulang pada View secara efisien.
- **Services (`lib/core/services/`)**: Lapisan abstraksi data untuk menangani komunikasi dengan pihak ketiga (Firebase Auth, Cloud Firestore API, dan modul pembaca/pembuat QR Code).

### 3. Keamanan Bertingkat (Dual-Layer RBAC Guard)
Sistem menerapkan kontrol akses peran pengguna (**Role-Based Access Control**) secara ketat pada dua tingkat keamanan:
1. **Client-Side (Route Guard)**: Router Flutter (`lib/app/routes.dart`) mencegah pengguna dengan role tidak sesuai mengakses halaman dashboard atau fitur role lainnya dengan mengecek properti `role` pada `UserModel` aktif saat navigasi dilakukan.
2. **Server-Side (Firebase Security Rules)**: Menjamin keamanan data di Cloud Firestore. Database memeriksa langsung kecocokan UID pengirim request dengan field `role` di dokumen `/users/{uid}` sebelum mengizinkan operasi *Read*, *Write*, atau *Delete*.

---

## 🌟 Fitur Utama & Keunggulan Sistem

### 👑 Modul Admin
| Fitur | Deskripsi |
|---|---|
| **Kelola Pengguna** | CRUD lengkap semua akun (admin, guru piket, guru mapel, siswa) |
| **Import Bulk Excel** | Upload pengguna massal via file `.xlsx` dengan template yang disediakan sistem |
| **Kelola Kelas** | CRUD kelas beserta penugasan wali kelas |
| **Generate QR Code** | Generate QR unik per siswa kelas 9 dengan tanda tangan digital (`SMP-MUH-1-ABSENSI-SECURE`) |
| **Export QR** | Export kartu QR siswa sebagai berkas gambar untuk dicetak/dibagikan |
| **Laporan Komprehensif** | Rekap presensi harian/mingguan/bulanan/semesteran dengan statistik ringkasan |
| **Filter & Pencarian** | Pencarian pengguna berdasarkan nama dan filterisasi berdasarkan kelas |

### 🛡️ Modul Guru Piket
| Fitur | Deskripsi |
|---|---|
| **Dashboard Real-time** | Pantau kehadiran siswa seluruh kelas secara langsung |
| **Buka/Tutup Sesi Harian** | Buat sesi presensi harian per kelas dengan timestamp otomatis |
| **Validasi Kehadiran** | Override status kehadiran siswa (Hadir / Izin / Sakit / Alpa) + catatan |
| **Rekap Mingguan** | Generate rekap akhir minggu dengan statistik kehadiran per kelas |
| **Unduh Laporan** | Export rekap kehadiran harian untuk keperluan pelaporan fisik |

### 📚 Modul Guru (Umum & Mata Pelajaran) - *Revisi Alur Baru*
| Fitur | Deskripsi |
|---|---|
| **Scan QR Meja Kelas** | Pindai QR Code yang ditempel pada meja/dinding kelas untuk mengidentifikasi kelas secara cepat tanpa memilih manual |
| **Buka Sesi & Input Massal (Fokus Absen)** | Masukkan mata pelajaran dengan seluruh siswa otomatis diset default "Hadir", lalu guru cukup memilih "Tidak Hadir" dan menentukan status (Izin/Sakit/Alpa) hanya untuk siswa yang absen (layar ringkas & efisien) |
| **Kirim Kehadiran Massal** | Simpan sesi presensi mata pelajaran dan catatan kehadiran massal secara instan ke Cloud Firestore |
| **Histori Sesi Presensi** | Lihat daftar histori sesi pelajaran yang pernah diajarkan oleh guru bersangkutan |
| **Edit & Hapus Sesi** | Lakukan pembaruan (edit) status kehadiran siswa di masa lalu atau hapus sesi presensi beserta catatan kehadirannya secara langsung |

### 🎓 Modul Siswa
| Fitur | Deskripsi |
|---|---|
| **Scan QR Presensi** | Presensi mandiri dengan memindai QR Code kartu siswa dalam sesi presensi aktif |
| **Dashboard Personal** | Tampilan status kehadiran hari ini beserta statistik ringkasan semester |
| **Riwayat Kehadiran** | Lihat seluruh histori kehadiran pribadi dengan filter status |
| **Ajukan Izin Digital** | Submit formulir pengajuan izin/sakit digital beserta unggah alasan ketidakhadiran |
| **Status Izin** | Pantau status persetujuan pengajuan izin oleh Guru Piket/Admin |

### ⚡ Keunggulan Teknis
- 🔒 **Double-layer Security**: Keamanan menyeluruh pada antarmuka (UI guard) dan basis data (database rules).
- ⚡ **Firestore Timeout handling**: Semua request database dilindungi timeout 10 detik guna mencegah aplikasi membeku ketika jaringan tidak stabil.
- 📦 **QR Signature Verification**: Mekanisme tanda tangan Base64 terenkripsi mencegah manipulasi atau penggunaan QR Code palsu dari luar sistem.
- 🎨 **Premium Aesthetics**: Menggunakan Glassmorphism modern, palet warna elegan, dan mikro-animasi halus (`flutter_animate`).
- 📊 **Bulk Operations**: Kemudahan operasional melalui pengolahan data massal (bulk input kehadiran & import akun via Excel).

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
    ├── providers/                         # State management (Provider pattern - ViewModel)
    │   ├── 📄 auth_provider.dart          # Auth state: login, logout, refreshProfile, RBAC routing
    │   ├── 📄 admin_provider.dart         # State admin: users, classes, QR generate, reports
    │   ├── 📄 piket_provider.dart         # State guru piket: sessions, attendance validation
    │   ├── 📄 mapel_provider.dart         # State guru mapel & guru kelas: input/edit presensi massal
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
    │   ├── guru/                                  # Modul tambahan guru (Alur Baru)
    │   │   ├── 📄 scan_class_qr_screen.dart       # Scan QR meja kelas sebagai entry point
    │   │   ├── 📄 input_attendance_screen.dart    # Input kehadiran massal (bulk) siswa kelas
    │   │   └── 📄 history_screen.dart             # Riwayat sesi, edit, dan hapus presensi guru
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

### 3. Alur Baru Presensi Guru (Scan Meja Kelas & Input Massal)
```
[Guru Mapel/Kelas]                [Sistem]                     [Siswa Kelas]
        │                             │                              │
        ▼                             │                              │
Scan QR Meja Kelas ───────────▶ Decode Class QR                      │
                                parsed ['class_id']                  │
        │                             │                              │
        ▼                             │                              │
Tampil Input Screen ◀───────── Ambil data siswa                      │
                                di kelas tersebut                    │
        │                             │                              │
        ▼                             │                              │
1. Masukkan Mata Pelajaran            │                              │
2. Pilih Status Kehadiran             │                              │
   Siswa secara massal                │                              │
        │                             │                              │
        ▼                             │                              │
Kirim Presensi (Submit) ──────▶ 1. Buat /sessions/{id}               │
                                   type: "mapel", status: "closed"   │
                                2. Tulis /attendances/{id}           │
                                   secara bulk (map data)            │
        │                             │                              ▼
        ▼                             │                     Histori Kehadiran
Kembali ke Dashboard ◀──────── Selesai                              Terbarui
```

---

## 🔐 Validasi & Logika Teknis Khusus

### 1. QR Code — Enkoding & Validasi Keamanan
Sistem melakukan validasi tanda tangan untuk memastikan QR Code yang discan tidak dipalsukan.

**Proses Generate:**
```
{ "app": "SMP-MUH-1-ABSENSI-SECURE", "student_id": "...", "qr_code_id": "..." }
    │
    ▼  jsonEncode → UTF-8 encode → Base64 encode
    │
[String QR yang di-embed ke QR Code image]
```

**Proses Validasi saat Scan:**
1. Decode Base64 string ke format teks JSON.
2. Periksa field `app` == `"SMP-MUH-1-ABSENSI-SECURE"` → jika tidak cocok, **tolak** scan.
3. Ambil nilai `student_id` dan `qr_code_id`.
4. Lakukan verifikasi apakah ada sesi presensi bertipe `harian` yang berstatus `active` untuk kelas siswa tersebut. Jika tidak ada sesi aktif, **tolak** presensi.
5. Cek apakah siswa bersangkutan sudah terdaftar melakukan presensi pada sesi tersebut. Jika sudah, **tolak** (mencegah duplikasi data).
6. Jika semua validasi terpenuhi, data presensi direkam ke node `/attendances/{sessionId}/{studentId}`.

**QR Kelas (untuk Guru):**
```
{ "app": "SMP-MUH-1-ABSENSI-SECURE", "class_id": "..." }
```
Ditempel di meja atau dinding kelas. Membantu guru mendeteksi ID Kelas secara instan saat scan sebelum melakukan presensi bulk.

---

### 2. Logika Presensi Massal (Bulk Attendance)
Pada menu input presensi guru, data siswa dikumpulkan ke dalam map lokal `_studentStatuses` dengan status default awal seluruhnya diset sebagai `hadir`.
- **Fokus Absen**: Layar UI disederhanakan dengan menyembunyikan pilihan detail ketidakhadiran secara default. Hanya toggle `Hadir` / `Tidak Hadir` yang dimunculkan. Jika guru mengklik `Tidak Hadir` pada siswa tertentu, barulah pilihan detail status (`Izin`, `Sakit`, `Alpa`) dimunculkan untuk siswa tersebut. Ini mempersempit scope kerja guru agar hanya fokus pada siswa yang tidak masuk kelas.
- Saat tombol **Kirim Presensi** ditekan, sistem membuat objek sesi presensi baru berstatus langsung `closed` (karena presensi diisi secara instan pada saat itu juga).
- Seluruh daftar kehadiran siswa dikompresi ke dalam bentuk map database tunggal untuk satu dokumen sesi di Firestore:
  ```json
  "/attendances/{sessionId}": {
     "student_id_1": { "status": "hadir", "timestamp": "...", "method": "manual_override", "recorded_by": "guru_uid" },
     "student_id_2": { "status": "izin", "timestamp": "...", "method": "manual_override", "recorded_by": "guru_uid" }
  }
  ```
  Hal ini menghemat kuota operasi baca/tulis Firestore (*Read/Write operations*) dibandingkan membuat dokumen terpisah untuk setiap kehadiran siswa.

---

### 3. Timeout & Error Handling Firestore
Untuk mengantisipasi koneksi internet yang lambat di area sekolah, seluruh kueri database Cloud Firestore dibatasi oleh timeout **10 detik**:
```dart
Future<QuerySnapshot> _getWithTimeout(Query query) async {
  return await query.get().timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw Exception(
      "Koneksi Firestore timeout. Periksa internet atau status database di Firebase Console."
    ),
  );
}
```

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
> MySQL hanya untuk keperluan **dokumentasi ERD & analisis relasi skripsi (Bab IV)**, bukan sumber data operasional aplikasi.

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
1. **Firebase Console** → Authentication → Add User.
2. Email: `admin@smpmuh1.sch.id`, Password: *(sesuai keinginan)*. Catat **UID** yang dihasilkan.
3. Buka **Firestore** → Collections → `users` → Add Document.
4. Document ID: *(UID dari langkah 2)*.
5. Isi field berikut:
   ```
   name    : "Administrator"
   email   : "admin@smpmuh1.sch.id"
   role    : "admin"
   status  : "active"
   ```
6. Jalankan aplikasi lalu login dengan kredensial tersebut.

---

## 🔑 Kredensial Akun Bawaan

> ⚠️ **Akun di bawah ini adalah contoh untuk lingkungan pengujian (testing).** Ganti seluruh sandi akun sebelum sistem dideploy secara resmi.

| Role | Email | Password | Akses |
|---|---|---|---|
| **Admin** | `admin@smpmuh1.sch.id` | *(setup manual via Firebase Console)* | Hak Akses Penuh |
| **Guru Piket** | *(dibuat oleh Admin)* | *(ditentukan saat dibuat)* | Sesi harian, validasi, rekap |
| **Guru Mapel** | *(dibuat oleh Admin)* | *(ditentukan saat dibuat)* | Sesi mapel, kehadiran per mapel |
| **Siswa** | *(dibuat oleh Admin)* | *(ditentukan saat dibuat)* | Scan QR mandiri, riwayat, izin |

---

## 🛠️ Ringkasan Tech Stack

| Layer | Teknologi | Peran |
|---|---|---|
| **Bahasa** | Dart 3 | Logika utama aplikasi |
| **UI Framework** | Flutter | Cross-platform mobile UI |
| **State Management** | Provider | Manajemen state reaktif (MVVM ViewModel) |
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

| Aksi | Admin | Guru Piket | Guru Mapel / Kelas | Siswa |
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
| **Functional Testing** | Uji setiap fitur per role: login, scan QR, buka/tutup sesi, validasi manual, bulk input, laporan. |
| **Non-Functional Testing** | Uji performa real-time, keamanan RBAC Firestore, kompatibilitas layar & versi Android. |
| **Regression Testing** | Pengujian ulang skenario sebelumnya saat menambahkan modul guru atau modifikasi basis data. |

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
