# DOKUMEN MASTER USER ACCEPTANCE TESTING (UAT) CLIENT MOBILE
## SISTEM INFORMASI MANAJEMEN LOGISTIK RUMAH SAKIT (SIMLOG RS NON-MEDIS v2)
### Platform Klien: Flutter Mobile (Android & iOS) — Zero-Dummy-Data & Capability-Based RBAC

---

### Informasi Dokumen
* **Aplikasi**: SIMLOG RS Mobile Client (`simlogrs-app`)
* **Backend API**: SIMLOG RS RESTful API v1 (`simlog-fix2` / Laravel 11 Sanctum)
* **Target Gawai**: Android (API 26+) & iOS (14+)
* **Lingkungan Pengujian**: Staging / Localhost API (`http://10.0.2.2:8000/api/v1` atau `http://127.0.0.1:8000/api/v1`)
* **Metodologi Pengujian**: Black Box Testing, Capability-Based UI Testing, Hardware Camera QR/Barcode Scanning, Concurrency & Form Validation, Offline/Inactivity Timeout Testing.
* **Standar Integritas**: 
  - **Zero Dummy Data**: Seluruh data antrean, kartu, dan formulir terikat 100% secara reaktif ke endpoint API backend.
  - **Zero Hardcoded Roles**: Seluruh kontrol tombol dan navigasi diatur oleh array `roles` dan `permissions` dari `GET /api/v1/auth/me`.

---

### Matriks 10 Peran Pengguna & Berkas UAT Terkait

| No | Peran Pengguna (Role) | Email Login | Sandi Default | Berkas Spesifikasi UAT |
|:---:|---|---|---|---|
| 1 | **Super Administrator** | `superadmin@simlogrs.local` | `password` | [`uat-mobile-01-superadmin.md`](./uat-mobile-01-superadmin.md) |
| 2 | **Admin Logistik** | `adminlogistik@simlogrs.local` | `password` | [`uat-mobile-02-adminlogistik.md`](./uat-mobile-02-adminlogistik.md) |
| 3 | **Kepala Gudang** | `kepalagudang@simlogrs.local` | `password` | [`uat-mobile-03-kepalagudang.md`](./uat-mobile-03-kepalagudang.md) |
| 4 | **Petugas Gudang** | `petugasgudang@simlogrs.local` | `password` | [`uat-mobile-04-petugasgudang.md`](./uat-mobile-04-petugasgudang.md) |
| 5 | **Bagian Pengadaan** | `pengadaan@simlogrs.local` | `password` | [`uat-mobile-05-pengadaan.md`](./uat-mobile-05-pengadaan.md) |
| 6 | **Kepala Ruangan (Karu)** | `kepalaunit@simlogrs.local` | `password` | [`uat-mobile-06-kepalaunit.md`](./uat-mobile-06-kepalaunit.md) |
| 7 | **Petugas / Staf Ruangan** | `petugasunit@simlogrs.local` | `password` | [`uat-mobile-07-petugasunit.md`](./uat-mobile-07-petugasunit.md) |
| 8 | **Teknisi Sarana IPSRS** | `teknisi@simlogrs.local` | `password` | [`uat-mobile-08-teknisi.md`](./uat-mobile-08-teknisi.md) |
| 9 | **Manajemen Direksi** | `manajemen@simlogrs.local` | `password` | [`uat-mobile-09-manajemen.md`](./uat-mobile-09-manajemen.md) |
| 10 | **Auditor Internal SPI** | `auditor@simlogrs.local` | `password` | [`uat-mobile-10-auditor.md`](./uat-mobile-10-auditor.md) |

---

### Fitur Global & Mekanisme Pengamanan Mobile

1. **Auto Idle Session Timeout**: Aplikasi otomatis mengakhiri sesi, membersihkan token Sanctum, dan mengosongkan state provider jika tidak ada sentuhan layar selama 30 menit.
2. **Anti-Screenshot & Task Snapshot Masking (`FLAG_SECURE`)**: Tampilan aplikasi otomatis dihitamkan pada Recent Apps switcher dan OS memblokir tangkapan layar di lingkungan Android.
3. **Deteksi Integritas Root**: Aplikasi memeriksa binary `su` dan test-keys; banner peringatan interaktif ditampilkan di `LoginScreen` dengan opsi *Pahami Risiko* atau *Keluar Aplikasi*.
4. **Enkripsi Kredensial**: Token autentikasi disimpan di `FlutterSecureStorage` dengan `encryptedSharedPreferences: true` (Android) dan `KeychainAccessibility.first_unlock` (iOS).
5. **Masking Harga Finansial**: Staf ruangan dan teknisi tidak dapat melihat harga beli satuan wholesale atau harga per batch gudang di katalog (di-masking ke `0.0`).
