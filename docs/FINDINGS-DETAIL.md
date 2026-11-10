# Rincian Temuan Audit Keamanan (SIMLOG RS Mobile)

Dokumen ini memuat analisis teknis mendalam untuk setiap kerentanan yang teridentifikasi selama audit keamanan terhadap `simlogrs-app`.

---

### SEC-01: Hardcoded Kredensial Default dan Akun Peran Administratif pada UI Rilis

- **Tingkat Keparahan**: **Critical**
- **Kategori OWASP Mobile**: M9: Insecure Data Storage / Insecure Communication, M8: Security Misconfiguration
- **CWE**: CWE-798 (Use of Hard-coded Credentials), CWE-200 (Exposure of Sensitive Information)
- **Komponen / Lokasi**:
  - `lib/features/auth/presentation/screens/login_screen.dart` (baris 325–342, baris 355–381)

#### 1. Bukti Kode Sumber
```dart
// lib/features/auth/presentation/screens/login_screen.dart:325-342
Wrap(
  spacing: 6,
  runSpacing: 6,
  children: [
    _buildRoleChip('Super Admin', 'superadmin@simlogrs.local'),
    _buildRoleChip('Admin Logistik', 'adminlogistik@simlogrs.local'),
    _buildRoleChip('Kepala Gudang', 'kepalagudang@simlogrs.local'),
    _buildRoleChip('Petugas Gudang', 'petugasgudang@simlogrs.local'),
    _buildRoleChip('Pengadaan', 'pengadaan@simlogrs.local'),
    _buildRoleChip('Karu IGD', 'kepalaunit@simlogrs.local'),
    _buildRoleChip('Petugas Unit', 'petugasunit@simlogrs.local'),
    _buildRoleChip('Kepala Teknisi', 'karu_ipsrs@simlogrs.local'),
    _buildRoleChip('Teknisi IPSRS', 'teknisi@simlogrs.local'),
    _buildRoleChip('Manajemen', 'manajemen@simlogrs.local'),
    _buildRoleChip('Auditor SPI', 'auditor@simlogrs.local'),
  ],
)

// lib/features/auth/presentation/screens/login_screen.dart:355-364
Widget _buildRoleChip(String label, String email) {
  return InkWell(
    onTap: () {
      ref.read(authStateProvider.notifier).clearError();
      setState(() {
        _emailController.text = email;
        _passwordController.text = 'SimlogRS@2026!';
      });
    },
    ...
```

#### 2. Analisis Akar Masalah & Skenario Ancaman
- Komponen chip preset akun percobaan dan kata sandi default `SimlogRS@2026!` dikompilasi langsung ke dalam antarmuka aplikasi produksi tanpa pembungkus kondisi lingkungan seperti `if (kDebugMode)`.
- Siapa pun yang menginstal berkas APK rilis atau mengakses build Web dapat melihat daftar lengkap alamat email seluruh administrator sistem dan peran kritis rumah sakit.
- Mengetuk salah satu chip otomatis mengisi form dengan kata sandi default `SimlogRS@2026!`. Jika akun backend di-seed atau belum mewajibkan reset kata sandi unik, penyerang dapat langsung masuk sebagai `Super Admin` atau `Admin Logistik` dengan hak istimewa penuh.

#### 3. Rekomendasi Perbaikan
Bungkus blok widget preset akun dengan pemeriksaan mode debug (`kDebugMode`) atau hapus sepenuhnya dari build rilis:
```dart
if (kDebugMode)
  Container(
    ... // Preset akun dan kata sandi hanya aktif saat proses debug
  )
```
Di sisi backend, pastikan seluruh akun produksi tidak menggunakan kata sandi default statis saat inisialisasi awal.

---

### SEC-02: Implementasi SSL Certificate Pinning Cacat Menggunakan `badCertificateCallback`

- **Tingkat Keparahan**: **High**
- **Kategori OWASP Mobile**: M5: Insecure Communication
- **CWE**: CWE-295 (Improper Certificate Validation)
- **Komponen / Lokasi**:
  - `lib/core/network/dio_client.dart` (baris 42–58)

#### 1. Bukti Kode Sumber
```dart
// lib/core/network/dio_client.dart:42-58
const sslFingerprint = String.fromEnvironment('SSL_FINGERPRINT', defaultValue: '');
if (!kIsWeb && sslFingerprint.isNotEmpty) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        final digest = sha256.convert(cert.der).toString().toUpperCase();
        final expected = sslFingerprint.toUpperCase().replaceAll(':', '').replaceAll(' ', '');
        return digest == expected;
      };
      return client;
    },
  );
}
```

#### 2. Analisis Akar Masalah & Skenario Ancaman
- Pada Dart `dart:io.HttpClient`, properti `badCertificateCallback` **hanya dipanggil ketika validasi sertifikat standar sistem operasi GAGAL** (misalnya sertifikat self-signed atau expired).
- Jika penyerang melakukan Man-in-the-Middle (MitM) menggunakan sertifikat yang diterbitkan oleh Certificate Authority (CA) yang tepercaya oleh sistem (atau sertifikat CA internal rumah sakit/proksi perusahaan yang terpasang di sistem root Android), **`badCertificateCallback` TIDAK PERNAH DIJALANKAN**.
- Validasi TLS berhasil secara otomatis tanpa pernah mencocokkan sidik jari (`SSL_FINGERPRINT`). Akibatnya, perlindungan certificate pinning yang diharapkan tidak berjalan.
- Selain itu, nilai default parameter `SSL_FINGERPRINT` adalah string kosong (`defaultValue: ''`), dan tidak disertakan pada file konfigurasi `dart_defines/*.json`.

#### 3. Rekomendasi Perbaikan
Gunakan pendekatan certificate pinning sejati pada level TLS connection handshake atau gunakan pustaka teruji seperti `http_certificate_pinning` atau konfigurasikan `SecurityContext` kustom yang hanya mempercayai root certificate yang disematkan (*asset bundling*):
```dart
final context = SecurityContext(withTrustedRoots: false);
context.setTrustedCertificatesBytes(certBytes);
final client = HttpClient(context: context);
```

---

### SEC-03: Izin Lalu Lintas HTTP Cleartext Global pada Android Manifest & NetSec Config

- **Tingkat Keparahan**: **High**
- **Kategori OWASP Mobile**: M5: Insecure Communication
- **CWE**: CWE-319 (Cleartext Transmission of Sensitive Information)
- **Komponen / Lokasi**:
  - `android/app/src/main/AndroidManifest.xml` (baris 12)
  - `android/app/src/main/res/xml/network_security_config.xml` (baris 4)
  - `dart_defines/wifi.json`, `dart_defines/dev.json`

#### 1. Bukti Kode Sumber
```xml
<!-- android/app/src/main/AndroidManifest.xml:11-13 -->
<application
    ...
    android:usesCleartextTraffic="true"
    android:networkSecurityConfig="@xml/network_security_config">
```
```xml
<!-- android/app/src/main/res/xml/network_security_config.xml:1-5 -->
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- Allow cleartext HTTP traffic for local LAN development and hospital intranet testing -->
    <base-config cleartextTrafficPermitted="true" />
</network-security-config>
```

#### 2. Analisis Akar Masalah & Skenario Ancaman
- Pengaturan `<base-config cleartextTrafficPermitted="true" />` mengizinkan seluruh koneksi HTTP tanpa TLS ke domain manapun.
- Aplikasi mentransmisikan token otentikasi Sanctum Bearer, kredensial login, data persediaan obat, dan laporan kerusakan dalam format JSON teks polos.
- Pada jaringan Wi-Fi rumah sakit atau jaringan publik, aktor jahat yang melakukan packet sniffing (ARP poisoning / rogue AP) dapat menyadap token otentikasi aktif dan membajak sesi pengguna.

#### 3. Rekomendasi Perbaikan
- Ubah `network_security_config.xml` agar secara default melarang cleartext, dan batasi cleartext hanya pada domain pengujian lokal tertentu jika diperlukan:
```xml
<network-security-config>
    <base-config cleartextTrafficPermitted="false" />
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">10.0.2.2</domain>
        <domain includeSubdomains="false">127.0.0.1</domain>
    </domain-config>
</network-security-config>
```
- Set `android:usesCleartextTraffic="false"` pada build rilis AndroidManifest.

---

### SEC-04: Persistensi Antrean Mutasi Offline Menyebabkan Kebocoran Sesi Antar-Pengguna

- **Tingkat Keparahan**: **High**
- **Kategori OWASP Mobile**: M1: Improper Credential Usage / Insecure Data Storage, M2: Inadequate Supply Chain / State Management
- **CWE**: CWE-312 (Cleartext Storage of Sensitive Information), CWE-488 (Exposure of Data Element to Wrong Session)
- **Komponen / Lokasi**:
  - `lib/core/offline/offline_queue.dart` (baris 56–125)
  - `lib/core/offline/offline_sync_service.dart` (baris 18–49)
  - `lib/features/auth/presentation/providers/auth_provider.dart` (`logout()` & `handleSessionTimeout()`)

#### 1. Bukti Kode Sumber
```dart
// lib/core/offline/offline_queue.dart:56-64
class OfflineQueue {
  static const String kunci = 'offline_queue_v1';
  final SharedPreferences _prefs;
  ...
  Future<void> _tulis(List<OfflineMutation> items) async {
    await _prefs.setString(kunci, jsonEncode(items.map((e) => e.toJson()).toList()));
  }
```
```dart
// lib/features/auth/presentation/providers/auth_provider.dart:132-143
Future<void> logout() async {
  _tokenRefreshSub?.cancel();
  _tokenRefreshSub = null;
  _clearUserCaches();
  state = AuthState.unauthenticated();
  try {
    await _ref.read(fcmTokenRepositoryProvider).deleteToken();
  } catch (_) {}
  await _repository.logout(); // Hanya menghapus FlutterSecureStorage (_storage.clearAll())
}
```

#### 2. Analisis Akar Masalah & Skenario Ancaman
- Pada gawai bersama di rumah sakit (misalnya tablet inventaris gudang yang dipakai bergantian antar-shift), staf A melakukan input perhitungan fisik opname atau laporan kerusakan saat koneksi internet terputus. Data masuk ke `OfflineQueue` yang disimpan di `SharedPreferences` (teks polos).
- Staf A melakukan `logout()`. Fungsi logout hanya membersihkan token di `FlutterSecureStorage` dan membatalkan provider memory, **namun membiarkan isi `OfflineQueue` di `SharedPreferences` tetap utuh**.
- Staf B (dengan akun berbeda) kemudian login pada gawai yang sama. Begitu perangkat mendapatkan koneksi internet, `OfflineSyncService.flush()` dieksekusi.
- Hasil hitungan atau mutasi yang dibuat oleh Staf A dikirim ke backend dengan header otentikasi milik Staf B.
- Dampak:
  1. **Keracunan Jejak Audit (Audit Trail Poisoning)**: Mutasi dan persetujuan data tercatat atas nama pengguna yang salah di log kepatuhan.
  2. **Pelanggaran Hak Akses**: Jika peran Staf B tidak memiliki otorisasi atas gudang/unit terkait, transaksi gagal atau menyebabkan inkonsistensi status.

#### 3. Rekomendasi Perbaikan
- Tambahkan atribut `userId` ke dalam model `OfflineMutation`.
- Saat memproses `flush()`, hanya kirim mutasi yang cocok dengan ID pengguna yang sedang aktif saat ini.
- Bersihkan mutasi tertunda milik pengguna sebelumnya atau berikan konfirmasi pembersihan saat pergantian akun dilakukan.
- Simpan antrean mutasi menggunakan penyimpanan aman terenkripsi.

---

### SEC-05: Deteksi Root Bersifat Advisory dan Mudah Dilewati

- **Tingkat Keparahan**: **Medium**
- **Kategori OWASP Mobile**: M8: Security Misconfiguration
- **CWE**: CWE-693 (Protection Mechanism Failure)
- **Komponen / Lokasi**:
  - `android/app/src/main/kotlin/com/simlogrs/simlog_mobile/MainActivity.kt` (baris 55–73)
  - `lib/features/auth/presentation/screens/login_screen.dart` (baris 73–140)

#### 1. Bukti Kode Sumber
```kotlin
// MainActivity.kt:55-73
private fun checkRootEnvironment(): Boolean {
    val rootPaths = arrayOf(
        "/system/app/Superuser.apk",
        "/sbin/su",
        "/system/bin/su",
        "/system/xbin/su",
        ...
    )
    for (path in rootPaths) {
        if (File(path).exists()) return true
    }
    val buildTags = Build.TAGS
    return buildTags != null && buildTags.contains("test-keys")
}
```
```dart
// login_screen.dart:126-135
ElevatedButton(
  onPressed: () => setState(() => _dismissRootWarning = true),
  style: ElevatedButton.styleFrom(...),
  child: const Text('Pahami & Lanjutkan'),
)
```

#### 2. Analisis Akar Masalah & Skenario Ancaman
- Deteksi lingkungan root di `MainActivity.kt` hanya memeriksa path file biner standar dan `Build.TAGS`. Framework root modern (seperti Magisk Zygisk, Shamiko, KernelSU, APatch) menyembunyikan file biner tersebut secara menyeluruh, sehingga metode pengecekan ini gagal mendeteksi keberadaan root.
- Pada antarmuka Flutter, peringatan root hanya bersifat himbauan (*advisory banner*). Tombol "Pahami & Lanjutkan" langsung mengubah state `_dismissRootWarning = true`, memungkinkan pengguna melanjutkan proses login pada perangkat yang tidak aman.
- Pada perangkat ter-root, data sesi sensitif pada `EncryptedSharedPreferences` dapat diinspeksi atau di-hook melalui Frida/Xposed.

#### 3. Rekomendasi Perbaikan
- Jika kebijakan keamanan rumah sakit mewajibkan integritas gawai (misalnya aplikasi digunakan untuk otorisasi pengadaan dan mutasi obat bernilai tinggi), gunakan Google Play Integrity API atau solusi verifikasi integritas perangkat keras native.
- Terapkan pemblokiran aktif (*fail-closed*) alih-alih banner yang dapat ditutup secara bebas.

---

### SEC-06: Navigasi Otomatis Payload Notifikasi Tanpa Verifikasi Otorisasi Peran

- **Tingkat Keparahan**: **Medium**
- **Kategori OWASP Mobile**: M6: Insecure Authorization
- **CWE**: CWE-862 (Missing Authorization)
- **Komponen / Lokasi**:
  - `lib/features/shell/presentation/screens/main_shell_screen.dart` (baris 228–302, `_bukaTujuan`)

#### 1. Bukti Kode Sumber
```dart
// main_shell_screen.dart:228-250
void _bukaTujuan(NotificationPayload payload) {
  if (!mounted) return;
  final user = ref.read(authStateProvider).user;
  final target = resolveTarget(payload);
  ...
  final id = int.tryParse(payload.referensiId ?? '');
  final Widget layar;
  switch (target) {
    case NotificationTarget.approvalPr:
      layar = const PengadaanHubScreen(initialTab: HubTab.pr);
      break;
    case NotificationTarget.approvalAmprah:
      layar = const AmprahHubScreen();
      break;
    ...
```

#### 2. Analisis Akar Masalah & Skenario Ancaman
- Handler `_bukaTujuan` menerima payload notifikasi dari FCM background, local notification tap, atau initial message, lalu langsung melakukan navigasi `Navigator.push` ke layar target tanpa memverifikasi apakah `user` memiliki izin atau peran yang relevan.
- Layar seperti `PengadaanHubScreen` atau modul approval tertentu mengasumsikan pengguna yang membuka halaman tersebut memiliki wewenang. Jika pengguna berhak akses rendah (misalnya `Petugas Unit`) menerima atau menyuntikkan payload bertipe `APPROVAL_PR`, antarmuka approval pengadaan akan terbuka di layar.
- Meskipun operasi API di backend menolak aksi jika otorisasi tidak valid, paparan antarmuka memungkinkan kebocoran alur bisnis internal dan memicu error status yang membingungkan pengguna.

#### 3. Rekomendasi Perbaikan
Lakukan pengecekan otorisasi peran pengguna sebelum menjalankan navigasi:
```dart
if (target == NotificationTarget.approvalPr && !(user?.canApprovePr ?? false)) {
  AppToast.error(context, 'Anda tidak memiliki wewenang untuk membuka persetujuan pengadaan.');
  return;
}
```

---

### SEC-07: Build Rilis Memiliki Fallback Otomatis ke Debug Keystore Publik

- **Tingkat Keparahan**: **Low**
- **Kategori OWASP Mobile**: M8: Security Misconfiguration
- **CWE**: CWE-296 (Improper Following of a Certificate's Chain of Trust)
- **Komponen / Lokasi**:
  - `android/app/build.gradle.kts` (baris 42–58)

#### 1. Bukti Kode Sumber
```kotlin
// android/app/build.gradle.kts:42-58
signingConfigs {
    create("release") {
        if (keystorePropertiesFile.exists()) {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "")
            storePassword = keystoreProperties.getProperty("storePassword")
        } else {
            // Fallback to debug keystore for development builds
            val debugSigning = signingConfigs.getByName("debug")
            keyAlias = debugSigning.keyAlias
            keyPassword = debugSigning.keyPassword
            storeFile = debugSigning.storeFile
            storePassword = debugSigning.storePassword
        }
    }
}
```

#### 2. Analisis Akar Masalah & Skenario Ancaman
- Apabila berkas `key.properties` tidak disiapkan di lingkungan CI/CD atau mesin build pengembang, build rilis Gradle tidak membatalkan proses dengan error, melainkan secara otomatis menandatangani APK rilis dengan `debug.keystore`.
- APK rilis yang ditandatangani dengan kunci debug publik rentan terhadap *re-packaging* dan penggantian tanda tangan oleh pihak ketiga tanpa terdeteksi oleh sistem verifikasi integritas standar Android.

#### 3. Rekomendasi Perbaikan
Ubah logika signing config agar melempar exception (*fail-closed*) saat build rilis dijalankan tanpa keystore produksi yang valid:
```kotlin
if (keystorePropertiesFile.exists()) {
    ...
} else {
    throw GradleException("Berkas konfigurasi keystore rilis (key.properties) tidak ditemukan. Build rilis dibatalkan demi keamanan.")
}
```

---

### SEC-08: Pembacaan Seluruh Berkas Lampiran ke Memori Heap Menimbulkan Risiko OOM

- **Tingkat Keparahan**: **Low**
- **Kategori OWASP Mobile**: M10: Insufficient Cryptography / Poor Code Quality
- **CWE**: CWE-400 (Uncontrolled Resource Consumption)
- **Komponen / Lokasi**:
  - `lib/features/audit/data/repositories/audit_repository.dart` (baris 264–267)
  - `lib/features/maintenance/data/repositories/maintenance_repository.dart` (baris 207, 255)

#### 1. Bukti Kode Sumber
```dart
// lib/features/audit/data/repositories/audit_repository.dart:264-267
final files = <MultipartFile>[];
for (final f in berkas) {
  files.add(MultipartFile.fromBytes(await f.readAsBytes(), filename: f.name));
}
final response = await _client.dio.post(
  '/audit/temuan-capa/$id/bukti',
  data: FormData.fromMap({'berkas[]': files}),
);
```

#### 2. Analisis Akar Masalah & Skenario Ancaman
- Setiap lampiran bukti temuan audit atau foto kerusakan dibaca sekaligus secara penuh ke memori heap Dart via `await f.readAsBytes()`.
- Jika staf memilih hingga 5 foto beresolusi tinggi langsung dari kamera resolusi 48MP/108MP (sekitar 10–25MB per foto), puluhan hingga ratusan megabyte alokasi memori raw bytes akan dimuat serentak ke dalam heap.
- Pada gawai Android kelas pemula (*low-end*) dengan batas heap proses ketat, hal ini memicu alokasi gagal dan crash mendadak aplikasi akibat *Out Of Memory* (OOM).

#### 3. Rekomendasi Perbaikan
Gunakan kompresi gambar sebelum transmisi atau gunakan `MultipartFile.fromFile` untuk melakukan streaming dari penyimpanan lokal:
```dart
MultipartFile.fromFile(f.path, filename: f.name)
```
Terapkan kompresi ukuran resolusi gambar sebelum berkas disiapkan untuk pengunggahan.
