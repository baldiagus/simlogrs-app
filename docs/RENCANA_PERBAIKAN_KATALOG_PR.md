# Rencana Perbaikan Katalog Tambah Barang pada Pengajuan PR

Status: implementasi backend/mobile dan tes terfokus selesai; APK debug terpasang. Verifikasi interaksi langsung pada HP belum dikonfirmasi pengguna.
Tanggal pemeriksaan: 13 November 2026.

Repositori terkait:
- Mobile: `simlogrs-app`.
- Backend lokal: `../simlog-fix2`.

Dokumen ini juga menjadi checklist pekerjaan untuk perbaikan ini. `tasks/plan.md` dan `tasks/todo.md` milik pekerjaan lain tidak diubah.

## 1. Keluhan dan batas pekerjaan

1. Sebagian barang/aset tidak tersedia di daftar Tambah Barang pada Pengajuan PR Baru.
2. Pencarian setelah huruf ketiga menampilkan Barang Tidak Ditemukan.

Tujuan: seluruh master barang aktif yang sah untuk PR dapat dijangkau, dan pencarian nama/kode bekerja tanpa bergantung pada kapitalisasi maupun panjang tiga huruf.

Tidak mengubah desain/layout, role/permission, persetujuan PR, harga, anggaran, data master, atau alur pengiriman PR. Perubahan UI hanya perilaku daftar berhalaman, status pemuatan/error, serta koreksi petunjuk pencarian agar sesuai kemampuan API.

## 2. Temuan berbasis sumber dan database

### A. Daftar dipotong pada 50 item tanpa halaman berikutnya

`../simlog-fix2/app/Http/Controllers/Api/V1/Pengadaan/PengadaanKatalogApiController.php:25-36` memakai `status = AKTIF`, kemudian `limit(50)->get()` tanpa pengurutan eksplisit atau metadata paginasi.

Pemeriksaan database lokal dilakukan dengan transaksi READ ONLY:

| Tipe | Master aktif | Termuat pada query awal LIMIT 50 saat pemeriksaan |
|---|---:|---:|
| HABIS_PAKAI | 30 | 29 |
| SPAREPART | 30 | 21 |
| ASET | 29 | 0 |
| Total | 89 | 50 |

Artinya, 39 master aktif tidak masuk daftar awal; pada hasil yang diperiksa seluruh master ASET tidak masuk. Komposisi hasil LIMIT tanpa ORDER BY tidak dijamin tetap.

Mobile memuat daftar sekali melalui `PengadaanRepository.getKatalogBarang()` dan menampilkan seluruh respons itu dalam `ListView.separated`. Tidak ada pemuatan halaman berikutnya.

Rujukan:
- `lib/features/pengadaan/data/repositories/pengadaan_repository.dart:15-38`.
- `lib/features/pengadaan/presentation/providers/pengadaan_provider.dart:18-43`.
- `lib/features/pengadaan/presentation/widgets/barang_picker_bottom_sheet.dart:100-127`.

### B. Pencarian peka kapitalisasi

Backend memakai `LIKE` pada PostgreSQL untuk kolom `nama` dan `kode` (`PengadaanKatalogApiController.php:29-33`). Ini berbeda dari `ILIKE` yang tidak peka kapitalisasi.

Probe SQL konstanta menghasilkan:
- `'Masker Bedah' LIKE '%mas%'`: false.
- `'Masker Bedah' ILIKE '%mas%'`: true.

Pada database lokal, 56 dari 89 master aktif menghasilkan nol kecocokan ketika tiga huruf awal namanya diubah ke huruf kecil dan dipakai dalam kondisi LIKE nama/kode yang sekarang. Probe ini mendukung penyebab kapitalisasi; belum merekam kata kunci persis yang diketik pengguna, sehingga bukan bukti bahwa semua kata kunci tiga huruf pasti gagal.

Tidak ditemukan aturan minimal tiga huruf pada jalur ini. `AppSearchBar` memakai debounce 300 ms, picker menyimpan `v.trim()`, dan provider meneruskan query ke server. Jangan memperbaikinya dengan menunda pencarian sampai empat huruf atau mematikan debounce.

Rujukan:
- `lib/shared/widgets/app_search_bar.dart:60-76`.
- `lib/features/pengadaan/presentation/widgets/barang_picker_bottom_sheet.dart:84-91`.
- `lib/features/pengadaan/presentation/providers/pengadaan_provider.dart:38-43`.

### C. Ini endpoint berbeda dari perbaikan katalog sebelumnya

Pengajuan PR menggunakan `GET /api/v1/master/barang`, bukan `/api/v1/master/barang-lengkap`. Perbaikan kolom `spesifikasi` pada endpoint barang-lengkap tidak memperbaiki pencarian PR.

Petunjuk picker saat ini menjanjikan pencarian spesifikasi, tetapi endpoint PR hanya mencari nama dan kode. Tidak perlu membuat kolom database baru; petunjuk diselaraskan menjadi pencarian nama barang atau kode SKU.

### D. Pembatasan yang memang harus dipertahankan

- Hanya master berstatus AKTIF yang ditawarkan. Ada dua master NONAKTIF pada database lokal; keduanya bukan item yang perlu dimunculkan otomatis.
- PR memilih master komoditas bertipe ASET, bukan unit aset fisik dengan nomor seri/kode AST. Jangan memasukkan isi register aset sebagai master baru.
- Form PR membuka picker tanpa filter tipe, sehingga HABIS_PAKAI, ASET, dan SPAREPART aktif harus dapat dijangkau.
- Picker juga dipakai `SparepartPickerSheet` pada maintenance dengan `filterTipe: SPAREPART`.
- Pada PR, stok nol bukan alasan menolak pemilihan barang. Pada picker khusus maintenance, aturan penolakan sparepart stok nol tetap dipertahankan.

## 3. Keputusan perbaikan

1. Ganti LIKE menjadi ILIKE pada nama/kode, tetap memakai parameter binding dan pengelompokan kondisi OR di dalam filter status/tipe.
2. Ganti batas total 50 item dengan paginasi server: 50 item per halaman secara default, batas maksimum 100, urutan stabil `nama ASC, id ASC`.
3. Terapkan filter dan pencarian sebelum paginasi. Pencarian harus menjangkau seluruh master aktif, bukan hanya 50 item yang sudah ada di HP.
4. Gunakan pola respons berhalaman yang sudah ada pada modul audit: `data.items` dan `data.paginasi` dengan `total`, `per_halaman`, `halaman_ini`, dan `total_halaman`. Field setiap item tetap sama.
5. Gunakan kembali `PagedResponse`, `PaginationMeta`, `PagedListState`, dan `AppPagedListView`; tidak membuat framework katalog/paginasi baru atau menambah dependency.
6. State daftar dipisahkan menurut pasangan query dan tipe. Query/tipe berubah atau pencarian dihapus berarti kembali ke halaman pertama, bukan mencampurkan hasil lama.
7. Bedakan hasil kosong yang sah dengan request gagal atau format respons tidak valid. Error tidak boleh diterjemahkan menjadi daftar kosong.

Kontrak input yang direncanakan:
- `cari`: string opsional, trim spasi tepi, maksimum 255 karakter; tidak ada batas minimal tiga huruf.
- `tipe`: opsional, hanya HABIS_PAKAI, ASET, atau SPAREPART.
- `page`: integer minimal 1, default 1.
- `per_halaman`: integer 1–100, default 50.

Perubahan `data` dari list menjadi objek berhalaman merupakan perubahan kontrak. Backend dan seluruh pemakai mobile harus diperbarui sebagai satu cutover. Jangan menerapkan backend baru sendirian pada lingkungan yang masih melayani klien lama. Sebelum implementasi, pastikan tidak ada konsumen di luar dua jalur mobile yang telah teridentifikasi; bila ada, tentukan strategi rilisnya terlebih dahulu, bukan menambahkan fallback diam-diam.

## 4. Urutan pekerjaan dan acceptance criteria

### Task 1 — Perbaiki pencarian nama/kode

Dependensi: tidak ada. Ukuran: S.

Berkas rencana:
- Backend `app/Http/Controllers/Api/V1/Pengadaan/PengadaanKatalogApiController.php`.
- Backend test baru `tests/Feature/Pengadaan/PengadaanKatalogApiTest.php`.

Checklist:
- [x] Tambahkan regresi API berdasarkan nama/kode master uji yang benar-benar ada; variasi huruf kecil, besar, campuran, serta prefix 1/2/3 huruf dan nama lengkap.
- [x] Gunakan ILIKE untuk nama/kode; normalisasi spasi tepi dan pertahankan filter AKTIF/tipe.
- [x] Pastikan kata kunci tanpa kecocokan menghasilkan HTTP 200 dengan hasil kosong, bukan HTTP 500.

Acceptance: kapitalisasi berbeda untuk kata kunci yang sama menghasilkan ID yang sama; prefix tiga huruf tetap menemukan item yang cocok; filter tipe/status tidak bocor akibat OR.

### Task 2 — Lengkapi jalur katalog berhalaman dari API ke picker

Dependensi: Task 1 dan pemeriksaan konsumen kontrak. Ukuran: M, lima berkas produksi; tes diperbarui bersama perubahannya.

Berkas produksi rencana:
- Backend `app/Http/Controllers/Api/V1/Pengadaan/PengadaanKatalogApiController.php`.
- Mobile `lib/features/pengadaan/data/repositories/pengadaan_repository.dart`.
- Mobile `lib/features/pengadaan/presentation/providers/pengadaan_provider.dart`.
- Mobile `lib/features/pengadaan/presentation/widgets/barang_picker_bottom_sheet.dart`.
- Dokumentasi kontrak API yang sudah dipakai proyek.

Checklist:
- [x] Validasi parameter, tambahkan urutan stabil, paginasi dan metadata; hilangkan pemotongan total pada 50 item.
- [x] Repository mengirim halaman/query/tipe dan membaca PagedResponse; respons tidak valid menghasilkan error terkontrol.
- [x] Provider mengakumulasi halaman tanpa duplikasi ID dan tanpa dua pemuatan halaman yang sama secara bersamaan; pergantian query/tipe mereset hasil.
- [x] Picker memuat halaman berikutnya saat scroll memakai komponen yang ada. Pertahankan tampilan baris, pemilihan barang, dan keranjang PR.
- [x] Pertahankan debounce 300 ms; koreksi hint menjadi pencarian nama/kode SKU.

Acceptance: seluruh fixture aktif dapat dijangkau lewat scroll; item yang berada setelah item ke-50 juga dapat ditemukan langsung lewat search; query lama yang selesai belakangan tidak mengganti hasil query terbaru; gagal memuat halaman lanjutan tidak menghapus halaman yang sudah tampil.

### Checkpoint A — Kontrak dan regresi bersama

- [x] Backend dan mobile sepakat pada nama parameter serta struktur data.items/data.paginasi.
- [x] Semua pemakai getKatalogBarang dan BarangPickerBottomSheet sudah dimigrasikan, termasuk maintenance. Penelusuran konsumen backend tidak menemukan pemakai runtime tambahan.
- [x] Tidak ada fallback format respons lama atau perubahan schema/data master.

### Task 3 — Uji dua gejala dan dampak picker bersama

Dependensi: Task 2. Ukuran: M, berkas tes dan dokumentasi.

Berkas rencana:
- Backend `tests/Feature/Pengadaan/PengadaanKatalogApiTest.php`.
- Mobile `test/features/pengadaan/pengadaan_repository_test.dart`.
- Mobile test provider/picker katalog baru di `test/features/pengadaan/`.
- Mobile `test/features/maintenance/lembar_kerja_stok_limit_test.dart` bila assertion kontraknya terdampak.

Checklist:
- [x] Gunakan minimal 61 master fixture aktif dengan prefix unik untuk isolasi; letakkan master ASET di halaman lanjutan menurut urutan nama, dan sediakan fixture NONAKTIF.
- [x] Buktikan seluruh fixture aktif muncul pada gabungan halaman tanpa duplikasi; item NONAKTIF tidak muncul; pencarian dan metadata total mengikuti query/filter.
- [x] Uji mengetik cepat, jeda setelah huruf ketiga, menghapus query, dan respons lama yang datang terlambat.
- [x] Uji PR dapat memilih master ASET dan barang stok nol serta menambahkannya ke keranjang tanpa mengirim PR nyata.
- [x] Uji maintenance tetap hanya menawarkan SPAREPART dan tidak mengizinkan pemilihan stok nol.
- [x] Uji loading/error/empty dibedakan; retry halaman yang gagal tidak kehilangan pilihan keranjang.

## 5. Perintah verifikasi saat implementasi

Hasil eksekusi: 7 tes backend lulus (159 assertion) pada database terisolasi; 40 tes mobile terfokus lulus. Bukan klaim bahwa seluruh suite proyek dijalankan.

Backend, pada database terisolasi `simlog_rs_test`, memakai transaksi yang di-rollback dan tidak menjalankan migrate:fresh pada database aplikasi:

```sh
docker exec simrslogv2-app sh .phptest.sh php artisan test --compact tests/Feature/Pengadaan/PengadaanKatalogApiTest.php
```

Mobile, memakai dependency lokal yang sudah tersedia:

```sh
flutter test --no-pub test/features/pengadaan/pengadaan_repository_test.dart test/features/pengadaan/katalog_barang_provider_test.dart test/features/pengadaan/barang_picker_bottom_sheet_test.dart test/features/maintenance/lembar_kerja_stok_limit_test.dart
```

Tes repository dan maintenance lulus pada pemeriksaan gabungan awal. Sesudah memperbaiki batas judul picker pada lebar sempit, debounce saat sheet ditutup, serta selector/teardown tes, pemeriksaan ulang dua berkas provider/picker lulus 17 tes. Semua nama berkas di atas kini tersedia. Tidak ada pengujian yang mengirim PR operasional.

### Checkpoint B — Verifikasi pada HP

- [x] Jalankan build mobile yang memakai kontrak baru dan backend yang sama melalui koneksi USB yang sudah diverifikasi.
- [ ] Buka Pengajuan PR Baru → Tambah Barang. Scroll sampai master ASET yang sebelumnya hilang terlihat dan dapat dipilih.
- [ ] Cari nama/kode item yang sama dengan 1, 2, 3 huruf dan kata lengkap; bandingkan huruf kecil/besar.
- [ ] Cari item yang tidak berada pada halaman pertama tanpa harus scroll terlebih dahulu.
- [ ] Hapus pencarian: daftar awal kembali dan halaman lanjut tetap dapat dimuat.
- [ ] Cek picker sparepart maintenance serta aturan stoknya.
- [ ] Catat status API, query, hasil, dan bukti layar tanpa merekam token atau mengirim PR operasional.

APK `app-debug.apk` berhasil dibangun, dipasang, dan diluncurkan pada 2412DPC0AG. Jalankan dengan `--dart-define-from-file=dart_defines/wifi.json --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1` setelah `adb reverse tcp:8000 tcp:8000`. Izin input ADB HP membatasi tap otomatis; formulir verifikasi pengguna dikembalikan tanpa hasil yang dicentang. Karena itu langkah layar di atas tetap belum terverifikasi, bukan dianggap lulus dari tes widget.

## 6. Risiko dan batas kesimpulan

- Hilangnya barang aktif dari daftar awal sudah dijelaskan oleh LIMIT 50 dan hasil database lokal. Filter NONAKTIF tetap disengaja.
- Pencarian ILIKE sudah diterapkan dan variasi prefix/kapitalisasi diverifikasi melalui API; kata kunci persis pengguna tetap perlu dicoba pada HP.
- Backend dan seluruh konsumen mobile lokal telah memakai kontrak baru. Rilis ke perangkat lain yang masih memakai APK lama perlu dikoordinasikan.
- Urutan stabil, deduplikasi, serta isolasi state per query/tipe telah diimplementasikan dan diuji.
- Eksekusi ini diotorisasi melalui permintaan pengguna setelah rencana dibuat. Tidak ada migrasi atau mutasi data bisnis; tidak ada PR nyata yang dikirim.
