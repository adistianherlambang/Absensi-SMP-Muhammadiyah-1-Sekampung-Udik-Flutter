# Flowchart Sistem Presensi Sekarang

Dokumen ini berisi flowchart alur sistem presensi yang berjalan saat ini pada aplikasi **SMP Muhammadiyah 1 Sekampung Udik** berdasarkan alur presensi berbasis **QR Siswa**, **Presensi Kelas Otomatis**, dan **Manajemen Riwayat Sesi Pelajaran**.

Alur sistem ini diurutkan secara terpadu (*sequential*) dari terminal **Mulai** hingga **Selesai**, dengan pembagian visual yang dipisah secara tegas berdasarkan **Peran (Role)** masing-masing.

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
        A_Generate[Generate QR Code Unik Siswa]
        A_ExportChoice{Pilih Oksi Ekspor QR}
        A_SingleQR[/Cetak / Unduh Kartu QR Siswa (.png)/]
        A_BatchZIP[/Unduh Batch ZIP Kartu QR per Kelas (.zip)/]
        A_SavePublic[/Simpan ke Folder Download / Bagikan/]
        A_Report[/Unduh / Bagikan Laporan Presensi Excel (.xlsx)/]
    end

    %% 2. Subgraph Siswa
    subgraph Siswa_Role["Siswa"]
        direction TB
        S_Decide{Hadir di Sekolah?}
        S_Leave[/Ajukan Surat Izin/Sakit via App/]
        S_SaveLeave[Simpan Dokumen Izin ke Database]
        S_Class[/Masuk Kelas & Tunjukkan QR Siswa / Kartu QR/]
    end

    %% 3. Subgraph Guru (Buka Sesi & Pemindaian QR)
    subgraph Guru_Role["Guru (Guru Mapel / Guru Piket / Wali Kelas)"]
        direction TB
        G_OpenSession[/Buka Sesi Pelajaran (Pilih Kelas & Mapel)/]
        G_SaveHist[(Simpan Sesi Langsung ke Histori Database)]
        G_InitAlpa[Inisialisasi Status Siswa Kelas: Default Tidak Hadir / Prepopulasi Izin]
        G_ScanQR[/Scan QR Code Siswa via Kamera HP Guru/]
        G_CheckClass{Siswa Anggota Kelas Sesi Ini?}
        G_RejectScan[/Tampilkan Peringatan: Siswa Bukan Anggota Kelas/]
        G_AutoHadir[Status Siswa Langsung Otomatis HADIR (Tanpa Konfirmasi Sistem)]
        G_CheckMore{Scan QR Siswa Lain?}
        G_Finalize[Siswa Tak Di-scan Otomatis Tetap TIDAK HADIR / ALPA]
        G_FinishSession[Simpan & Selesaikan Sesi Presensi]
    end

    %% 4. Subgraph Guru Piket & Wali Kelas (Monitoring)
    subgraph Monitor_Role["Pemantauan (Guru Piket & Wali Kelas)"]
        direction TB
        P_Dashboard[/Pantau Presensi Real-Time Seluruh Kelas/]
        W_Dashboard[/Pantau Presensi Kelas Asuhan/]
    end

    %% === HUBUNGAN ALUR BERURUTAN (SEQUENTIAL CONNECTIONS) ===
    
    %% Mulai -> Admin Setup
    Start --> A_Login
    A_Login --> A_Verify
    A_Verify -- Tidak --> A_Login
    A_Verify -- Ya --> A_Manage
    A_Manage --> A_Generate
    A_Generate --> A_ExportChoice
    A_ExportChoice -- Kartu Individu --> A_SingleQR
    A_ExportChoice -- Batch per Kelas --> A_BatchZIP
    A_SingleQR --> A_SavePublic
    A_BatchZIP --> A_SavePublic
    
    %% Admin Setup -> Siswa Memilih Kehadiran
    A_SavePublic -->|Kartu / QR Siswa Siap| S_Decide
    
    %% Alur Siswa Tidak Hadir (Izin / Sakit)
    S_Decide -- Tidak --> S_Leave
    S_Leave --> S_SaveLeave
    S_SaveLeave --> G_InitAlpa
    
    %% Alur Siswa Hadir (Masuk Kelas)
    S_Decide -- Ya --> S_Class
    
    %% Guru Membuka Sesi Pelajaran
    S_Class --> G_OpenSession
    G_OpenSession --> G_SaveHist
    G_SaveHist --> G_InitAlpa
    
    %% Guru Scan QR Siswa
    G_InitAlpa --> G_ScanQR
    G_ScanQR --> G_CheckClass
    
    %% Pengecekan Kelas (Kontrol Berbasis Kelas)
    G_CheckClass -- Tidak (Salah Kelas) --> G_RejectScan
    G_RejectScan --> G_CheckMore
    
    G_CheckClass -- Ya (Valid Kelas) --> G_AutoHadir
    G_AutoHadir --> G_CheckMore
    
    %% Loop Pemindaian QR Siswa
    G_CheckMore -- Ya --> G_ScanQR
    G_CheckMore -- Selesai Scan --> G_Finalize
    G_Finalize --> G_FinishSession
    
    %% Hasil Presensi Disimpan & Dipantau Real-Time
    G_FinishSession --> P_Dashboard
    G_FinishSession --> W_Dashboard
    
    %% Laporan Akhir oleh Admin
    P_Dashboard --> A_Report
    W_Dashboard --> A_Report
    A_Report --> End
```

---

## Penjelasan Detail Alur Berurutan (Mulai sampai Selesai)

1. **[Terminal] Mulai:** Memulai proses presensi harian dan jam pelajaran sekolah.
2. **Setup & Pengelolaan QR Siswa (Admin):**
   - Admin masuk ke sistem (*di-verifikasi*), mengelola data pengguna (siswa, guru) dan kelas.
   - Admin membuat QR Code unik untuk setiap siswa.
   - Admin dapat mengekspor Kartu QR Siswa secara **Individu (.png)** atau **Batch ZIP per Kelas (.zip)** (misal `QR_Siswa_Kelas_7A.zip`).
   - Seluruh hasil ekspor disimpan langsung ke **Folder Downloads Publik** di perangkat atau **Dibagikan** via Share Sheet.
3. **Keputusan Kehadiran Siswa:**
   - **Jika Tidak Hadir:** Siswa mengajukan izin/sakit melalui aplikasi, mengunggah bukti/alasan, lalu disimpan di database.
   - **Jika Hadir:** Siswa hadir di kelas dan membawa/menampilkan QR Code unik miliknya (melalui Kartu QR fisik atau layar aplikasi).
4. **Pembukaan Sesi Pelajaran oleh Guru (Simpan ke Histori):**
   - Guru (Guru Mapel / Piket / Wali Kelas) memilih Kelas dan Mata Pelajaran untuk membuka sesi presensi pelajaran.
   - Sesi pelajaran ini **langsung tercatat dan disimpan ke histori database** (bukan sebagai sesi gantung/ongoing yang memerlukan persetujuan dari device siswa).
   - Sistem secara otomatis memuat daftar seluruh siswa di kelas tersebut dan memberikan status awal **Tidak Hadir (Alpa)** secara default (kecuali siswa yang memiliki pengajuan Izin/Sakit terverifikasi pada hari tersebut).
5. **Pemindaian QR Siswa oleh Guru & Otomatisasi (Tanpa Konfirmasi Sistem):**
   - Guru memindai QR Code milik siswa satu per satu menggunakan kamera HP Guru.
   - **Kontrol Berbasis Kelas:** Sistem secara otomatis memvalidasi apakah siswa yang di-scan terdaftar di kelas sesi tersebut. Jika siswa berasal dari kelas lain, sistem menolak scan dan menampilkan peringatan visual/suara.
   - **Otomatisasi Status Hadir:** Jika QR siswa valid dan sesuai dengan kelas, status kehadiran siswa tersebut **langsung otomatis berubah menjadi HADIR di sesi tersebut secara instan tanpa perlu persetujuan atau konfirmasi manual dari sistem**.
   - **Default Status Tidak Hadir:** Siswa yang berada di kelas tersebut tetapi QR-nya tidak di-scan oleh Guru hingga akhir sesi otomatis tetap berstatus **Tidak Hadir (Alpa)**.
6. **Penyelesaian Sesi & Pemantauan Real-Time:**
   - Guru meninjau ringkasan presensi (Hadir, Izin, Sakit, Alpa) dan menyelesaikan sesi presensi.
   - **Guru Piket** memantau kehadiran harian seluruh siswa di sekolah secara real-time.
   - **Wali Kelas** memantau kehadiran harian khusus siswa di kelas asuhannya.
7. **Laporan & Rekapitulasi Presensi (Admin):**
   - Admin menarik seluruh data kehadiran dari database dan mengunduh laporan rekapitulasi Excel (`.xlsx`).
   - Berkas laporan disimpan langsung ke **Folder Downloads Publik** atau **Dibagikan** langsung melalui aplikasi.
8. **[Terminal] Selesai:** Seluruh rangkaian presensi pelajaran dan harian selesai direkam secara akurat.
