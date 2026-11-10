# Laporan Audit Keamanan Aplikasi (SIMLOG RS Mobile Client)

## 1. Ringkasan Eksekutif

Audit keamanan komprehensif dilakukan terhadap repositori `simlogrs-app` (klien mobile SIMLOG RS berbasis Flutter/Dart untuk platform Android/Web). Audit dilakukan dengan metode *defensive source-first analysis* tanpa memodifikasi kode sumber aplikasi.

Target audit adalah aplikasi manajemen logistik rumah sakit yang mengelola komoditas kritis (obat-obatan, reagen, bahan medis habis pakai, dan pemeliharaan alat medis) dengan 11 peran otorisasi. Hasil audit menemukan **8 temuan keamanan**, mencakup kerentanan kritis kebocoran kredensial default pada antarmuka rilis, kegagalan implementasi certificate pinning, lalu lintas HTTP tidak terenkripsi, serta isolasi data sesi pada antrean mutasi *offline*.

### Matriks Distribusi Tingkat Keparahan

| Keparahan | Jumlah | Deskripsi Dampak |
|:---|:---:|:---|
| **Critical** | 1 | Kompromi kredensial langsung & pengambilalihan akun peran administratif |
| **High** | 3 | Kegagalan enkripsi transmisi, pinning bypass, kebocoran sesi *cross-user* |
| **Medium** | 2 | Kontrol integritas lingkungan advisory, navigasi tanpa validasi peran |
| **Low** | 2 | Fail-open keystore signing, potensi crash kehabisan memori heap |
| **Total** | **8** | |

---

## 2. Ruang Lingkup dan Metodologi

- **Target Repositori**: `simlogrs-app` (Flutter Mobile Client v1.0.0+1)
- **Komponen Inti yang Diperiksa**:
  - Lapisan Autentikasi & Penyimpanan Kredensial (`lib/features/auth/`, `lib/core/storage/`)
  - Lapisan Jaringan & Transport Security (`lib/core/network/`, `android/.../network_security_config.xml`)
  - Logika Sinkronisasi & Antrean Offline (`lib/core/offline/`)
  - Penanganan Notifikasi & Routing (`lib/core/notifications/`, `lib/features/shell/`)
  - Konfigurasi Keamanan Native Android (`android/app/src/main/AndroidManifest.xml`, `MainActivity.kt`, `build.gradle.kts`)
- **Standar Rujukan**:
  - OWASP Mobile Application Security Verification Standard (MASVS v2.0)
  - OWASP Mobile Top 10 (2024)
  - CWE (Common Weakness Enumeration)

---

## 3. Ringkasan Temuan Keamanan

| ID | Tingkat | Judul Temuan | Komponen / Berkas Terdampak | Pemetaan OWASP / CWE |
|:---|:---:|:---|:---|:---|
| **SEC-01** | **Critical** | Hardcoded Kredensial Default dan Akun Peran Administratif pada UI Rilis | `lib/features/auth/presentation/screens/login_screen.dart` | OWASP M9 / CWE-798 |
| **SEC-02** | **High** | Implementasi SSL Certificate Pinning Cacat Menggunakan `badCertificateCallback` | `lib/core/network/dio_client.dart` | OWASP M5 / CWE-295 |
| **SEC-03** | **High** | Izin Lalu Lintas HTTP Cleartext Global pada Android Manifest & NetSec Config | `android/app/src/main/AndroidManifest.xml`, `network_security_config.xml` | OWASP M5 / CWE-319 |
| **SEC-04** | **High** | Persistensi Antrean Mutasi Offline Menyebabkan Kebocoran Sesi Antar-Pengguna | `lib/core/offline/offline_queue.dart`, `auth_provider.dart` | OWASP M1 / CWE-312, CWE-488 |
| **SEC-05** | **Medium** | Deteksi Root Bersifat Advisory dan Mudah Dilewati | `MainActivity.kt`, `login_screen.dart` | OWASP M8 / CWE-693 |
| **SEC-06** | **Medium** | Navigasi Otomatis Payload Notifikasi Tanpa Verifikasi Otorisasi Peran | `lib/features/shell/presentation/screens/main_shell_screen.dart` | OWASP M6 / CWE-862 |
| **SEC-07** | **Low** | Build Rilis Memiliki Fallback Otomatis ke Debug Keystore Publik | `android/app/build.gradle.kts` | OWASP M8 / CWE-296 |
| **SEC-08** | **Low** | Pembacaan Seluruh Berkas Lampiran ke Memori Heap Menimbulkan Risiko OOM | `audit_repository.dart`, `maintenance_repository.dart` | OWASP M10 / CWE-400 |

---

## 4. Rekomendasi Remediasi Strategis

1. **Prioritas 1 (Segera / Pra-Rilis Produksi)**:
   - Bersihkan seluruh chip akun percobaan dan hardcoded kata sandi (`SimlogRS@2026!`) dari `login_screen.dart`. Gunakan *flavor/build-mode flag* (`kDebugMode`) jika preset hanya diperlukan saat pengembangan lokal.
   - Nonaktifkan `cleartextTrafficPermitted` pada `network_security_config.xml` dan hapus `android:usesCleartextTraffic="true"` di `AndroidManifest.xml`.
   - Benahi mekanisme Certificate Pinning di `DioClient` dengan validasi sertifikat yang ketat pada *handshake*, bukan via `badCertificateCallback` yang hanya aktif saat sertifikat dianggap tidak tepercaya oleh OS.
2. **Prioritas 2 (Peningkatan Tata Kelola Data & Sesi)**:
   - Modifikasi `OfflineQueue` agar mengaitkan setiap mutasi dengan `user_id` aktif. Bersihkan atau kunci antrean saat fungsi `logout()` dijalankan agar tidak terjadi pengiriman mutasi silang akun.
   - Pindahkan data mutasi offline sensitif dari `SharedPreferences` polos ke media terenkripsi (`FlutterSecureStorage` atau database terenkripsi).
   - Perketat validasi wewenang peran pada `_bukaTujuan` di `main_shell_screen.dart` sebelum melakukan *push* rute tampilan operasional.
3. **Prioritas 3 (Penguatan Lingkungan Rilis)**:
   - Buat build rilis gagal (*fail-closed*) jika `key.properties` tidak ditemukan, guna mencegah distribusi berkas biner berpenandatangan kunci debug.
   - Gunakan pustaka kompresi dan *streaming upload* (`MultipartFile.fromFile`) guna menghindari lonjakan alokasi memori heap pada perangkat berkapasitas rendah.

---

*Detail teknis, bukti kode, skenario eksploitasi, dan panduan perbaikan rinci tersedia pada berkas `docs/FINDINGS-DETAIL.md`.*
