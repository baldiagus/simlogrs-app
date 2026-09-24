# Master Implementation Prompt: SIMLOG RS Mobile Client (Flutter)
## Autonomous Agent Execution Blueprint (Zero-Hardcode & Zero-Dummy-Data Standard)
### Design Reference: `agents/desain.md` | Skill: `build-your-own-x`

---

## 1. Peran & Mandat Eksekusi Agen

Anda adalah Senior Mobile Systems & Flutter Software Engineer kelas dunia. Anda ditugaskan untuk membangun aplikasi mobile **SIMLOG RS Non-Medis v2** dari nol (*from first principles*) menggunakan framework **Flutter**, mengintegrasikan API backend resmi Laravel 13 Sanctum (`simlog-fix2`), serta mengimplementasikan design system modern dari file rujukan `desain.md`.

---

## 2. Invarian Mutlak (Non-Negotiable Rules)

1. **ZERO DUMMY DATA & ZERO HARDCODE**:
   - **DILARANG KERAS** menyuntikkan data statis palsu, daftar mock, array contoh buatan, atau hardcoded string transaksi di seluruh kode aplikasi.
   - Seluruh metrik angka, antrean dokumen, detail barang, nomor batch, identitas aset, dan riwayat tugas **WAJIB DIAMBIL SECARA REAL-TIME DARI BACKEND API**.
   - Jika endpoint mengembalikan list kosong, tampilkan **Empty State UI** yang elegan dan informatif. Jangan pernah membuat mock data untuk mengisi kekosongan layar.
2. **ZERO ROLE HARDCODING (CAPABILITY-BASED RBAC)**:
   - Dilarang keras melakukan pengecekan nama role secara statis seperti `if (role == 'admin')`.
   - Gunakan pengecekan wewenang dinamis Spatie permissions yang diterima dari respons `GET /api/v1/auth/me` (misal: `user.can('update_pengadaan::permintaan::pengadaan')`, `user.can('create_gudang_stok::picking::distribusi')`).
   - Tombol dan navigasi modul hanya diaktifkan jika token pengguna memiliki wewenang yang sah.
3. **KESELARASAN DESAIN DENGAN `desain.md`**:
   - Gunakan token warna resmi: Primary `#5B50E6`, Primary Gradient `LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF635BF7), Color(0xFF766EF8), Color(0xFF9084FA)])`, Netral `#F7F8FC` (Canvas), `#FFFFFF` (Surface), `#0F172A` (Text Primary), `#64748B` (Text Secondary).
   - Terapkan *Card-based Modular UI* dengan *rounded corners* `20.0` - `24.0`, *soft drop shadows*, serta *Floating Bottom Navigation Bar* dengan *Elevated Center Action Button* untuk pemindaian QR.
4. **5-STAGE ENGINEERING LADDER (BUILD-YOUR-OWN-X)**:
   - **Stage 1 (The Wire)**: Jaringan HTTP murni dengan interceptor token dan kompresi streaming gambar kamera.
   - **Stage 2 (In-Memory Primitive)**: Struktur data domain immutable bebas UI framework coupling.
   - **Stage 3 (Protocol Parsing)**: Parser paket `ApiResponse<T>` yang aman dari runtime casting crash.
   - **Stage 4 (Storage Engine)**: Enkripsi Keychain/Keystore via `flutter_secure_storage` dan antrean mutasi offline.
   - **Stage 5 (Hardening)**: Debounce scanner 1200ms, proteksi race condition tombol aksi, dan optimasi kompresi foto klien.

---

## 3. Spesifikasi Dependensi (`pubspec.yaml`)

Pastikan `pubspec.yaml` memuat dependensi inti standar industri:
```yaml
name: simlog_mobile
description: "Sistem Informasi Manajemen Logistik Rumah Sakit v2 - Mobile Client"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Core State Management & Reactive UI
  flutter_riverpod: ^2.5.1
  
  # Networking & HTTP Client
  dio: ^5.4.3+1
  
  # Secure Storage & Persistence
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.2.3
  
  # Barcode & QR Code Camera Scanner
  mobile_scanner: ^5.1.1
  
  # Camera & Image Picker
  camera: ^0.10.6
  image_picker: ^1.1.2
  flutter_image_compress: ^2.3.0
  
  # Typography & Design System Icons
  google_fonts: ^6.2.1
  lucide_icons: ^0.259.0
  
  # Utilities
  intl: ^0.19.0
  flutter_dotenv: ^5.1.0
  cached_network_image: ^3.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

---

## 4. Panduan Implementasi Bertahap (Step-by-Step Blueprint)

### Fase 1: Fondasi Theme & Token Desain (`desain.md`)

Bangun file `lib/core/theme/` yang mendefinisikan seluruh token visual:

1. `lib/core/theme/app_colors.dart`:
```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary & Accent
  static const Color primaryPurple = Color(0xFF5B50E6);
  static const Color primaryInteractive = Color(0xFF6355F6);
  
  // Functional & Semantics
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color danger = Color(0xFFEF4444);  // Rose
  static const Color warning = Color(0xFFF59E0B); // Amber
  
  // Category Icon Tints (desain.md Sec 2.2)
  static const Color tintBlueBg = Color(0xFFEFF6FF);
  static const Color tintBlueText = Color(0xFF2563EB);
  
  static const Color tintOrangeBg = Color(0xFFFFF7ED);
  static const Color tintOrangeText = Color(0xFFEA580C);
  
  static const Color tintVioletBg = Color(0xFFFAF5FF);
  static const Color tintVioletText = Color(0xFF7C3AED);
  
  static const Color tintTealBg = Color(0xFFF0FDFA);
  static const Color tintTealText = Color(0xFF0D9488);
  
  // Neutral & Canvas (desain.md Sec 2.3)
  static const Color canvas = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F3F9);
  
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFEDF0F7);
}
```

2. `lib/core/theme/app_gradients.dart`:
```dart
import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient primaryHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF635BF7),
      Color(0xFF766EF8),
      Color(0xFF9084FA),
    ],
  );

  static const LinearGradient secondaryAccent = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xB3EEEDFE),
      Color(0xFFFFFFFF),
    ],
  );
}
```

3. `lib/core/theme/app_shadows.dart`:
```dart
import 'package:flutter/material.dart';

class AppShadows {
  static const List<BoxShadow> softCard = [
    BoxShadow(
      color: Color(0x0A0F172A), // 4% rgba(15, 23, 42)
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x050F172A), // 2%
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> heroCard = [
    BoxShadow(
      color: Color(0x2E5B50E6), // 18% rgba(91, 80, 230)
      blurRadius: 25,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
  ];
}
```

---

### Fase 2: Networking, Protokol & Wire Engine

1. `lib/core/network/api_response.dart`:
Standarisasi deserialisasi envelope resmi backend:
```dart
class ApiResponse<T> {
  final bool sukses;
  final String pesan;
  final T? data;
  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.sukses,
    required this.pesan,
    this.data,
    this.meta,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data)? fromJsonT,
  ) {
    return ApiResponse<T>(
      sukses: json['sukses'] as bool? ?? false,
      pesan: json['pesan'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      meta: json['meta'] as Map<String, dynamic>?,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}
```

2. `lib/core/network/api_client.dart`:
Konfigurasi `Dio` dengan `AuthInterceptor` untuk otomatis menyuntikkan token Sanctum:
```dart
import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService secureStorage;

  ApiClient({required this.secureStorage, required String baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token kadaluwarsa / dicabut
            await secureStorage.clearToken();
            // Trigger auto-redirect to Login
          }
          return handler.next(error);
        },
      ),
    );
  }
}
```

---

### Fase 3: Modul Autentikasi & Wewenang Dinamis (No Hardcoded Roles)

1. `lib/features/auth/data/models/user_model.dart`:
```dart
class UserModel {
  final int id;
  final String nama;
  final String? nip;
  final String username;
  final String email;
  final String? noTelepon;
  final String status;
  final UnitModel? unit;
  final GudangModel? gudang;
  final List<String> roles;
  final List<String> permissions;

  UserModel({
    required this.id,
    required this.nama,
    this.nip,
    required this.username,
    required this.email,
    this.noTelepon,
    required this.status,
    this.unit,
    this.gudang,
    required this.roles,
    required this.permissions,
  });

  bool can(String permission) => permissions.contains(permission);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      nama: json['nama'] as String,
      nip: json['nip'] as String?,
      username: json['username'] as String,
      email: json['email'] as String,
      noTelepon: json['no_telepon'] as String?,
      status: json['status'] as String,
      unit: json['unit'] != null ? UnitModel.fromJson(json['unit']) : null,
      gudang: json['gudang'] != null ? GudangModel.fromJson(json['gudang']) : null,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
```

2. Endpoint Login & User Context:
- `POST /api/v1/auth/login`: Menerima email, password, device_name &rarr; Simpan token di `FlutterSecureStorage`.
- `GET /api/v1/auth/me`: Memuat data `UserModel` lengkap dengan permissions.
- `POST /api/v1/auth/logout`: Revoke token aktif dan bersihkan cache lokal.

---

### Fase 4: Antarmuka Beranda (Dashboard) Berdasarkan `desain.md`

Struktur layar `HomeScreen` (`lib/features/dashboard/presentation/screens/home_screen.dart`):

1. **User Top Bar (`desain.md` Sec 5.1)**:
   - Sisi Kiri: Avatar bulat `40x40px` dengan inisial nama pengguna dinamis (misal: "dr. P" untuk dr. Pratama).
   - Teks Sapaan: *"Selamat Bertugas,"* dan Baris kedua nama pengguna + badge unit dinamis (misal: `IGD` atau `Gudang Sentral`).
   - Sisi Kanan: Action icon notifikasi dengan badge indikator jika ada antrean pending.
2. **Hero Balance Card (Operational Status Hero - `desain.md` Sec 5.2)**:
   - Kontainer dengan `AppGradients.primaryHero`, rounded corners `24.0`, dan `AppShadows.heroCard`.
   - Menampilkan total antrean aktif dari API: `Total Antrean Approval: X Dokumen`.
   - Pill Button di kanan atas kartu: `Periksa ->` dengan `Color(0x33FFFFFF)`.
   - Sub-info: Rincian `PR Menunggu` vs `Amprah Menunggu`.
3. **Quick Action Grid 2x2 (`desain.md` Sec 5.3)**:
   - **Kartu 1 (Approval Cepat)**: Icon CheckSquare Violet (`AppColors.tintVioletBg`), judul *"Approval Cepat"*, subtitle dinamis jumlah antrean menanti.
   - **Kartu 2 (Daftar Rak Gudang)**: Icon Archive/Boxes Blue (`AppColors.tintBlueBg`), judul *"Daftar Rak Gudang"*, subtitle *"Stok & Aset per Rak"*.
   - **Kartu 3 (Scan QR Aset)**: Icon QrCode Orange (`AppColors.tintOrangeBg`), judul *"Sirkulasi Aset"*, subtitle *"Serah Terima & Cek"*.
   - **Kartu 4 (Lapor Kerusakan)**: Icon Wrench Teal (`AppColors.tintTealBg`), judul *"Lapor Rusak"*, subtitle *"IPSRS Fieldwork"*.
4. **Live Activity Feed (`desain.md` Sec 5.4)**:
   - Menampilkan aktivitas operasional terkini dari sistem.
   - Baris item: Ikon ber-background kotak membulat (`rounded-2xl`), judul mutasi, timestamp, dan status badge kanan (misal: `DISETUJUI_KARU` warna hijau, `CITO` warna merah).

---

### Fase 5: Modul Persetujuan Cepat (Fast-Approval Center)

1. Tampilan Tab:
   - Tab 1: **Permintaan Pengadaan (PR)**
   - Tab 2: **Amprah Ruangan (Permintaan Distribusi)**
2. Sumber Data: `GET /api/v1/approval/pending`
   - Bind langsung data array `permintaan_pengadaan` dan `permintaan_distribusi`.
3. Komponen Kartu Approval:
   - Menampilkan Kode Dokumen, Unit Pemohon, Pengaju, Tanggal, dan Chip Urgensi (`CITO`, `SEGERA`, `BIASA`).
   - Daftar item barang yang diajukan beserta kuantitasnya.
   - Dua Tombol Aksi di bagian bawah kartu:
     - **Tolak** (Outlined / Danger Pill): Membuka dialog konfirmasi alasan penolakan &rarr; `aksi: "tolak"`.
     - **Setujui** (Solid Purple Pill): Eksekusi persetujuan &rarr; `aksi: "setujui"`.
4. Proteksi Wewenang Dinamis:
   - Tombol PR hanya aktif jika `user.can('update_pengadaan::permintaan::pengadaan')`.
   - Tombol Amprah Meja 1 hanya aktif jika `user.can('update_layanan_unit::approval::karu')`.
   - Tombol Amprah Meja 2 hanya aktif jika `user.can('update_gudang_stok::distribusi::approval')`.

---

### Fase 6: Modul Manajemen Rak Gudang & Inventaris Ruang Simpan

1. Layar Daftar Rak Gudang (`DaftarRakScreen`):
   - Memuat data real-time dari `GET /api/v1/gudang/rak`.
   - Menampilkan list/grid kartu rak penyimpanan (`lokasi_gudang`).
   - Setiap kartu rak memuat: Kode rak (`kode`), nama deskriptif (`nama`), nama gudang induk, jumlah jenis barang (`total_barang`), dan jumlah aset fisik (`total_aset`).
   - Input pencarian di bagian atas untuk memfilter rak berdasarkan kode atau nama.
2. Layar Detail Rak (`DetailRakScreen`):
   - Dibuka saat pengguna memilih salah satu rak (`GET /api/v1/gudang/rak/{id}`).
   - Header menampilkan info rak (kode rak, nama, gudang induk, dan ringkasan total item).
   - Dilengkapi 2 Tab Konten (`TabBar`):
     - **Tab 1 (Barang & Stok Batch)**: Menampilkan seluruh item logistik di rak tersebut beserta nama barang, kode SKU, kategori, nomor batch, tanggal kedaluwarsa, jumlah stok aktual, dan satuan.
     - **Tab 2 (Aset Fisik)**: Menampilkan seluruh sarana/peralatan fisik di rak tersebut beserta kode aset (`AST-...`), nama aset, merk, nomor seri, kondisi fisik, dan status ketersediaan.
   - Filter pencarian cepat (*in-shelf search*) untuk memfilter daftar barang atau aset di rak secara instan.
---

### Fase 7: Modul Sirkulasi Aset & Scanner QR

1. Pindai QR Aset Fisik:
   - Kamera memindai stiker QR pada alat medis/non-medis &rarr; `POST /api/v1/aset/scan-qr`.
   - Menampilkan profil lengkap aset: Nama barang, merk, nomor seri, lokasi saat ini (Unit / Gudang + Rak), status ketersediaan, riwayat servis, serta peringatan jika statusnya sedang `DIPINJAM` dan sudah melewati tanggal rencana kembali (*Overdue*).
2. Konfirmasi Serah Terima Fisik:
   - Tombol `Konfirmasi Serah Terima Fisik` &rarr; `POST /api/v1/aset/serah-terima` dengan `peminjaman_id`.
3. Konfirmasi Pengembalian & Inspeksi Fisik:
   - Formulir inspeksi fisik: Pemilihan kondisi saat kembali (`BAIK`, `RUSAK_RINGAN`, `RUSAK_BERAT`) dan catatan kelengkapan &rarr; `POST /api/v1/aset/kembalikan`.

---

### Fase 8: Modul Pemeliharaan Fasilitas & Mobile Teknisi (IPSRS)

1. Lapor Cepat Kerusakan:
   - Pengambilan foto langsung dari kamera perangkat menggunakan package `camera` atau `image_picker`.
   - Kompresi gambar lokal (resolusi maksimal 1920x1080, JPEG quality 80%) untuk efisiensi jaringan.
   - Pemilihan Aset (via scan QR atau dropdown pencarian), Pilihan Prioritas (`CITO`, `TINGGI`, `SEDANG`, `RENDAH`), dan Deskripsi Masalah.
   - Kirim multipart data ke `POST /api/v1/maintenance/lapor-cepat`.
2. Daftar SPK Teknisi:
   - Menampilkan SPK yang ditugaskan ke teknisi login dari `GET /api/v1/maintenance/spk`.
   - Kartu SPK menampilkan nomor tiket, nama aset, unit lokasi, deskripsi masalah, foto kerusakan awal, dan tanggal target selesai.
3. Lembar Kerja Pengerjaan (Log Maintenance):
   - Teknisi mencatat: Jam Mulai, Jam Selesai, Diagnosa Kerusakan, Tindakan Perbaikan, Hasil Pengerjaan (`BERHASIL`, `PENDING`, `GAGAL`), Foto Bukti Perbaikan, Checklist Uji Kelayakan, dan Pemakaian Suku Cadang (memilih barang suku cadang dan jumlah yang terpotong otomatis secara FEFO).
   - Kirim ke `POST /api/v1/maintenance/spk/{id}/log`.

---

### Fase 9: Floating Bottom Navigation Bar (`desain.md` Sec 5.5)

Komponen navigasi `lib/shared/widgets/floating_bottom_nav_bar.dart`:
- Terpasang melayang (*floating*) di bagian bawah layar dengan margin horizontal `16.0`, margin bawah `16.0`, border radius `24.0`, background putih solid dengan bayangan `AppShadows.softCard`.
- 5 Item Navigasi:
  1. **Beranda**: Icon Home (LucideIcons.home).
  2. **Approval**: Icon CheckSquare (LucideIcons.checkSquare) dengan badge merah jika ada antrean pending.
  3. **Scan QR (Center Elevated Action)**: Tombol lingkaran menonjol ungu (`AppColors.primaryPurple`) dengan icon QrCode putih, diameter `56x56px` dengan bayangan `AppShadows.heroCard`.
  4. **IPSRS**: Icon Wrench (LucideIcons.wrench).
  5. **Profil**: Icon User (LucideIcons.user).

---

## 5. Instruksi Eksekusi Kode untuk Agen

Saat menjalankan implementasi:
1. Awali dengan membuat arsitektur modular lengkap pada folder `lib/core` (Network, Theme, Storage, Models).
2. Bangun `lib/features/auth` dan hubungkan ke backend Laravel (gunakan kredensial seed resmi untuk pengujian: `kepalaunit@simlogrs.local` / `password`, `adminlogistik@simlogrs.local` / `password`, `teknisi@simlogrs.local` / `password`).
3. Bangun `lib/features/dashboard` dengan layout presisi sesuai `desain.md`.
4. Bangun seluruh modul operasional (`approval`, `gudang`, `aset`, `maintenance`) tanpa ada satupun mock data.
5. Jalankan `flutter analyze` atau verifikasi tipe statis untuk memastikan tidak ada syntax error, null-safety violation, atau dynamic typing traps.
