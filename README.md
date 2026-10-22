# SIMLOG RS Mobile

Klien mobile dan web resmi **SIMLOG RS (Sistem Informasi Manajemen Logistik Rumah Sakit Non-Medis v2)** berbasis **Flutter**. Aplikasi ini mengotomatiskan seluruh siklus rantai pasok rumah sakit—mulai dari perencanaan anggaran, pengadaan, penerimaan gudang berprinsip FEFO, distribusi/amprah ruangan, pemeliharaan sarana prasarana (IPSRS), sirkulasi dan mutasi aset, hingga pengawasan audit internal (CAPA).

Platform target: **Android (APK & App Bundle)** dan **Web (Chrome / PWA)**.  
Status proyek: **Selesai (Production Ready)** — 542 pengujian otomatis lolos, analisis kode bersih (0 issues).

---

## Daftar Isi

1. [Fitur & Kemampuan Utama](#fitur--kemampuan-utama)
2. [Matriks Peran Pengguna (RBAC)](#matriks-peran-pengguna-rbac)
3. [Teknologi & Arsitektur](#teknologi--arsitektur)
4. [Struktur Direktori](#struktur-direktori)
5. [Prasyarat Sistem](#prasyarat-sistem)
6. [Konfigurasi Lingkungan (`dart_defines`)](#konfigurasi-lingkungan-dart_defines)
7. [Menjalankan Aplikasi](#menjalankan-aplikasi)
8. [Build & Distribusi](#build--distribusi)
9. [Pengujian & Verifikasi Kualitas](#pengujian--verifikasi-kualitas)
10. [Dokumentasi Terkait](#dokumentasi-terkait)

---

## Fitur & Kemampuan Utama

### 1. Autentikasi & Keamanan Sesi
- **Token-based Authentication (Sanctum)** dengan *interceptor* otomatis untuk penanganan error 401 dan pembersihan cache lokal (*user data isolation*).
- **Preset Akun Percobaan Cepat (UAT Chip)** pada layar login untuk memudahkan pengujian multi-peran di lapangan.
- **Pergantian Sandi Wajib (*Force Password Change*)** bagi pengguna baru atau akun dengan kata sandi sementara.
- **Pendeteksi Integritas Perangkat**: Peringatan non-blocking jika aplikasi dijalankan pada perangkat dengan akses *root* atau ROM *test-keys*.

### 2. Dashboard Adaptif Multi-Peran
- Tampilan beranda dirancang khusus untuk setiap kelompok kerja:
  - **Dashboard Ruangan/Unit**: Ringkasan amprah aktif, peminjaman aset ruangan, dan tiket servis.
  - **Dashboard Gudang Logistik**: Antrean penerimaan inbound PO, antrean picking distribusi, dan peringatan stok menipis/kedaluwarsa.
  - **Dashboard IPSRS**: Disposisi SPK teknisi, tiket perbaikan masuk, dan jadwal pemeliharaan preventif.
  - **Dashboard Eksekutif & Manajemen**: Ringkasan persetujuan pimpinan, serapan pagu anggaran, dan matriks sirkulasi sarana.
  - **Dashboard Auditor**: Register temuan audit SPI dan pemantauan tindak lanjut CAPA.

### 3. Sirkulasi & Manajemen Aset Fisik
- **Katalog Aset Terpadu**: Profil lengkap aset medis dan non-medis beserta QR code, riwayat servis, mutasi, dan histori peminjaman.
- **Scanner QR Terintegrasi**: Pindai label fisik aset langsung menggunakan kamera gawai.
- **Sirkulasi Peminjaman**: Pengajuan pinjam alat antar-ruangan/gudang, persetujuan Kepala Ruangan, perpanjangan masa pinjam, hingga verifikasi pengembalian fisik.
- **Pengalihan & Mutasi Fisik**: Pemindahan permanen kepemilikan aset ruangan atau redistribusi barang antar-gudang logistik dengan sistem isolasi RBAC ketat.

### 4. Distribusi & Amprah Ruangan
- **Pengajuan Amprah Multi-Item**: Pemilihan barang persediaan dengan alokasi otomatis gudang penyedia berdasarkan ketersediaan stok aktual.
- **Pencatatan Stok Kosong**: Barang dengan stok gudang kosong otomatis dicatat sebagai hutang gudang (*backorder*) tanpa membatalkan pengajuan item lainnya.
- **Otorisasi 2 Meja**: Persetujuan Meja 1 oleh Kepala Unit (Karu) dan Meja 2 oleh Kepala Gudang.
- **Picking & Ekspedisi SPPB**: Antrean pemenuhan barang di gudang hingga konfirmasi serah terima oleh staf ruangan.

### 5. Gudang & Manajemen Persediaan (FEFO)
- **Penerimaan Inbound PO**: Verifikasi surat jalan vendor, pencatatan nomor batch, tanggal kedaluwarsa, dan alokasi rak/bin gudang.
- **Stock Opname Fisik**: Perhitungan fisik berkala per fasilitas gudang dengan alur approval penyesuaian selisih saldo.
- **Monitoring FEFO**: Pelacakan batch yang mendekati kedaluwarsa untuk meminimalkan *spoilage*.

### 6. Pengadaan Barang & Jasa (Procurement)
- **Purchase Requisition (PR)**: Pengusulan kebutuhan barang persediaan dan aset baru dari unit kerja atau gudang logistik.
- **Tracking Purchase Order (PO)**: Pemantauan penerbitan pesanan pembelian ke vendor, rincian harga beli terakhir, dan progres pengiriman.

### 7. Pemeliharaan & IPSRS (Maintenance)
- **Lapor Cepat Kerusakan**: Formulir pelaporan kerusakan alat dengan prioritas penanganan (Cito/Reguler).
- **Manajemen SPK Teknisi**: Disposisi tugas teknisi, pengisian formulir tindakan perbaikan, pergantian suku cadang, dan penutupan tiket servis.
- **Pemeliharaan Preventif**: Kalender pemeliharaan berkala untuk menjaga keandalan sarana vital rumah sakit.

### 8. Audit & Kepatuhan (CAPA)
- Register temuan audit internal (SPI).
- Alur tindak lanjut dan evaluasi tindakan korektif dan preventif (CAPA) antar unit auditee dan auditor.

### 9. Notifikasi Cerdas
- Integrasi **Firebase Cloud Messaging (FCM)** untuk push notification latar belakang.
- Pusat notifikasi in-app dengan perutean langsung (*deep navigation*) ke halaman detail dokumen terkait.

---

## Matriks Peran Pengguna (RBAC)

Aplikasi mengimplementasikan kontrol akses berbasis peran (RBAC) granular untuk 11 peran rumah sakit:

| # | Peran | Kode Role | Cakupan Fitur Utama |
|---|-------|-----------|---------------------|
| 1 | **Super Admin** | `super_admin` | Akses penuh konfigurasi sistem, bypass approval, dan seluruh modul logistik |
| 2 | **Admin Logistik** | `admin_logistik` | Manajemen master data barang/aset, pengadaan, persediaan, dan approval logistik |
| 3 | **Kepala Gudang** | `kepala_gudang` | Otorisasi Meja 2 amprah, stock opname, penyesuaian stok, pengalihan barang gudang |
| 4 | **Petugas Gudang** | `petugas_gudang` | Penerimaan inbound PO, picking distribusi, penataan rak penyimpanan |
| 5 | **Bagian Pengadaan** | `pengadaan` | Verifikasi PR unit/gudang, penerbitan PO vendor, monitoring pesanan |
| 6 | **Kepala Unit / Karu** | `kepala_unit` | Otorisasi Meja 1 amprah ruangan, izin peminjaman aset, pengajuan PR unit |
| 7 | **Petugas / Staf Unit**| `petugas_unit` | Penginputan amprah rutin, pelaporan kerusakan alat, konfirmasi penerimaan SPPB |
| 8 | **Kepala Teknisi** | `kepala_teknisi` | Disposisi SPK perbaikan IPSRS, approval pinjam alat teknisi, preventif maintenance |
| 9 | **Teknisi IPSRS** | `teknisi` | Pelaksanaan lembar kerja SPK, pemeliharaan fisik alat, permohonan suku cadang |
| 10 | **Manajemen Eksekutif**| `manajemen` | Monitoring serapan anggaran unit, laporan persediaan, eksekutif approval |
| 11 | **Auditor Internal (SPI)**| `auditor` | Penerbitan dan evaluasi temuan audit CAPA, audit trail kepatuhan regulasi |

---

## Teknologi & Arsitektur

- **Framework**: [Flutter](https://flutter.dev) 3.47+ / [Dart](https://dart.dev) 3.13+
- **State Management**: [Riverpod](https://riverpod.dev) 2.6 (StateProvider, FutureProvider, StateNotifierProvider)
- **HTTP Client**: [Dio](https://pub.dev/packages/dio) 5.x dengan Custom Interceptors, Token Refresh, dan Unified Error Parsing
- **Iconography**: [Lucide Icons Flutter](https://pub.dev/packages/lucide_icons_flutter)
- **QR / Barcode Scanning**: [Mobile Scanner](https://pub.dev/packages/mobile_scanner) (Android Camera API)
- **Local Storage**: `flutter_secure_storage` & `shared_preferences`
- **Push Notification**: `firebase_core` & `firebase_messaging`
- **Pola Arsitektur**: *Feature-First Layered Architecture* (Core, Shared, Data, Presentation, Providers, Screens, Widgets, Utils).

---

## Struktur Direktori

```text
simlogrs-app/
├── android/                   # Konfigurasi native Android & Gradle
├── assets/                    # Aset grafis, logo, dan ikon
├── dart_defines/              # Template & file konfigurasi environment
│   ├── dev.example.json       # Template konfigurasi development USB / lokal
│   └── wifi.example.json      # Template konfigurasi Wi-Fi LAN
├── docs/                      # Spesifikasi teknis, PRD, desain, dan dokumen UAT
├── lib/
│   ├── core/                  # Utilitas inti: network (Dio), storage, theme, routing, notifikasi
│   │   ├── network/           # DioClient, interceptor, penanganan error API
│   │   ├── notifications/     # FCM Token service, notification payload & router
│   │   ├── offline/           # Queue & sync operasi offline
│   │   └── theme/             # Token warna (AppColors), tipografi, komponen tema Material 3
│   ├── features/              # Modul fungsional (feature-first)
│   │   ├── auth/              # Login, force password change, profile, user model
│   │   ├── dashboard/         # Dashboard modular untuk 11 peran
│   │   ├── aset/              # Katalog aset, detail, sirkulasi pinjam, histori mutasi
│   │   ├── distribusi/        # Pengajuan amprah, otorisasi meja 1 & 2, picking, SPPB
│   │   ├── gudang/            # Inbound PO, stock opname, penyesuaian stok, kartu stok
│   │   ├── pengadaan/         # Permintaan pengadaan (PR), monitoring PO, penerbitan PO
│   │   ├── maintenance/       # Lapor cepat kerusakan, tiket servis, lembar kerja SPK teknisi
│   │   ├── anggaran/          # Screening anggaran unit & serapan pagu logistik
│   │   ├── audit/             # Register temuan audit SPI & alur CAPA
│   │   ├── master/            # Katalog master barang, detail stok gudang/ruangan
│   │   ├── notifikasi/        # Layar notification center & notifikasi in-app
│   │   ├── profile/           # Profil pengguna, ubah sandi, status koneksi
│   │   └── shell/             # Navigasi utama (bottom nav bar adaptif per role)
│   ├── shared/                # Widget global (badge, search bar, empty view, toast, bottom sheet)
│   └── main.dart              # Entry point aplikasi
└── test/                      # 542 unit & widget automated test suite
```

---

## Prasyarat Sistem

1. **Flutter SDK**: Versi `^3.24.0` (disarankan channel stable `3.47.x`).
2. **Dart SDK**: Versi `^3.5.0` (disertakan bersama Flutter).
3. **Android SDK**: API level minimal 24 (Android 7.0), target SDK API 34/36.
4. **Google Chrome**: Untuk pengujian target Web.
5. **Backend Server**: Layanan API SIMLOG RS Laravel v2 yang sedang aktif.

---

## Konfigurasi Lingkungan (`dart_defines`)

Konfigurasi runtime didefinisikan lewat file JSON terpisah agar kredensial atau alamat IP tidak tercampur ke riwayat Git:

1. Buat file `dart_defines/dev.json` dari template:
   ```sh
   cp dart_defines/dev.example.json dart_defines/dev.json
   ```
2. Sesuaikan isi `dart_defines/dev.json`:
   ```json
   {
     "API_BASE_URL": "http://192.168.0.65:8000/api/v1",
     "CONNECT_TIMEOUT": "15000",
     "RECEIVE_TIMEOUT": "15000"
   }
   ```
3. Opsi file konfigurasi:
   - `dart_defines/dev.json`: Digunakan untuk koneksi via kabel data USB atau emulator.
   - `dart_defines/wifi.json`: Digunakan untuk koneksi nirkabel Wi-Fi LAN antara gawai fisik dan PC server.

> **Catatan**: Nilai `--dart-define` dibundel saat proses kompilasi. Jika mengubah alamat IP pada file konfigurasi, lakukan kompilasi ulang (bukan sekadar hot reload).

---

## Menjalankan Aplikasi

### 1. Menjalankan di Browser (Web)
```sh
flutter run -d chrome --dart-define-from-file=dart_defines/dev.json
```

### 2. Menjalankan di Ponsel Android via USB (Kabel Data)
Pastikan USB Debugging aktif di ponsel:
```sh
# Periksa perangkat yang terhubung
flutter devices

# Jalankan langsung ke perangkat Android
flutter run -d <DEVICE_ID> --dart-define-from-file=dart_defines/dev.json
```
*Tips USB ADB Reverse (jika menggunakan `http://127.0.0.1:8000/api/v1`)*:
```sh
adb reverse tcp:8000 tcp:8000
```

### 3. Menjalankan di Ponsel Android via Wi-Fi LAN
Pastikan laptop/PC server dan ponsel terhubung ke jaringan Wi-Fi lokal yang sama:
```sh
flutter run -d <DEVICE_ID> --dart-define-from-file=dart_defines/wifi.json
```

### 4. Menjalankan lewat VS Code
Profil peluncuran sudah siap di `.vscode/launch.json`:
- **SIMLOG Web (Chrome)**
- **SIMLOG Android USB**
- **SIMLOG Android Wi-Fi**

---

## Build & Distribusi

### 1. Build Web Rilis
```sh
flutter build web --release --dart-define-from-file=dart_defines/dev.json
```
Hasil build berada di direktori `build/web/`.

### 2. Build Android APK Rilis
```sh
flutter build apk --release --dart-define-from-file=dart_defines/dev.json
```
Hasil paket APK berada di `build/app/outputs/flutter-apk/app-release.apk`.

### 3. Build APK Hemat Ukuran (*Split Per ABI*)
```sh
flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines/dev.json
```
Menghasilkan APK terpisah untuk arsitektur `armeabi-v7a`, `arm64-v8a`, dan `x86_64`.

### 4. Build Android App Bundle (AAB untuk Google Play Store)
```sh
flutter build appbundle --release --dart-define-from-file=dart_defines/dev.json
```

### 5. Pasang Langsung ke Ponsel via ADB
```sh
adb install -r -d build/app/outputs/flutter-apk/app-release.apk
```

---

## Pengujian & Verifikasi Kualitas

Seluruh fungsionalitas inti telah dilindungi oleh pengujian otomatis yang komprehensif:

```sh
# Menjalankan seluruh test suite (542 tes)
flutter test

# Menjalankan analisis statis kode (Linter)
flutter analyze
```

Cakupan pengujian otomatis meliputi:
- **Matriks Akses & Navigasi RBAC** untuk seluruh 11 peran pengguna.
- **Isolasi State & Cache Antar-Akun**: Mencegah kebocoran data saat berganti peran pada gawai bersama.
- **Alur Transaksi & Form**: Validasi form 2 tahap pengalihan aset, stepper jumlah stok, filter status PO, penutupan SPK teknisi, dan approval berjenjang.
- **Penanganan Kesalahan Jaringan**: Uji respons offline queue, timeout, 401 Unauthorized, 403 Forbidden, dan 422 Unprocessable Entity.

---

## Dokumentasi Terkait

Dokumentasi rancangan dan panduan UAT lengkap tersimpan pada folder [`docs/`](./docs):

- [`docs/prd.md`](./docs/prd.md) — *Product Requirements Document* & aturan bisnis lengkap.
- [`docs/desain.md`](./docs/desain.md) — Pedoman desain antarmuka, palet warna, dan tata letak UI.
- [`docs/NOTIFICATION_CONTRACT.md`](./docs/NOTIFICATION_CONTRACT.md) — Kontrak muatan notifikasi FCM & perutean layar.
- [`docs/FIREBASE_SETUP.md`](./docs/FIREBASE_SETUP.md) — Panduan konfigurasi proyek Firebase Cloud Messaging.
- [`docs/uat-mobile.md`](./docs/uat-mobile.md) — Rangkuman skenario User Acceptance Testing (UAT).
- [`docs/uat-mobile-01-superadmin.md`](./docs/uat-mobile-01-superadmin.md) s/d [`docs/uat-mobile-11-auditor.md`](./docs/uat-mobile-10-auditor.md) — Lembar verifikasi UAT per peran pengguna.
