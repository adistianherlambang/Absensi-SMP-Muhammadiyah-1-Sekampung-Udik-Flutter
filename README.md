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
- [Struktur Direktori Proyek](#-struktur-direktori-proyek)
- [Alur Kerja Utama Sistem](#-alur-kerja-utama-sistem)
- [Validasi & Logika Teknis Khusus](#-validasi--logika-teknis-khusus)
- [Dependensi Project](#-dependensi-project)
- [Panduan Instalasi & Konfigurasi](#-panduan-instalasi--konfigurasi)
- [Kredensial Akun Bawaan & Database Seeder](#-kredensial-akun-bawaan--database-seeder)
- [Ringkasan Tech Stack](#-ringkasan-tech-stack)
- [Matriks Hak Akses Lengkap](#-matriks-hak-akses-lengkap)
- [Metode Pengujian](#-metode-pengujian)
- [Referensi](#-referensi)

---

## 🏫 Overview Proyek

| Item | Keterangan |
|---|---|
| **Nama Proyek** | Aplikasi Presensi Siswa Berbasis Mobile |
| **Studi Kasus** | SMP Muhammadiyah 1 Sekampung Udik, Kec. Sekampung Udik, Kab. Lampung Timur |
| **Akreditasi Sekolah** | B |
| **Jumlah Siswa** | ±304 siswa (kelas VII–IX) |
| **Jumlah Guru/Staf** | 27 orang |
| **Ruang Lingkup Implementasi QR** | Fokus Siswa Kelas 9 (IX) & Presensi Massal Seluruh Kelas |
| **Versi Aplikasi** | 1.0.0+1 |
| **SDK Environment** | Dart ^3.12.2 (Flutter 3.x) |
| **Platform Output** | Android (Utama), iOS, Desktop (Cross-platform) |

### Latar Belakang Masalah

Sistem presensi di SMP Muhammadiyah 1 Sekampung Udik sebelumnya masih dilakukan **secara manual berbasis kertas**, yang mengakibatkan berbagai permasalahan:

- 📄 **Data mudah hilang/terselip** — lembar absensi fisik rentan rusak dan tercecer.
- 🔄 **Data tidak sinkron** antara absensi harian guru piket dan absensi per mata pelajaran guru mapel.
- ⏳ **Rekap lambat** — rekapitulasi mingguan/bulanan memakan waktu lama.
- 📊 **Laporan tidak real-time** — guru piket dan kepala sekolah tidak dapat memantau kehadiran secara langsung.

### Solusi yang Ditawarkan

Aplikasi mobile berbasis **QR Code & Firebase Real-time Database** dengan:
- ✅ Penyimpanan terpusat & **real-time** di Cloud Firestore.
- ✅ **RBAC (Role-Based Access Control)** berjenjang untuk 4 peran pengguna (Admin, Guru Piket, Guru Mapel/Wali Kelas, Siswa).
- ✅ Presensi mandiri siswa via **Scan QR Code** terverifikasi signature keamanan.
- ✅ Presensi massal (Bulk Attendance) guru mapel dengan auto pre-populasi alasan izin siswa.
- ✅ Rekap otomatis harian → mingguan → bulanan → semesteran dengan ekspor file **Excel (.xlsx)** ter-styling & **Kartu QR Bulk (ZIP)**.

---

## ⚙️ Paradigma Pengembangan & Arsitektur Sistem

Aplikasi ini dirancang dengan mematuhi paradigma rekayasa perangkat lunak modern untuk menjamin performa, keamanan, dan kemudahan pemeliharaan (*maintainability*).

### 1. Metodologi RAD (Rapid Application Development)

Proyek dikembangkan menggunakan metodologi RAD yang berfokus pada kecepatan pengembangan melalui siklus iteratif dan umpan balik pengguna yang cepat:

1. **Requirements Planning**: Identifikasi kendala presensi manual di SMP Muhammadiyah 1 Sekampung Udik.
2. **User Design**: Pemodelan diagram UML (Use Case, Activity, Class, Sequence) dan perancangan antarmuka Glassmorphism premium.
3. **Construction**: Pengodean modular dengan Flutter & Firebase, menggabungkan presensi mandiri QR Code siswa dan presensi massal guru secara iteratif.
4. **Cutover**: Pengujian menyeluruh dengan *Black Box Testing* sebelum sistem diimplementasikan di lingkungan sekolah.

### 2. Arsitektur MVVM (Model-View-ViewModel) dengan Provider

Untuk memisahkan antara antarmuka pengguna (UI) dan logika bisnis, proyek ini menggunakan arsitektur **MVVM**:

```
 ┌───────────────────────┐        ┌─────────────────────────┐        ┌───────────────────────┐
 │       VIEW (UI)       │        │   VIEWMODEL (Provider)  │        │         MODEL         │
 │                       │        │                         │        │                       │
 │  • Screens (UI)       │ ◀────  │  • AuthProvider         │ ◀────  │  • UserModel          │
 │  • Widgets (Reusable) │  State │  • AdminProvider        │  Data  │  • SessionModel       │
 │                       │  Update│  • PiketProvider        │        │  • AttendanceModel    │
 │  (Merespon input user │        │  • MapelProvider        │        │  • LeaveRequestModel  │
 │   & render state)     │  ────▶ │  • SiswaProvider        │  ────▶ │  • ReportModel        │
 └───────────────────────┘  Event └────────────┬────────────┘ Action └───────────────────────┘
                                               │
                                               ▼
                                  ┌─────────────────────────┐
                                  │      SERVICE LAYER      │
                                  │                         │
                                  │  • AuthService (Auth)   │
                                  │  • DBService (Firestore)│
                                  │  • QRService (Encoder)  │
                                  │  • QRCardRenderer       │
                                  │  • FileDownloadHelper   │
                                  └─────────────────────────┘
```

- **Model (`lib/models/`)**: Representasi struktur data murni Dart (`UserModel`, `ClassModel`, `SessionModel`, `AttendanceModel`, `LeaveRequestModel`, `ReportModel`) dilengkapi dengan fungsi serialisasi (`toMap()` dan `fromMap()`).
- **View (`lib/screens/` & `lib/widgets/`)**: Berisi komponen antarmuka pengguna. View murni merepresentasikan state yang dikirimkan oleh ViewModel dan mengirimkan interaksi user kembali ke ViewModel.
- **ViewModel/Provider (`lib/providers/`)**: Mengelola state aplikasi secara reaktif (`AuthProvider`, `AdminProvider`, `PiketProvider`, `MapelProvider`, `SiswaProvider`). Memanggil `notifyListeners()` saat data berubah.
- **Services & Utils (`lib/core/services/` & `lib/core/utils/`)**: Abstraksi komunikasi backend Firebase Auth, Cloud Firestore CRUD, generator & parser QR Code, renderer kartu QR, helper pengunduhan/berbagi file cross-platform, dan seeder data pengujian.

### 3. Keamanan Bertingkat (Dual-Layer RBAC Guard)

Sistem menerapkan kontrol akses peran pengguna (**Role-Based Access Control**) secara ketat pada dua tingkat keamanan:
1. **Client-Side (Route Guard)**: Router Flutter (`lib/app/routes.dart`) mencegah pengguna dengan role tidak sesuai mengakses halaman yang bukan wewenangnya dengan memeriksa properti `role` pada `UserModel` aktif.
2. **Server-Side (Firebase Security Rules)**: Menjamin keamanan data di Cloud Firestore (`firestore.rules`). Database memeriksa langsung UID pengirim request dengan field `role` di dokumen `/users/{uid}` sebelum mengizinkan operasi *Read*, *Write*, atau *Delete*.

---

## 🌟 Fitur Utama & Keunggulan Sistem

### 👑 Modul Admin
| Fitur | Deskripsi |
|---|---|
| **Kelola Pengguna** | CRUD lengkap semua akun (Admin, Guru Piket, Guru Mapel, Wali Kelas, Siswa) dengan pencarian nama/email & filter role/kelas/tipe guru. |
| **Import Bulk Excel** | Upload akun pengguna secara massal via file `.xlsx` dengan template bawaan sistem. |
| **Kelola Kelas** | CRUD data kelas beserta penugasan wali kelas dari daftar guru. |
| **Generate & Cetak Kartu QR** | Generate QR unik per siswa dengan enkripsi signature (`SMP-MUH-1-ABSENSI-SECURE`). |
| **Export QR Single & Bulk (ZIP)** | Export kartu QR siswa individual (PNG) atau batch seluruh kelas sebagai **ZIP Archive** via `FileDownloadHelper`. |
| **Laporan & Ekspor Excel** | Rekap presensi harian/mingguan/bulanan/semesteran dengan ekspor file Excel (`.xlsx`) ter-styling rapi (lebar kolom otomatis, warna header, dan baris selang-seling). |
| **Reset Tahun Ajaran** | Pembersihan data sesi presensi, kehadiran, dan surat izin dengan dialog konfirmasi keamanan untuk memulai periode baru. |
| **Database Seeder Auto** | Jalankan `DatabaseSeeder.seedTestData()` langsung dari menu admin untuk membuat data pengujian otomatis. |

### 🛡️ Modul Guru Piket
| Fitur | Deskripsi |
|---|---|
| **Dashboard Real-time** | Pantau kehadiran siswa seluruh kelas secara langsung dengan statistik ringkasan harian. |
| **Buka/Tutup Sesi Harian** | Buat dan kelola sesi presensi harian per kelas dengan timestamp otomatis. |
| **Validasi & Override Kehadiran** | Override status kehadiran siswa (Hadir / Izin / Sakit / Alpa) dilengkapi catatan khusus. |
| **Monitoring Surat Izin** | Pantau dan kelola pengajuan izin/sakit digital yang diajukan oleh siswa secara real-time. |
| **Rekap Mingguan & Laporan** | Generate rekap akhir minggu dan ekspor laporan kehadiran harian untuk arsip sekolah. |

### 📚 Modul Guru (Mapel & Wali Kelas)
| Fitur | Deskripsi |
|---|---|
| **Input Presensi Massal (Bulk)** | Masukkan mata pelajaran dan catat kehadiran seluruh kelas secara cepat dalam satu layar. |
| **Auto Pre-populasi Izin** | Otomatis mendeteksi siswa yang mengajukan izin/sakit hari ini dan mengisikan alasan izin di bawah nama siswa pada daftar presensi. |
| **Fokus Absen Ringkas** | Default status siswa adalah "Hadir"; guru hanya perlu men-toggle siswa yang "Tidak Hadir" dan memilih detail (Izin/Sakit/Alpa). |
| **Histori Presensi Guru** | Melihat daftar histori sesi pelajaran yang pernah diajarkan oleh guru bersangkutan. |
| **Edit & Hapus Sesi** | Perbarui status presensi siswa pada sesi terdahulu atau hapus dokumen sesi presensi beserta log kehadirannya. |

### 🎓 Modul Siswa
| Fitur | Deskripsi |
|---|---|
| **Scan QR Presensi** | Presensi mandiri dengan memindai QR Code kartu siswa menggunakan kamera hp saat sesi presensi aktif. |
| **Dashboard Personal** | Tampilan status kehadiran hari ini beserta statistik persentase kehadiran semester. |
| **Riwayat Kehadiran** | Lihat seluruh histori presensi pribadi dilengkapi filter status (Hadir, Izin, Sakit, Alpa). |
| **Ajukan Surat Izin Digital** | Submit formulir izin/sakit digital dengan memilih tanggal, jenis status, dan mengisi alasan ketidakhadiran. |
| **Edit & Hapus Surat Izin** | Perbarui atau batalkan surat izin yang diajukan sebelumnya (database otomatis menyinkronkan status presensi pada tanggal terkait). |

### ⚡ Keunggulan Teknis
- 🔒 **Double-Layer Security**: Keamanan menyeluruh pada UI route guard dan Firestore Security Rules backend.
- ⚡ **Firestore Timeout Handling**: Semua request database dilindungi timeout 5–10 detik untuk mencegah aplikasi hanging saat koneksi lambat.
- 📦 **QR Signature Verification**: Mekanisme tanda tangan Base64 terenkripsi mencegah manipulasi QR Code palsu dari luar sistem.
- 🎨 **Premium Aesthetics**: Menggunakan Glassmorphism modern, palet warna elegan, dan mikro-animasi halus (`flutter_animate`).
- 📁 **Cross-Platform Download & Share**: Dukungan simpan file publik Android (Scoped Storage), iOS Documents, Desktop Save Dialog, dan native Share Sheet.

---

## 📁 Struktur Direktori Proyek

```
flutter_application_1/
├── 📄 pubspec.yaml                    # Konfigurasi dependensi, assets & metadata proyek
├── 📄 firestore.rules                 # Firebase Security Rules (RBAC backend Cloud Firestore)
├── 📄 database_schema.sql             # Skema MySQL pendukung (dokumentasi ERD skripsi)
├── 📄 firebase_rules.json             # Firestore Rules dalam format JSON
├── 📄 agent.md                        # Panduan pengembangan & spesifikasi sistem
├── 📄 skripsiRev.md                   # Naskah revisi skripsi & dokumentasi bab
├── 📄 testing.md                      # Laporan skenario pengujian aplikasi
│
└── lib/
    ├── 📄 main.dart                   # Entry point aplikasi & inisialisasi Firebase
    ├── 📄 firebase_options.dart        # Konfigurasi Firebase (generated by FlutterFire CLI)
    │
    ├── app/
    │   ├── 📄 routes.dart             # Definisi named routes & route guard RBAC
    │   └── 📄 theme.dart              # Design system: warna, tipografi, tema Glassmorphism
    │
    ├── core/
    │   ├── services/
    │   │   ├── 📄 auth_service.dart       # Wrapper Firebase Auth (login, logout, get profile)
    │   │   ├── 📄 db_service.dart         # Wrapper Firestore CRUD (users, classes, sessions, attendances, leave_requests)
    │   │   ├── 📄 qr_service.dart         # Generator & parser QR Code (encode Base64 + signature)
    │   │   └── 📄 qr_card_renderer.dart   # Renderer kartu QR siswa sebagai image byte PNG
    │   └── utils/
    │       ├── 📄 db_seeder.dart          # Seeder data pengujian otomatis (Admin, Piket, Mapel, Siswa)
    │       └── 📄 file_download_helper.dart # Helper simpan/share file & pembuat ZIP archive cross-platform
    │
    ├── models/
    │   ├── 📄 user_model.dart             # Model pengguna: uid, name, email, role, class_id, subjects, qr_code_id, status
    │   ├── 📄 class_model.dart            # Model kelas: id, name, homeroom_teacher_id, student_ids
    │   ├── 📄 session_model.dart          # Model sesi presensi: id, type, class_id, subject, date, time_start/end, status
    │   ├── 📄 attendance_model.dart       # Model log kehadiran: student_id, status, timestamp, method, recorded_by, note
    │   ├── 📄 leave_request_model.dart    # Model surat izin: id, student_id, date, status, reason, reviewed_by
    │   └── 📄 report_model.dart           # Model laporan presensi & summary agregasi
    │
    ├── providers/                         # State Management (Provider pattern - ViewModel)
    │   ├── 📄 auth_provider.dart          # State otentikasi, login/logout, & navigasi RBAC
    │   ├── 📄 admin_provider.dart         # State admin: kelola user, kelas, QR, laporan, reset
    │   ├── 📄 piket_provider.dart         # State guru piket: sesi harian, validasi, surat izin
    │   ├── 📄 mapel_provider.dart         # State guru mapel: input/edit presensi massal kelas
    │   └── 📄 siswa_provider.dart         # State siswa: scan QR, riwayat, pengajuan surat izin
    │
    ├── screens/
    │   ├── auth/
    │   │   └── 📄 login_screen.dart           # Halaman login terpusat semua role
    │   │
    │   ├── admin/
    │   │   ├── 📄 admin_dashboard.dart        # Dashboard admin: ringkasan statistik & menu cepat
    │   │   ├── 📄 manage_users_screen.dart    # Kelola pengguna: CRUD, filter role/tipe, import Excel
    │   │   ├── 📄 manage_classes_screen.dart  # Kelola kelas: CRUD & penugasan wali kelas
    │   │   ├── 📄 generate_qr_screen.dart     # Cetak & ekspor kartu QR siswa (PNG / ZIP Bulk)
    │   │   └── 📄 reports_screen.dart         # Laporan presensi komprehensif & export Excel
    │   │
    │   ├── guru_piket/
    │   │   ├── 📄 piket_dashboard.dart            # Dashboard guru piket: monitoring real-time
    │   │   ├── 📄 open_session_screen.dart         # Form buka sesi presensi harian
    │   │   ├── 📄 validate_attendance_screen.dart  # Validasi & override status kehadiran siswa
    │   │   └── 📄 weekly_recap_screen.dart         # Rekapitulasi presensi mingguan
    │   │
    │   ├── guru_mapel/
    │   │   ├── 📄 mapel_dashboard.dart            # Dashboard guru mapel: daftar sesi pelajaran
    │   │   ├── 📄 open_mapel_session_screen.dart  # Form buka sesi presensi mapel
    │   │   └── 📄 mapel_attendance_screen.dart    # Input presensi siswa per sesi mapel
    │   │
    │   ├── guru/                                  # Modul guru (Presensi Massal & Histori)
    │   │   ├── 📄 input_attendance_screen.dart    # Form input presensi massal (bulk) siswa kelas
    │   │   └── 📄 history_screen.dart             # Histori presensi guru, edit, & hapus sesi
    │   │
    │   └── siswa/
    │       ├── 📄 siswa_dashboard.dart            # Dashboard siswa: status hari ini & statistik
    │       ├── 📄 scan_qr_screen.dart             # Kamera pemindai QR Code presensi
    │       ├── 📄 attendance_history_screen.dart  # Histori presensi pribadi & filter
    │       └── 📄 leave_request_screen.dart       # Form pengajuan & kelola surat izin digital
    │
    └── widgets/
        ├── 📄 glass_card.dart          # Reusable widget kartu efek Glassmorphism
        └── 📄 searchable_select.dart   # Dropdown kustom dengan pencarian bawaan
```

---

## 🔄 Alur Kerja Utama Sistem

### 1. Alur Autentikasi & Routing RBAC
```
[User Membuka Aplikasi]
         │
         ▼
[Login Screen] ── (Email + Password) ──▶ [Firebase Auth]
         │                                      │
         │                          Auth Berhasil → getUserProfile(uid)
         │                          Ambil role dari Firestore /users/{uid}
         │
         ▼
[AuthProvider Menentukan Route]
         │
         ├── role: "admin"            ──▶ /admin   (AdminDashboard)
         ├── role: "guru_piket"       ──▶ /piket   (PiketDashboard)
         ├── role: "guru_mapel"       ──▶ /mapel   (MapelDashboard)
         ├── role: "guru_wali_kelas"  ──▶ /guru/input-attendance
         └── role: "siswa"            ──▶ /siswa   (SiswaDashboard)
```

---

### 2. Alur Presensi Mandiri QR Code Siswa
```
[Guru Piket]                      [Cloud Firestore]                   [Siswa]
     │                                    │                              │
     ▼                                    │                              │
Buka Sesi Harian ──────────────▶ Buat /sessions/{id}                     │
(pilih kelas, tanggal)           status: "active"                        │
     │                                    │              Scan QR Code ◀──┤
     │                                    │              (buka kamera)   │
     │                         ① Decode Base64 QR                        │
     │                         ② Verifikasi app signature                │
     │                         ③ Validasi sesi aktif kelas               │
     │                         ④ Rejection jika sudah absen              │
     │                         ⑤ Catat ke /attendances/{session}/{student}
     │                            { status:"hadir", method:"qr_scan" }   │
     │                                    │                              ▼
     ▼                                    │                    Konfirmasi Berhasil
Override Status (Izin/Sakit/Alpa) ───────▶ Update /attendances
     │                                    │
     ▼                                    │
Tutup Sesi Presensi ───────────▶ Update status: "closed"
```

---

### 3. Alur Presensi Massal Guru Mapel / Kelas (Bulk Attendance)
```
[Guru Mapel / Kelas]                [Sistem / App]                 [Cloud Firestore]
         │                                │                                │
         ▼                                │                                │
Pilih Kelas & Mapel ─────────────▶ Load Data Siswa                         │
                                   & Pre-populasi Surat Izin               │
         │                                │                                │
         ▼                                │                                │
1. Status Default: "Hadir"                │                                │
2. Toggle "Tidak Hadir"                   │                                │
   pilih: Izin / Sakit / Alpa             │                                │
         │                                │                                │
         ▼                                │                                │
Klik "Kirim Presensi" ───────────────────▶ 1. Buat Dokumen Sesi           │
                                              /sessions/{id} (closed)     │
                                           2. Simpan Bulk Attendance ────▶ Simpan /attendances
                                              Map /attendances/{id}        secara atomic
```

---

## 🔐 Validasi & Logika Teknis Khusus

### 1. QR Code — Enkoding & Validasi Keamanan

Sistem melakukan validasi tanda tangan (*digital signature*) untuk menjamin QR Code yang discan tidak dipalsukan.

**Format Data Terenkripsi:**
```json
{
  "app": "SMP-MUH-1-ABSENSI-SECURE",
  "student_id": "UID_SISWA_FIRESTORE",
  "qr_code_id": "QR-UID_SISWA"
}
```

**Tahapan Validasi saat Scan:**
1. Decode string Base64 menjadi format JSON UTF-8.
2. Periksa field `app` harus persis `"SMP-MUH-1-ABSENSI-SECURE"` (mencegah penyerangan dengan QR Code acak/luar).
3. Ekstrak `student_id` dan `qr_code_id`.
4. Periksa apakah terdapat sesi presensi harian berstatus `active` untuk kelas siswa tersebut.
5. Periksa apakah siswa sudah tercatat presensi pada sesi tersebut (mencegah double-scan).
6. Rekam data kehadiran ke node `/attendances/{sessionId}/{studentId}` jika seluruh syarat terpenuhi.

---

### 2. Logika Presensi Massal (Bulk Attendance)

Pada menu input presensi guru, seluruh siswa kelas dimuat ke dalam map lokal dengan status awal default `hadir`.
- **Fokus Ketidakhadiran**: UI disederhanakan agar guru hanya perlu mengklik siswa yang **tidak masuk**, kemudian memilih alasan (`Izin`, `Sakit`, `Alpa`).
- **Auto Pre-populasi Surat Izin**: Sistem secara otomatis mengecek koleksi `/leave_requests` untuk hari ini. Jika siswa telah mengajukan izin/sakit yang disetujui, statusnya otomatis terisi sebagai `izin`/`sakit` dan alasan permohonan ditampilkan tepat di bawah nama siswa.
- **Efisiensi Database**: Seluruh daftar kehadiran siswa dikompresi ke dalam dokumen sesi atau map terstruktur sehingga meminimalkan jumlah kuota operasi penulisan (*Write operations*) ke Firestore.

---

### 3. Timeout & File Handling Cross-Platform

- **Firestore Timeout Guard**: Setiap query Firestore dibungkus dengan timeout **5–10 detik** untuk mencegah UI tertahan ketika koneksi internet sekolah tidak stabil.
- **Cross-Platform Download Helper**: `FileDownloadHelper` secara pintar mendeteksi platform:
  - **Android**: Menyimpan ke folder `/storage/emulated/0/Download` publik dengan fallback ke external storage jika Scoped Storage aktif.
  - **iOS**: Menyimpan ke direktori Dokumen aplikasi.
  - **Desktop**: Membuka dialog native *Save File*.
  - **ZIP Bulk Exporter**: Mengompresi kumpulan gambar kartu QR per kelas menjadi berkas `.zip` tunggal via package `archive`.

---

## 📦 Dependensi Project

### Dependencies Utama (`pubspec.yaml`)

| Package | Versi | Fungsi & Kegunaan |
|---|---|---|
| `flutter` | SDK | Framework UI cross-platform utama |
| `cupertino_icons` | ^1.0.8 | Icon set gaya iOS |
| `firebase_core` | ^4.11.0 | Inisialisasi koneksi Firebase |
| `firebase_auth` | ^6.5.4 | Layanan autentikasi email & password |
| `cloud_firestore` | ^6.6.0 | Basis data real-time NoSQL terpusat |
| `provider` | ^6.1.5+1 | State management arsitektur MVVM |
| `qr_flutter` | ^4.1.0 | Generator QR Code berbasis widget |
| `mobile_scanner` | ^7.2.0 | Pemindai QR Code via kamera perangkat |
| `intl` | ^0.20.3 | Pengolahan & format tanggal Bahasa Indonesia |
| `excel` | ^4.0.0 | Pembuat & pembaca berkas spreadsheet `.xlsx` |
| `file_picker` | ^8.1.7 | Pilih berkas Excel dari penyimpanan perangkat |
| `path_provider` | ^2.1.2 | Pengaksesan direktori penyimpanan internal/eksternal |
| `flutter_animate` | ^4.5.0 | Animasi & efek visual antarmuka |
| `share_plus` | ^12.0.2 | Berbagi berkas laporan/QR ke aplikasi lain |
| `archive` | ^3.6.1 | Kompresi berkas gambar kartu QR menjadi ZIP |

### Dev Dependencies

| Package | Versi | Fungsi & Kegunaan |
|---|---|---|
| `flutter_test` | SDK | Framework pengujian unit & widget Flutter |
| `flutter_lints` | ^6.0.0 | Standar aturan penulisan kode Dart/Flutter |

---

## 🚀 Panduan Instalasi & Konfigurasi

### Prasyarat System

| Komponen | Versi Minimum | Perintah Cek |
|---|---|---|
| **Flutter SDK** | ^3.12.2 (Dart 3.x) | `flutter --version` |
| **Android Studio / Xcode** | Versi Terbaru | — |
| **Firebase CLI** | Latest | `npx firebase-tools --version` |
| **Git** | Any | `git --version` |

---

### Langkah 1 — Clone Repository & Install Dependensi
```bash
# Clone repository proyek
git clone <url-repository>
cd flutter_application_1

# Unduh seluruh dependensi Flutter
flutter pub get
```

---

### Langkah 2 — Konfigurasi Firebase Project
1. **Buat Project di Firebase Console** → [console.firebase.google.com](https://console.firebase.google.com).
2. **Aktifkan Layanan Firebase:**
   - **Firebase Authentication** → Metode Login: *Email/Password*.
   - **Cloud Firestore Database** → Mode Produksi (*Production Mode*).
3. **Konfigurasi FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   *(File `lib/firebase_options.dart` akan dibuat otomatis)*.
4. **Deploy Security Rules Firestore:**
   ```bash
   firebase deploy --only firestore:rules
   ```

---

### Langkah 3 — Setup MySQL (Opsional — Dokumentasi Skripsi Bab IV)
> **Catatan**: Database MySQL hanya digunakan sebagai pendukung dokumentasi ERD & analisis relasi pada Naskah Skripsi, bukan penyimpanan data operasional aplikasi mobile.

```bash
# Buka XAMPP / MySQL Service
# Buat database bernama 'db_presensi_muh1' di phpMyAdmin
mysql -u root -p db_presensi_muh1 < database_schema.sql
```

---

### Langkah 4 — Jalankan & Build Aplikasi
```bash
# Uji perangkat/emulator terhubung
flutter devices

# Jalankan dalam mode debug
flutter run

# Build berkas APK Android Release
flutter build apk --release
```

---

## 🔑 Kredensial Akun Bawaan & Database Seeder

### Otomatisasi Seeding Data Pengujian (Database Seeder)

Untuk mempercepat pengujian tanpa membuat akun manual satu per satu, aplikasi menyediakan fitur **Automatic Database Seeder** (`DatabaseSeeder.seedTestData()`).

> 💡 **Cara Menggunakan Seeder**: Login sebagai Admin, lalu buka **Admin Dashboard** → Klik tombol **"Seed Data Pengujian"**.

Seeder akan otomatis membuat struktur kelas `IX-A` beserta seluruh akun pengujian berikut di Firebase Auth & Cloud Firestore:

| Peran (Role) | Email | Password | Akses & Wewenang |
|---|---|---|---|
| **Admin** | `admin@smpm1.sch.id` | `admin123` | Akses penuh manajemen sistem & seeder |
| **Guru Piket** | `piket@smpm1.sch.id` | `piket123` | Buka sesi harian, validasi, & rekap mingguan |
| **Guru Mapel** | `mapel@smpm1.sch.id` | `mapel123` | Input presensi massal mata pelajaran |
| **Wali Kelas** | `wali@smpm1.sch.id` | `wali123` | Monitoring kehadiran & izin siswa kelas asuhan |
| **Siswa 1** | `siswa1@smpm1.sch.id` | `siswa123` | Scan QR presensi mandiri (Kelas IX-A) |
| **Siswa 2** | `siswa2@smpm1.sch.id` | `siswa123` | Scan QR presensi mandiri (Kelas IX-A) |

---

## 🛠️ Ringkasan Tech Stack

| Layer / Komponen | Teknologi | Peran dalam Sistem |
|---|---|---|
| **Bahasa Pemrograman** | Dart 3 | Pengodean logika & model data |
| **Framework UI** | Flutter 3 | Framework UI cross-platform mobile |
| **State Management** | Provider | Arsitektur MVVM reaktif |
| **Autentikasi** | Firebase Authentication | Manajemen sesi & kredensial pengguna |
| **Database Utama** | Cloud Firestore | Basis data NoSQL real-time terpusat |
| **QR Code Engine** | `qr_flutter` & `mobile_scanner` | Generator & pemindai QR Code terenkripsi |
| **Pengolahan Berkas** | `excel`, `file_picker`, `archive` | Import akun, export laporan Excel, & ZIP QR |
| **Desain Antarmuka** | Glassmorphism & `flutter_animate` | Styling UI modern & mikro-animasi |
| **Database Skripsi** | MySQL (XAMPP) | Pemodelan ERD & lampiran Bab IV Skripsi |
| **Metode Pengujian** | Black Box Testing | Uji fungsionalitas & keamanan RBAC |

---

## 👥 Matriks Hak Akses Lengkap (RBAC)

| Fitur / Aksi Sistem | Admin | Guru Piket | Guru Mapel / Kelas | Siswa |
|---|:---:|:---:|:---:|:---:|
| Kelola Data Pengguna & Kelas | ✅ | ❌ | ❌ | ❌ |
| Import Akun Massal (Excel) | ✅ | ❌ | ❌ | ❌ |
| Generate & Export QR Siswa (PNG/ZIP) | ✅ | ❌ | ❌ | ❌ |
| Reset Tahun Ajaran & Seed Data | ✅ | ❌ | ❌ | ❌ |
| Buka / Tutup Sesi Presensi Harian | ✅ | ✅ | ❌ | ❌ |
| Validasi & Override Presensi Harian | ✅ | ✅ | ❌ | ❌ |
| Input Presensi Massal (Bulk Mapel) | ✅ | ❌ | ✅ | ❌ |
| Edit & Hapus Histori Presensi Guru | ✅ | ❌ | ✅ | ❌ |
| Scan QR Code Presensi Mandiri | ❌ | ❌ | ❌ | ✅ |
| Pengajuan Surat Izin Digital | ❌ | ❌ | ❌ | ✅ |
| Monitoring & Review Surat Izin | ✅ | ✅ | ❌ | ❌ |
| Ekspor Laporan Presensi (Excel) | ✅ | ✅ | ❌ | ❌ |

---

## 📊 Metode Pengujian — Black Box Testing

Pengujian aplikasi dilakukan menggunakan metode **Black Box Testing** untuk memastikan seluruh fitur berjalan sesuai spesifikasi tanpa kegagalan:

1. **Functional Testing**: Uji coba fungsionalitas login, pembukaan sesi, scan QR Code, presensi massal, override status, pengajuan surat izin, dan ekspor laporan Excel/ZIP.
2. **Non-Functional Testing**: Uji waktu respon sinkronisasi real-time Firestore, toleransi timeout koneksi, serta kesesuaian tampilan antarmuka pada berbagai ukuran layar Android.
3. **Security RBAC Testing**: Pengujian penembusan route URL & verifikasi kecocokan hak akses Firestore Security Rules.

---

## 📚 Referensi

- Documentation Flutter: [flutter.dev](https://flutter.dev)
- Firebase Documentation: [firebase.google.com/docs](https://firebase.google.com/docs)
- Provider Package: [pub.dev/packages/provider](https://pub.dev/packages/provider)
- Cloud Firestore Security Rules: [firebase.google.com/docs/firestore/security/get-started](https://firebase.google.com/docs/firestore/security/get-started)
- Excel Package Flutter: [pub.dev/packages/excel](https://pub.dev/packages/excel)

---

<div align="center">

**Aplikasi Presensi Siswa — SMP Muhammadiyah 1 Sekampung Udik**

Dikembangkan sebagai tugas akhir skripsi oleh **Elen Novita Sari (NPM 22430117)**  
Program Studi S1 Ilmu Komputer — Universitas Muhammadiyah Metro © 2025

</div>
