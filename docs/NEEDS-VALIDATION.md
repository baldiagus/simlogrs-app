# Catatan Validasi Lingkungan & Backend (Needs Validation)

Dokumen ini memuat hipotesis dan aspek keamanan yang membutuhkan verifikasi langsung pada lingkungan backend, basis data, infrastruktur jaringan, atau konfigurasi rilis produksi karena bukti definitif berada di luar cakupan kode sumber repositori klien mobile ini.

---

### NV-01: Kebijakan Masa Berlaku & Pencabutan Token Sanctum di Backend (Token Lifecycle)

- **Komponen Klien Terkait**: `lib/core/storage/secure_storage_service.dart`, `lib/core/network/dio_client.dart`
- **Pertanyaan Validasi**:
  1. Apakah konfigurasi Laravel Sanctum di backend (`config/sanctum.php`) mendefinisikan batas waktu kadaluarsa token (`'expiration' => ...`)?
  2. Apakah endpoint `/auth/logout` benar-benar mencabut (*revoke*) token aktif dari tabel `personal_access_tokens` di database, atau hanya membuang sesi di sisi klien?
- **Rencana Verifikasi yang Aman**:
  - Periksa berkas `config/sanctum.php` pada repositori backend SIMLOG RS.
  - Lakukan panggilan `POST /api/v1/auth/login`, catat token, panggil `POST /api/v1/auth/logout`, lalu uji ulang pemanggilan `GET /api/v1/auth/me` menggunakan token lama. Pastikan server mengembalikan status HTTP `401 Unauthorized`.

---

### NV-02: Penegakan Otorisasi Sisi Server untuk Seluruh Endpoint Operasional (Server-Side RBAC)

- **Komponen Klien Terkait**:
  - `lib/features/gudang/data/repositories/persediaan_repository.dart` (`approvePenyesuaian`)
  - `lib/features/pengadaan/data/repositories/approval_repository.dart`
  - `lib/features/shell/presentation/screens/main_shell_screen.dart` (`_bukaTujuan`)
- **Pertanyaan Validasi**:
  - Jika klien mobile membuka rute tampilan otorisasi akibat manipulasi payload notifikasi (merujuk pada temuan `SEC-06`), apakah API backend secara konsisten memvalidasi otorisasi peran via middleware (misal `middleware('can:...')` atau `abort_if(!auth()->user()->hasRole(...))`)?
- **Rencana Verifikasi yang Aman**:
  - Uji pengiriman permintaan HTTP dari akun dengan peran rendah (misal `petugasunit@simlogrs.local`) menuju endpoint otorisasi tingkat tinggi (misal `POST /api/v1/gudang/penyesuaian/{id}/approve` atau `POST /api/v1/pengadaan/approval/po/{id}`).
  - Pastikan server mengembalikan kode respon `403 Forbidden` dan menolak perubahan data.

---

### NV-03: Status Rotasi Kredensial Akun Bawaan di Database Produksi

- **Komponen Klien Terkait**: `lib/features/auth/presentation/screens/login_screen.dart` (merujuk pada temuan `SEC-01`)
- **Pertanyaan Validasi**:
  - Apakah akun-akun administratif yang tertera pada *preset chip* (`superadmin@simlogrs.local`, `adminlogistik@simlogrs.local`, dsb.) telah dirotasi kata sandinya di database produksi, atau masih menggunakan kata sandi seeder awal (`SimlogRS@2026!` atau `password`)?
  - Apakah flag `wajib_ganti_password` diaktifkan secara otomatis bagi pengguna baru yang dibuat oleh administrator?
- **Rencana Verifikasi yang Aman**:
  - Periksa skrip database seeder di backend (`DatabaseSeeder.php`, `UserSeeder.php`).
  - Verifikasi tabel `users` di lingkungan staging/produksi bahwa tidak ada akun aktif dengan hash kata sandi default yang belum pernah diganti.

---

### NV-04: Penerapan TLS Termination & Header Keamanan pada Reverse Proxy

- **Komponen Klien Terkait**: `android/.../network_security_config.xml`, `lib/core/network/dio_client.dart`
- **Pertanyaan Validasi**:
  - Apakah server web / reverse proxy (Nginx / Cloudflare / Traefik) di lingkungan rumah sakit memaksakan pengalihan otomatis HTTP ke HTTPS (*HTTP Strict Transport Security* - HSTS)?
  - Apakah sertifikat TLS yang dipasang menggunakan rantai validasi publik yang sah atau sertifikat self-signed intranet?
- **Rencana Verifikasi yang Aman**:
  - Lakukan inspeksi TLS menggunakan perintah `openssl s_client -connect <domain_api>:443 -servername <domain_api>` untuk memeriksa masa berlaku sertifikat, cipher suite yang diizinkan, dan rantai CA.

---

### NV-05: Penanganan Penyimpanan Aman pada Target Flutter Web

- **Komponen Klien Terkait**: `lib/core/storage/secure_storage_service.dart`
- **Pertanyaan Validasi**:
  - Jika aplikasi ini akan di-deploy ke platform Web (*Flutter Web*): `flutter_secure_storage` pada platform Web secara default menyimpan data di `window.localStorage` tanpa enkripsi perangkat keras.
  - Apakah build Web digunakan di lingkungan produksi rumah sakit yang dapat diakses dari browser publik?
- **Rencana Verifikasi yang Aman**:
  - Jika build web dipublikasikan, evaluasi apakah autentikasi berbasis HttpOnly secure cookie lebih disarankan daripada menyimpan Bearer token pada `localStorage`.
