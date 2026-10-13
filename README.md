# simlog_mobile

Klien SIMLOG RS (Sistem Informasi Manajemen Logistik Rumah Sakit v2) berbasis Flutter. Target platform: **web (Chrome)** dan **Android (APK)**.

## Menjalankan (web)

```sh
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## Build (web)

```sh
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Variabel konfigurasi (`API_BASE_URL`, `CONNECT_TIMEOUT`, `RECEIVE_TIMEOUT`) diberikan lewat `--dart-define`. Lihat `.env.example` untuk daftar kunci dan nilai contoh.

## Build APK

Syarat:

- Android SDK terpasang dan lisensinya diterima: `flutter doctor --android-licenses`.
- Pastikan `flutter doctor` tidak melaporkan masalah pada toolchain Android.

APK debug:

```sh
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
```

Emulator Android: bila `API_BASE_URL` kosong, aplikasi otomatis memakai `10.0.2.2` (alias host mesin pengembang dari emulator), sehingga `--dart-define=API_BASE_URL` boleh dihilangkan.

APK rilis:

```sh
flutter build apk --release --dart-define=API_BASE_URL=https://simlog.example.com/api/v1
```

Opsi lain: `flutter build apk --split-per-abi` untuk APK per arsitektur, atau `flutter build appbundle` untuk Play Store.

Tanda tangan rilis:

1. Salin `android/key.properties.example` ke `android/key.properties`, lalu isi nilainya.
2. File `android/key.properties` tidak boleh di-commit.
3. Tanpa file tersebut, APK rilis ditandatangani dengan kunci debug (tidak layak untuk distribusi).

Catatan:

- Scanner QR membutuhkan izin kamera dan hanya berjalan di APK; di web dipakai input kode manual.
- URL server diatur saat build lewat `--dart-define`; tidak ada file `.env` yang dibundel ke APK.

## Dokumentasi

Semua dokumen proyek ada di folder [`docs/`](./docs):

- [`docs/prd.md`](./docs/prd.md): kebutuhan produk
- [`docs/desain.md`](./docs/desain.md): panduan desain
- [`docs/prompt.md`](./docs/prompt.md): prompt kerja
- [`docs/FLUTTER_CODE_RULES.md`](./docs/FLUTTER_CODE_RULES.md): aturan kode Flutter
- [`docs/REFACTORING_PLAN.md`](./docs/REFACTORING_PLAN.md): rencana refactoring
- [`docs/uat-mobile.md`](./docs/uat-mobile.md): skenario UAT per peran
