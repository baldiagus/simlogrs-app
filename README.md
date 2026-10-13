# simlog_mobile

Klien SIMLOG RS (Sistem Informasi Manajemen Logistik Rumah Sakit v2) berbasis Flutter. Target platform: **web (Chrome)** saja.

## Menjalankan (web)

```sh
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## Build (web)

```sh
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Variabel konfigurasi (`API_BASE_URL`, `CONNECT_TIMEOUT`, `RECEIVE_TIMEOUT`) diberikan lewat `--dart-define`. Lihat `.env.example` untuk daftar kunci dan nilai contoh.

## Dokumentasi

Semua dokumen proyek ada di folder [`docs/`](./docs):

- [`docs/prd.md`](./docs/prd.md): kebutuhan produk
- [`docs/desain.md`](./docs/desain.md): panduan desain
- [`docs/prompt.md`](./docs/prompt.md): prompt kerja
- [`docs/FLUTTER_CODE_RULES.md`](./docs/FLUTTER_CODE_RULES.md): aturan kode Flutter
- [`docs/REFACTORING_PLAN.md`](./docs/REFACTORING_PLAN.md): rencana refactoring
- [`docs/uat-mobile.md`](./docs/uat-mobile.md): skenario UAT per peran
