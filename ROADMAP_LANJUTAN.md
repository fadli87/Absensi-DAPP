# Roadmap & Tahapan Pengembangan Lanjutan: Sistem Absensi DAPP

Dokumen ini memuat rangkuman tahapan pengembangan lanjutan untuk melengkapi sistem Absensi DAPP agar menjadi aplikasi korporat/instansi yang utuh dan siap produksi.

---

## 1. Manajemen User & RBAC (Role-Based Access Control)
*Tujuan: Memisahkan hak akses antara Admin, HR, dan Karyawan, serta mengelola data pegawai secara terpusat.*

*   **Fitur CRUD Karyawan (Admin/HR Panel):**
    *   Menambah, mengubah, menonaktifkan, atau menghapus akun pegawai.
    *   Pengaturan profil pegawai (Jabatan, Divisi, NIP/ID Karyawan).
*   **Sistem Peran (Roles):**
    *   `ADMIN / HR`: Mengelola data user, melihat seluruh laporan absensi, dan melakukan konfigurasi sistem.
    *   `EMPLOYEE`: Hanya dapat melakukan login, absensi (Check-in/Check-out dengan Selfie + GPS), dan melihat riwayat pribadi.
*   **Geofencing & Pengaturan Shift:**
    *   Menentukan titik koordinat kantor pusat/cabang beserta batas radius yang diizinkan (misal: maksimal radius 100 meter dari titik kantor).
    *   Pengaturan jam kerja / shift masuk dan pulang.

---

## 2. Admin Dashboard & Reporting
*Tujuan: Menyediakan antarmuka berbasis Web (Dashboard) bagi HR/Admin untuk memantau kehadiran secara real-time dan menarik rekapitulasi laporan.*

*   **Frontend Web Dashboard (React / Next.js / Vue):**
    *   Tampilan statistik harian (Jumlah yang hadir, terlambat, izin, dan alfa).
    *   Peta atau daftar log absensi masuk yang memuat foto selfie dan titik koordinat GPS pegawai.
*   **Modul Reporting & Ekspor Data:**
    *   Filter laporan berdasarkan rentang tanggal (harian, mingguan, bulanan) dan divisi.
    *   Fitur ekspor data rekapitulasi absensi ke format **Excel (.xlsx)** atau **PDF**.

---

## 3. Deployment & Production Setup
*Tujuan: Memindahkan seluruh ekosistem aplikasi dari lingkungan lokal (*development*) ke peladen publik (*cloud/production*) agar dapat diakses dari mana saja.*

*   **Backend Deployment (Node.js & Database):**
    *   Deploy server Node.js ke Cloud VPS (DigitalOcean, AWS, Railway, atau Render).
    *   Migrasi database lokal ke Cloud PostgreSQL (Supabase, Neon, atau managed database).
    *   Konfigurasi Domain/SSL (HTTPS) agar aplikasi mobile dapat berkomunikasi dengan aman.
*   **Web Admin Deployment:**
    *   Hosting Frontend Dashboard Admin ke Vercel, Netlify, atau VPS terpusat.
*   **Mobile App Release Build:**
    *   Konfigurasi signing key untuk rilis aplikasi Android.
    *   Build production APK / App Bundle (`flutter build appbundle --release`) untuk distribusi internal atau publikasi ke Google Play Store.