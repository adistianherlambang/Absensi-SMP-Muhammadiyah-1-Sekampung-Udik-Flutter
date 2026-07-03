-- Schema MySQL untuk Pendukung Analisis & Dokumentasi Skripsi
-- Penulis: Elen Novita Sari (NPM 22430117)
-- Studi Kasus: SMP Muhammadiyah 1 Sekampung Udik

CREATE DATABASE IF NOT EXISTS db_presensi_muh1;
USE db_presensi_muh1;

-- 1. Tabel Kelas
CREATE TABLE IF NOT EXISTS classes (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    homeroom_teacher_id VARCHAR(50) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabel Pengguna (Admin, Guru, Siswa)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'guru_piket', 'guru_mapel', 'siswa') NOT NULL,
    class_id VARCHAR(50) NULL,
    qr_code_id VARCHAR(100) UNIQUE NULL,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL
);

-- Tambahkan foreign key pada classes untuk homeroom_teacher_id setelah tabel users dibuat
ALTER TABLE classes ADD CONSTRAINT fk_homeroom_teacher FOREIGN KEY (homeroom_teacher_id) REFERENCES users(id) ON DELETE SET NULL;

-- 3. Tabel Mata Pelajaran
CREATE TABLE IF NOT EXISTS subjects (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabel Relasi Guru Mata Pelajaran - Kelas - Mapel
CREATE TABLE IF NOT EXISTS teacher_subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id VARCHAR(50) NOT NULL,
    subject_id VARCHAR(50) NOT NULL,
    class_id VARCHAR(50) NOT NULL,
    FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
);

-- 5. Tabel Sesi Presensi (Harian / Mapel)
CREATE TABLE IF NOT EXISTS sessions (
    id VARCHAR(50) PRIMARY KEY,
    type ENUM('harian', 'mapel') NOT NULL,
    class_id VARCHAR(50) NOT NULL,
    subject_id VARCHAR(50) NULL,
    created_by VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    time_start TIME NOT NULL,
    time_end TIME NULL,
    status ENUM('active', 'closed') DEFAULT 'active',
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

-- 6. Tabel Presensi / Kehadiran Siswa
CREATE TABLE IF NOT EXISTS attendances (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id VARCHAR(50) NOT NULL,
    student_id VARCHAR(50) NOT NULL,
    status ENUM('hadir', 'izin', 'sakit', 'alpa') NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    method ENUM('qr_scan', 'manual_override') NOT NULL,
    recorded_by VARCHAR(50) NOT NULL,
    note VARCHAR(255) NULL,
    FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recorded_by) REFERENCES users(id) ON DELETE CASCADE
);

-- 7. Tabel Pengajuan Izin Siswa (Digital Leave Request)
CREATE TABLE IF NOT EXISTS leave_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    reason TEXT NOT NULL,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_by VARCHAR(50) NULL,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 8. Tabel Rekap Laporan
CREATE TABLE IF NOT EXISTS reports (
    id VARCHAR(50) PRIMARY KEY,
    type ENUM('harian', 'mingguan', 'bulanan', 'semesteran') NOT NULL,
    class_id VARCHAR(50) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    generated_by VARCHAR(50) NOT NULL,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    FOREIGN KEY (generated_by) REFERENCES users(id) ON DELETE CASCADE
);
