# Product Requirement Document (PRD): SIMLOG RS Mobile Client
## Sistem Informasi Manajemen Logistik Rumah Sakit (Non-Medis) v2
### Arsitektur Klien Mobile: Flutter 3.x (Zero-Hardcode & Zero-Dummy-Data Standard)
### Dokumen Rujukan Desain: `desain.md` / `design.md`

---

## 1. Ringkasan Eksekutif & Visi Produk

SIMLOG RS Non-Medis Mobile adalah aplikasi pendamping (*companion app*) berbasis **Flutter** untuk sistem ERP Logistik Rumah Sakit v2 (`simlog-fix2`). Aplikasi ini dirancang khusus untuk memfasilitasi operasional bergerak (*mobile fieldwork*) di lingkungan rumah sakit:
1. **Persetujuan Cepat (Fast-Approval)**: Kepala Ruangan (Karu), Kepala Unit, Pejabat Pengadaan, dan Manajemen dapat meninjau serta menyetujui dokumen Permintaan Pengadaan (PR) dan Amprah Ruangan (Permintaan Distribusi) secara seketika (*instant swipe/tap approval*).
2. **Manajemen & Monitoring Rak Gudang**: Petugas gudang dan staf dapat meninjau daftar rak penyimpanan (*storage rack*), memilih salah satu rak, dan melihat daftar lengkap aset fisik serta barang/stok batch yang tersimpan di dalam rak tersebut secara real-time.
3. **Sirkulasi Aset Cepat (QR Asset Tracking)**: Perawat dan pengelola aset dapat memindai QR code fisik sarana medis/non-medis untuk melacak riwayat lokasi, status peminjaman aktif, konfirmasi serah terima fisik, dan inspeksi fisik pengembalian.
4. **Pemeliharaan Sarana Tanggap (IPSRS Fieldwork & Lapor Rusak)**: Pelaporan kerusakan fisik fasilitas langsung dari kamera HP (*lapor cepat dengan bukti foto kompresi*), penerimaan Surat Perintah Kerja (SPK) oleh teknisi di lapangan, serta pencatatan lembar kerja dan pemakaian suku cadang berbasis FEFO.

---

## 2. Standar Integritas: Zero-Hardcode & Zero-Dummy-Data Invariant

Aplikasi mobile ini **DIHARAMKAN SECARA MUTLAK** menggunakan data palsu (*dummy data*), mock statis, array contoh buatan di kode, maupun hardcoded peran pengguna. Seluruh komponen antarmuka wajib terikat secara langsung (*100% reactive binding*) ke RESTful API Backend:
1. **Tidak Ada Data Dummy / Mock**:
   - Seluruh daftar (antrean approval, kartu batch, aset, SPK teknisi, riwayat aktivitas) wajib bersumber dari API JSON endpoint.
   - Status jumlah antrean, nama unit, pemohon, harga estimasi, dan tanggal kedaluwarsa ditarik secara dinamis dari database PostgreSQL melalui API v1.
   - Jika data kosong di database, antarmuka wajib menampilkan *Empty State UI* yang elegan, bukan menyuntikkan data contoh.
2. **Tidak Ada Hardcode Role**:
   - Hak akses menu, visibilitas tombol aksi (misal: tombol Setujui PR, tombol Validasi Gudang, tombol Eksekusi SPK) dikendalikan sepenuhnya oleh array `permissions` dan `roles` yang dikembalikan oleh endpoint `GET /api/v1/auth/me`.
   - Menggunakan mekanisme *Capability-Based UI*: Tombol hanya muncul jika token pengguna memiliki wewenang Spatie yang sesuai (contoh: `update_pengadaan::permintaan::pengadaan`, `create_gudang_stok::picking::distribusi`, `create_pemeliharaan::lembar::kerja`).
3. **Konfigurasi Lingkungan Dinamis (Environment Driven)**:
   - Base URL server backend, timeout koneksi, dan konfigurasi API dikelola via konfigurasi `.env` / `flutter_dotenv` atau runtime configuration, bukan hardcoded string di dalam HTTP client.

---

## 3. Penerapan Sistem Desain (`desain.md`)

Seluruh tampilan antarmuka Flutter wajib mengikuti panduan visual pada `desain.md`:

### 3.1 Palet Warna & Token Visual (`desain.md` Sec. 2)
- **Primary Accent Purple**: `#5B50E6` (Utama) dan `#6355F6` (Interaktif)
- **Primary Hero Gradient**: `LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF635BF7), Color(0xFF766EF8), Color(0xFF9084FA)])`
- **Secondary Gradient Accent**: `LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xB3EEEDFE), Color(0xFFFFFFFF)])`
- **Functional Semantics**:
  - Success / Inbound / Valid: `#10B981` (Emerald)
  - Danger / Outbound / Rejected / Non-FEFO / CITO: `#EF4444` (Rose)
  - Warning / Pending / Review: `#F59E0B` (Amber)
- **Category Icon Tints** (Digunakan untuk grid aksi cepat & kategori aktivitas):
  - Blue / Indigo Tint: Container `#EFF6FF` dengan Ikon `#2563EB` (Gudang & Batch)
  - Orange / Peach Tint: Container `#FFF7ED` dengan Ikon `#EA580C` (Peminjaman & Aset)
  - Violet / Purple Tint: Container `#FAF5FF` dengan Ikon `#7C3AED` (Approval & Otorisasi)
  - Teal / Cyan Tint: Container `#F0FDFA` dengan Ikon `#0D9488` (IPSRS Maintenance)
- **Netral & Kanvas**:
  - Background Canvas: `#F7F8FC`
  - Card & Surface: `#FFFFFF`
  - Pill & Secondary Surface: `#F1F3F9`
  - Text Primary: `#0F172A` (Slate 900)
  - Text Secondary: `#64748B` (Slate 500)
  - Border & Hairline Divider: `#EDF0F7`

### 3.2 Tipografi & Skala Spasi (`desain.md` Sec. 3 & 4)
- **Font Family**: `Plus Jakarta Sans` atau `Inter` (Google Fonts).
- **Skala Ukuran**:
  - Hero Metric Display: 28px – 32px | Bold | h: 1.2
  - Section Title / Header H1: 18px – 20px | SemiBold | h: 1.3
  - Card Subheading: 15px – 16px | SemiBold | h: 1.4
  - Body Text: 14px | Regular & Medium | h: 1.5
  - Caption / Meta / Timestamps: 11px – 12px | Medium | h: 1.4
  - Button & Pill Text: 13px – 14px | SemiBold
- **Spasi & Radius**:
  - Base Spacing: 4px grid (8px, 12px, 16px, 20px, 24px).
  - Card Radius: `20.0` – `24.0` (Rounded corners lembut).
  - Input & Search Bar Radius: `16.0` – `20.0`.
  - Button & Action Pills: `12.0` – `999.0` (Fully rounded pills).
  - Elevation & Drop Shadows: `BoxShadow(color: Color(0x0A0F172A), blurRadius: 20, offset: Offset(0, 4))` untuk kartu standar, dan `BoxShadow(color: Color(0x2E5B50E6), blurRadius: 25, offset: Offset(0, 10))` untuk kartu hero aktif.

### 3.3 Struktur Komponen Utama (`desain.md` Sec. 5)
1. **Top Bar Header**:
   - Avatar Pengguna (lingkaran 40x40px berinisial atau foto).
   - Sambutan & nama pengguna dinamis (dari `/api/v1/auth/me`).
   - Quick Action & Notifikasi Pill di pojok kanan atas.
2. **Hero Balance Card (Operational Status Hero)**:
   - Gradasi ungu lembut, menampilkan agregat antrean kerja aktif (Total Menunggu Approval, SPK Berjalan, atau Status Inbound).
   - Chip status dinamis dan tombol aksi cepat berbentuk pill (`Lihat Antrean ->`).
3. **Quick Action Grid (2x2)**:
   - 4 kartu aksi modular dengan *category icon tint*:
     1. **Approval Cepat** (Icon Check-Circle Violet) &rarr; Menuju antrean PR & Amprah.
     2. **Daftar Rak Gudang** (Icon Boxes/Archive Blue) &rarr; Menampilkan daftar rak gudang serta rincian aset dan stok barang di setiap rak.
     3. **Scan QR Aset** (Icon QrCode Orange) &rarr; Membuka scanner sirkulasi & info aset.
     4. **Lapor Rusak IPSRS** (Icon Wrench Teal) &rarr; Membuka form foto kamera pelaporan kerusakan.
4. **Activity List (Live Feed)**:
   - Daftar transaksi real-time terkini (approval terakhir, barang terdistribusi, pembaruan tiket).
   - Ikon kategori ber-background rounded-xl, judul transaksi, timestamp ISO terformat, dan badge status berwarna fungsional.
5. **Floating Bottom Navigation Bar**:
   - Bar navigasi melayang (*docked/floating with margin 16px, border radius 24px*).
   - Item: **Beranda**, **Approval**, **Scan QR (Center Elevated Action)**, **IPSRS**, **Profil**.

---

## 4. Tangga Rekayasa 5 Tahap (The 5-Stage Engineering Ladder)

Sesuai filosofi sistem first-principles `build-your-own-x`, arsitektur Flutter dibangun dengan 5 tahap fondasi:

### Tahap 1: The Wire / I/O Primitive (Jaringan & Komunikasi Mentah)
- Menggunakan `Dio` dengan arsitektur interceptor khusus:
  - **AuthInterceptor**: Menyuntikkan header `Authorization: Bearer <sanctum_token>` secara otomatis dari secure storage pada setiap request.
  - **LoggingInterceptor**: Memantau waktu eksekusi (`meta.waktu_eksekusi_ms`), ukuran payload, dan status HTTP.
  - **ErrorInterceptor**: Menangkap error koneksi (SocketException, Timeout, 401 Unauthorized yang memicu auto-logout, 422 Validation Error).
- **Multipart/Stream Handler**: Menangani unggah file kamera (`foto_kerusakan`, `foto_pengerjaan`) dengan kompresi streaming sebelum transmisi data tanpa membebani memori heap perangkat.

### Tahap 2: In-Memory Data Primitive (Struktur Data Domain Murni)
- Domain entities murni bebas dependensi UI:
  - `User`, `UnitRef`, `GudangRef`
  - `PermintaanPengadaanItem`, `PermintaanDistribusiItem`
  - `RakItem`, `BarangRakItem`, `AsetRakItem`
  - `AsetDetail`, `PeminjamanAktif`
  - `SpkItem`, `LogMaintenanceEntry`, `SparepartUsage`
- Menggunakan `freezed` atau data class immutable dengan pemetaan `fromJson` / `toJson` bertipe ketat (*null-safe*).

### Tahap 3: Protokol & Command Parsing (Standarisasi Paket JSON)
- Parser wrapper terpusat `ApiResponse<T>` yang menguraikan format resmi backend Laravel:
  ```dart
  class ApiResponse<T> {
    final bool sukses;
    final String pesan;
    final T? data;
    final ApiMeta? meta;
    final Map<String, dynamic>? errors;
    ...
  }
  ```
- Menangani deserialisasi array dan objek bersarang secara aman tanpa *runtime casting exception*.

### Tahap 4: Persistence & Storage Engine (Penyimpanan Lokal & Offline Queue)
- **Flutter Secure Storage**: Menyimpan Bearer Token Sanctum dengan enkripsi Keychain (iOS) dan Keystore/EncryptedSharedPreferences (Android).
- **Local Storage Engine (SQLite / Drift / Hive)**:
  - Menyimpan cache profil pengguna dan daftar permissions untuk verifikasi instan saat startup offline.
  - **Offline Mutation Queue**: Menyimpan antrean perhitungan *blind count* opname atau laporan kerusakan jika teknisi berada di ruang isolasi / basement rumah sakit tanpa sinyal internet. Begitu sinyal pulih, sinkronisasi otomatis (*flush queue*) dijalankan.

### Tahap 5: Concurrency & Performance Hardening (Stabilitas & Optimasi)
- **Scanner Debouncer**: Menghentikan proses pembacaan ganda (*duplicate scans*) pada kamera barcode dengan timer throttle 1200ms.
- **Race Condition Prevention**: Tombol `Setujui` dan `Tolak` langsung mengaktifkan state *in-flight disabled* seketika untuk mencegah *double-tap submission*.
- **Client-Side Image Optimization**: Foto kamera HP (berukuran 5MB - 12MB) dikompresi otomatis di perangkat klien menjadi maksimal 1920x1080 JPEG (~300KB) sebelum dikirimkan ke endpoint `/api/v1/maintenance/lapor-cepat`.

---

## 5. Rincian Modul Fungsional & Kontrak API

Aplikasi mobile mengintegrasikan 5 kontroler API resmi dari backend Laravel:

```
                      [ FLUTTER MOBILE APP ]
                                │
               HTTP/HTTPS + Sanctum Bearer Token
                                ▼
         ┌──────────────────────────────────────────────┐
         │              ROUTES / API V1                 │
         └──────────────────────┬───────────────────────┘
                                │
   ┌───────────────┬────────────┴───┬───────────────┬───────────────┐
   ▼               ▼                ▼               ▼               ▼
[Auth]        [Approval]        [Gudang]         [Aset]       [Maintenance]
/auth/*       /approval/*       /gudang/*        /aset/*      /maintenance/*
- login       - pending         - rak            - scan-qr    - lapor-cepat
- logout      - pr/{id}         - rak/{id}       - serah-     - spk (list)
- me          - amprah/{id}                        terima     - spk/{id}
                                                 - kembalikan - spk/{id}/log
```

### 5.1 Modul Autentikasi & Profil Pengguna (`/api/v1/auth/*`)
- **Login Screen**:
  - Input Email & Password, field nama perangkat (`device_name`).
  - Request: `POST /api/v1/auth/login`
    ```json
    {
      "email": "kepalaunit@simlogrs.local",
      "password": "password",
      "device_name": "Samsung Galaxy S23 (Karu IGD)"
    }
    ```
  - Response: Menyimpan `token` ke Secure Storage dan navigasi ke portal utama.
- **Session Check & Profil**:
  - Request: `GET /api/v1/auth/me`
  - Mengambil data nama, NIP, unit dinas, gudang dinas, serta list permissions.
  - Logout: `POST /api/v1/auth/logout` &rarr; Menghapus token lokal dan mengarahkan kembali ke login.

### 5.2 Modul Persetujuan Cepat (Approval Center - `/api/v1/approval/*`)
- **Antrean Persetujuan Terpadu (`GET /api/v1/approval/pending`)**:
  - Menampilkan dua tab: **Permintaan Pengadaan (PR)** dan **Amprah Ruangan (Permintaan Distribusi)**.
  - Setiap kartu dokumen menampilkan: Kode dokumen, unit pemohon, nama pengaju, tanggal, badge urgensi (CITO: Merah, SEGERA: Oranye, BIASA: Abu-abu), jumlah item, dan rincian barang.
- **Eksekusi Approval PR (`POST /api/v1/approval/pr/{id}`)**:
  - Payload: `{"aksi": "setujui" | "tolak", "catatan": "Catatan persetujuan/penolakan"}`
  - Proteksi Wewenang: Memeriksa permission `update_pengadaan::permintaan::pengadaan`.
- **Eksekusi Approval Amprah (`POST /api/v1/approval/amprah/{id}`)**:
  - Payload: `{"aksi": "setujui" | "tolak", "catatan": "Catatan persetujuan/penolakan"}`
  - Mendukung persetujuan 2 meja otomatis:
    - Meja 1: Status `DIAJUKAN` &rarr; Disetujui Karu menjadi `DISETUJUI_KARU` (Permission: `update_layanan_unit::approval::karu`).
    - Meja 2: Status `DISETUJUI_KARU` &rarr; Disetujui Gudang menjadi `DISETUJUI_GUDANG` (Permission: `update_gudang_stok::distribusi::approval`).

### 5.3 Modul Rak Gudang & Inventaris Ruang Simpan (`/api/v1/gudang/*`)
- **Daftar Rak Gudang (`GET /api/v1/gudang/rak`)**:
  - Parameter kueri opsional: `gudang_id` (filter ID gudang spesifik), `cari` (kata kunci pencarian kode/nama rak).
  - Response: Daftar seluruh rak penyimpanan (`lokasi_gudang`) di gudang aktif:
    - `id`: ID lokasi rak.
    - `kode`: Kode rak penyimpanan (contoh: `RAK-ATK-01`, `RAK-ALKES-02`).
    - `nama`: Nama deskriptif rak (contoh: `Rak ATK Sentral Lantai 1`).
    - `gudang_id` & `nama_gudang`: Identitas gudang induk.
    - `total_barang`: Agregat jumlah jenis barang/SKU yang tersimpan di rak.
    - `total_aset`: Agregat jumlah unit fisik sarana/aset yang berada di rak.
  - Tampilan UI: Card list modular dengan badge kapasitas, ikon ruang simpan, dan navigasi sentuh menuju detail rak.
- **Detail Rak: Inventaris Barang & Aset (`GET /api/v1/gudang/rak/{id}`)**:
  - Menampilkan informasi lengkap satu rak spesifik ketika diklik oleh pengguna, dengan antarmuka 2 tab utama:
    1. **Tab 1: Daftar Barang & Stok Batch**:
       - Menampilkan seluruh item logistik/barang yang tersimpan di rak tersebut.
       - Rincian per item: Nama barang, kode barang, kategori, satuan, nomor batch, tanggal kedaluwarsa (*expired date*), status kedaluwarsa, dan jumlah kuantitas stok fisik saat ini.
    2. **Tab 2: Daftar Aset Fisik**:
       - Menampilkan seluruh peralatan/sarana fisik rumah sakit yang ditempatkan pada rak tersebut.
       - Rincian per aset: Kode aset (`AST-...`), nama aset/sarana, merk & model, nomor seri, status ketersediaan (`TERSEDIA`, `DIPINJAM`, `DALAM_MAINTENANCE`), dan kondisi fisik (`BAIK`, `RUSAK_RINGAN`, `RUSAK_BERAT`).
  - Fitur Filter & Pencarian: Pencarian cepat (*real-time search bar*) di dalam rak untuk menemukan barang atau aset tertentu secara instan.

### 5.4 Modul Sirkulasi Aset & Scanner QR (`/api/v1/aset/*`)
- **Pindai QR Aset (`POST /api/v1/aset/scan-qr`)**:
  - Payload: `{"kode_aset": "AST-2026-0001"}`
  - Mengembalikan informasi lengkap: Nama aset, merk, spesifikasi, lokasi saat ini (Unit / Gudang + Nama Rak), status terkini (`TERSEDIA`, `DIPINJAM`, `DALAM_MAINTENANCE`, `RUSAK`), kondisi fisik, serta status peminjaman aktif jika sedang dipinjam (termasuk deteksi keterlambatan *overdue*).
- **Konfirmasi Serah Terima Fisik (`POST /api/v1/aset/serah-terima`)**:
  - Payload: `{"peminjaman_id": 5}`
  - Mengubah status peminjaman dari `DISETUJUI` menjadi `DIPINJAM` dan mencatat waktu serah terima resmi.
- **Konfirmasi Pengembalian & Cek Fisik (`POST /api/v1/aset/kembalikan`)**:
  - Payload:
    ```json
    {
      "peminjaman_id": 5,
      "inspeksi": [
        {
          "permintaan_peminjaman_detail_id": 10,
          "aset_id": 3,
          "kondisi_saat_kembali": "BAIK",
          "catatan": "Fisik lengkap dan berfungsi normal"
        }
      ],
      "catatan": "Pengembalian tepat waktu"
    }
    ```
  - Memperbarui lokasi aset kembali ke unit/gudang penyedia dan menutup transaksi peminjaman.

### 5.5 Modul Pemeliharaan Fasilitas & Mobile Teknisi (`/api/v1/maintenance/*`)
- **Lapor Cepat Kerusakan Sarana (`POST /api/v1/maintenance/lapor-cepat`)**:
  - Input: Pindai QR Aset / Pilih Aset, Deskripsi Masalah, Prioritas (`RENDAH`, `SEDANG`, `TINGGI`, `CITO`), dan Foto Kamera Fisik.
  - Multi-part form upload: File gambar dioptimasi di perangkat klien.
  - Jika prioritas CITO/TINGGI, backend otomatis mengubah status aset menjadi `DALAM_MAINTENANCE` dan menerbitkan tiket `MNT-...` ke dashboard IPSRS.
- **Daftar SPK Teknisi (`GET /api/v1/maintenance/spk`)**:
  - Menampilkan daftar surat perintah kerja perbaikan dengan filter status (`DITUGASKAN`, `DITERIMA`, `SELESAI`).
  - Mengurutkan SPK aktif di urutan teratas secara otomatis.
- **Detail SPK & Log Pengerjaan (`POST /api/v1/maintenance/spk/{id}/log`)**:
  - Teknisi mengisi: Jam mulai, jam selesai, diagnosa teknis, tindakan perbaikan, hasil (`BERHASIL`, `PENDING`, `GAGAL`), foto bukti perbaikan, checklist uji fungsi kelaikan, serta pencatatan suku cadang yang digunakan.
  - Backend otomatis memotong stok batch suku cadang secara FEFO dengan penguncian pesimis (*pessimistic locking*).

---

## 6. Arsitektur Struktur Direktori Flutter

Struktur proyek Flutter mengadopsi standar *Feature-First Modular Architecture*:

```text
lib/
├── core/
│   ├── config/
│   │   ├── app_config.dart          # Base URL, API version, timeout settings
│   │   └── env.dart                 # Environment loader
│   ├── constants/
│   │   ├── api_endpoints.dart       # Seluruh rute API /api/v1/*
│   │   └── storage_keys.dart        # Kunci secure storage & preferences
│   ├── network/
│   │   ├── api_client.dart          # Wrapper Dio singleton
│   │   ├── api_response.dart        # Model ApiResponse<T> & ApiMeta
│   │   ├── auth_interceptor.dart    # Penyuntik Bearer Token
│   │   └── error_handler.dart       # Penerjemah galat 401, 403, 404, 422
│   ├── storage/
│   │   ├── secure_storage_service.dart # Keychain / Keystore manager
│   │   └── offline_queue_service.dart  # Antrean mutasi offline
│   ├── theme/
│   │   ├── app_colors.dart          # Palet warna resmi desain.md
│   │   ├── app_typography.dart      # Tipografi Plus Jakarta Sans
│   │   ├── app_gradients.dart       # Gradasi hero violet & secondary
│   │   ├── app_shadows.dart         # Drop shadow elevation tokens
│   │   └── app_theme.dart           # ThemeData Flutter
│   └── utils/
│       ├── currency_formatter.dart  # Format Rupiah (Rp xx.xxx)
│       ├── date_formatter.dart      # Format tanggal lokal Indonesia
│       └── image_compressor.dart    # Kompresi gambar kamera sebelum unggah
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/user_model.dart
│   │   │   └── repositories/auth_repository.dart
│   │   ├── presentation/
│   │   │   ├── providers/auth_provider.dart
│   │   │   └── screens/login_screen.dart
│   ├── dashboard/
│   │   ├── presentation/
│   │   │   ├── providers/dashboard_provider.dart
│   │   │   ├── screens/home_screen.dart
│   │   │   └── widgets/
│   │   │       ├── hero_status_card.dart
│   │   │       ├── quick_action_grid.dart
│   │   │       ├── live_activity_feed.dart
│   │   │       └── user_top_bar.dart
│   ├── approval/
│   │   ├── data/
│   │   │   ├── models/approval_item_model.dart
│   │   │   └── repositories/approval_repository.dart
│   │   ├── presentation/
│   │   │   ├── providers/approval_provider.dart
│   │   │   ├── screens/approval_center_screen.dart
│   │   │   └── widgets/approval_card.dart
│   ├── gudang/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── rak_model.dart
│   │   │   │   ├── barang_rak_model.dart
│   │   │   │   └── aset_rak_model.dart
│   │   │   └── repositories/gudang_repository.dart
│   │   ├── presentation/
│   │   │   ├── providers/gudang_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── daftar_rak_screen.dart
│   │   │   │   └── detail_rak_screen.dart
│   │   │   └── widgets/
│   │   │       ├── rak_card_item.dart
│   │   │       ├── barang_rak_list_tab.dart
│   │   │       └── aset_rak_list_tab.dart
│   ├── aset/
│   │   ├── data/
│   │   │   ├── models/aset_detail_model.dart
│   │   │   └── repositories/aset_repository.dart
│   │   ├── presentation/
│   │   │   ├── providers/aset_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── qr_scanner_screen.dart
│   │   │   │   ├── aset_detail_screen.dart
│   │   │   │   └── aset_return_screen.dart
│   │   │   └── widgets/kondisi_selector_widget.dart
│   ├── maintenance/
│   │   ├── data/
│   │   │   ├── models/spk_model.dart
│   │   │   └── repositories/maintenance_repository.dart
│   │   ├── presentation/
│   │   │   ├── providers/maintenance_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── lapor_cepat_screen.dart
│   │   │   │   ├── spk_list_screen.dart
│   │   │   │   ├── spk_detail_screen.dart
│   │   │   │   └── lembar_kerja_screen.dart
│   │   │   └── widgets/sparepart_picker_widget.dart
│   └── profile/
│       └── presentation/screens/profile_screen.dart
├── shared/
│   └── widgets/
│       ├── floating_bottom_nav_bar.dart # Floating bottom nav (desain.md Sec 5.5)
│       ├── custom_button.dart           # Pill action button
│       ├── status_badge.dart            # Badge status fungsional
│       └── empty_state_view.dart        # Tampilan kosong tanpa dummy data
└── main.dart                            # Titik masuk aplikasi
```

---

## 7. Rencana Rilis & Kriteria Penerimaan

| Milestone | Ruang Lingkup | Kriteria Penerimaan |
|---|---|---|
| **M1: Core & Auth** | Setup Dio, Secure Storage, Theme `desain.md`, Login Screen, `auth/me` | Berhasil login dengan akun seeded (`kepalaunit@simlogrs.local`), menyimpan Bearer token, dan memuat profil dinamis. |
| **M2: Dashboard & Shell** | Floating Bottom Nav, Hero Gradient Card, 2x2 Quick Action, Activity Feed | Dashboard menampilkan metrik riil dari API tanpa 1 pun data dummy; navigasi responsif. |
| **M3: Approval Center** | Tab PR & Amprah, Swipe/Button Approve & Reject, Modal Catatan | Karu / Admin Logistik dapat mengesahkan permohonan; status backend berubah seketika di database. |
| **M4: Manajemen Rak Gudang** | Daftar Rak Gudang, Detail Rak, Tab Barang & Stok Batch, Tab Aset Fisik | Pengguna dapat melihat daftar rak gudang, memilih salah satu rak, dan melihat daftar lengkap barang beserta aset di rak tersebut. |
| **M5: Aset & Sirkulasi** | Scan QR Aset, Info Lokasi & Status, Serah Terima Fisik, Pengembalian | Scanner mengenali kode aset; serah terima dan inspeksi fisik berhasil mengupdate status di backend. |
| **M6: IPSRS Fieldwork** | Lapor Cepat (Upload Foto Kamera), Daftar SPK Teknisi, Lembar Kerja & Suku Cadang | Laporan menerbitkan tiket `MNT-...`; teknisi mengisi lembar kerja dan memotong stok suku cadang secara FEFO. |
