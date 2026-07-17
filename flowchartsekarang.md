# Flowchart Sistem Presensi Sekarang

Dokumen ini berisi flowchart alur sistem presensi yang berjalan saat ini pada aplikasi **SMP Muhammadiyah 1 Sekampung Udik** berdasarkan analisis codebase Flutter.

Alur sistem ini diurutkan secara terpadu (sequential) dari terminal **Mulai** hingga **Selesai**, dengan pembagian visual yang dipisah secara tegas berdasarkan **Peran (Role)** masing-masing.

Proses pengisian presensi setelah memindai QR Meja Kelas bersifat **sama dan dapat dilakukan oleh semua peran Guru** (Guru Mapel, Guru Piket, maupun Wali Kelas). Oleh karena itu, alur input presensi ini ditempatkan dalam modul proses bersama (shared).

---

## Diagram Alir Sistem (Mermaid Flowchart)

```mermaid
flowchart TD
    %% Terminal Nodes
    Start([Mulai])
    End([Selesai])

    %% 1. Subgraph Admin
    subgraph Admin_Role["Admin"]
        direction TB
        A_Login[/Login Admin/]
        A_Verify{Kredensial Valid?}
        A_Manage[/Kelola Pengguna & Kelas/]
        A_Generate[Generate QR Meja Kelas]
        A_Print[/Cetak & Tempel QR Meja Kelas/]
        A_Report[/Unduh Laporan Kehadiran .xlsx/]
    end

    %% 2. Subgraph Siswa
    subgraph Siswa_Role["Siswa"]
        direction TB
        S_Decide{Hadir di Kelas?}
        S_Leave[/Ajukan Izin/Sakit via App/]
        S_SaveLeave[Simpan Dokumen Izin ke Firestore]
        S_Class[/Masuk & Mengikuti Kelas/]
    end

    %% 3. Guru Piket
    subgraph Piket_Role["Guru Piket"]
        direction TB
        P_Dashboard[/Pantau Presensi Seluruh Kelas/]
        P_Scan[/Scan QR Meja Kelas/]
    end

    %% 4. Guru Wali Kelas
    subgraph Wali_Role["Guru Wali Kelas"]
        direction TB
        W_Dashboard[/Pantau Presensi Kelas Asuhan/]
        W_Scan[/Scan QR Meja Kelas/]
    end

    %% 5. Guru Mapel
    subgraph Mapel_Role["Guru Mata Pelajaran"]
        direction TB
        M_Scan[/Scan QR Meja Kelas/]
    end

    %% 6. Modul Proses Bersama (Semua Guru)
    subgraph Presensi_KBM["Proses Presensi Guru (Shared)"]
        direction TB
        Prepop[Prepopulasi Status Kehadiran & Izin]
        Input[/Input Nama Mapel & Sesuaikan Kehadiran/]
        Submit[Simpan Presensi Mapel Harian ke Firestore]
    end

    %% === HUBUNGAN ALUR BERURUTAN (SEQUENTIAL CONNECTIONS) ===
    
    %% Mulai -> Admin Setup
    Start --> A_Login
    A_Login --> A_Verify
    A_Verify -- Tidak --> A_Login
    A_Verify -- Ya --> A_Manage
    A_Manage --> A_Generate
    A_Generate --> A_Print
    
    %% Admin Setup -> Siswa Memilih Kehadiran
    A_Print -->|QR Meja Kelas Ditempel| S_Decide
    
    %% Alur Siswa Tidak Hadir (Izin)
    S_Decide -- Tidak --> S_Leave
    S_Leave --> S_SaveLeave
    S_SaveLeave --> W_Dashboard
    
    %% Alur Siswa Hadir (Masuk Kelas)
    S_Decide -- Ya --> S_Class
    
    %% Aksi Memulai Presensi - Semua Guru Bisa Melakukan Scan QR
    S_Class --> M_Scan
    S_Class --> P_Scan
    S_Class --> W_Scan
    
    %% Alur Pemindaian QR oleh Guru (Menuju Pemrosesan Bersama)
    M_Scan --> Prepop
    P_Scan --> Prepop
    W_Scan --> Prepop
    
    %% Sistem Memproses Presensi (Modul Shared)
    Prepop --> Input
    Input --> Submit
    
    %% Hasil Presensi Disimpan dan Dipantau oleh Masing-masing Peran Guru
    Submit --> P_Dashboard
    Submit --> W_Dashboard
    
    %% Dari Pemantauan Piket/Wali Kelas -> Penarikan Laporan Akhir oleh Admin
    P_Dashboard --> A_Report
    W_Dashboard --> A_Report
    A_Report --> End
```

---

## Penjelasan Alur Berurutan (Mulai sampai Selesai)

1. **[Terminal] Mulai:** Memulai proses presensi harian sekolah.
2. **Setup Admin:** Admin masuk ke sistem (di-verifikasi), mengelola data pengguna/kelas, memproses pembuatan QR kelas, dan mencetak QR Meja Kelas.
3. **Keputusan Siswa:** Di pagi hari, siswa menentukan kehadirannya:
   * **Jika tidak hadir:** Siswa mengajukan izin/sakit melalui aplikasi, disimpan di database, dan masuk ke pantauan **Wali Kelas**.
   * **Jika hadir:** Siswa masuk kelas dan bersiap mengikuti pelajaran.
4. **Pemindaian QR Meja Kelas (Semua Guru):**
   * **Guru Mapel**, **Guru Piket**, maupun **Wali Kelas** dapat memindai QR Meja Kelas yang tertempel untuk memulai pencatatan/koreksi kehadiran siswa.
5. **Pemrosesan & Input Presensi (Modul Bersama):**
   * Sistem otomatis mendeteksi ID kelas, memuat daftar siswa, dan menandai (*prepopulasi*) status siswa yang sudah terdaftar Izin/Sakit pada hari itu dari database.
   * Guru menginput nama mata pelajaran (jika KBM) dan menyesuaikan status kehadiran siswa (Hadir, Sakit, Izin, Alpa), lalu menyimpannya ke Firestore.
6. **Pemantauan Dasbor Guru:**
   * **Guru Piket** dapat memantau kehadiran harian seluruh siswa dari semua kelas di sekolah secara real-time.
   * **Wali Kelas** memantau kehadiran harian khusus siswa kelas asuhan yang diampunya.
7. **Laporan & Rekapitulasi:**
   * Admin menarik seluruh data kehadiran siswa dari database dan mengunduh berkas laporan rekapitulasi `.xlsx` (Excel).
8. **[Terminal] Selesai:** Seluruh rangkaian presensi hari itu selesai direkam.
