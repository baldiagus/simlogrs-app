# Rencana Pencarian Rak dan Informasi Gudang pada Terima PO

Status: diimplementasikan dan lulus tes terfokus; build APK diperbarui untuk pemasangan. Interaksi langsung pada HP belum dikonfirmasi.
Tanggal: 13 November 2026.

Dokumen baru ini melanjutkan perbaikan alokasi rak tanpa mengganti `RENCANA_PERBAIKAN_ALOKASI_RAK_PO.md`, rencana katalog PR, atau pekerjaan di `tasks/`.

## 1. Tujuan

- Pengguna dapat mencari rak berdasarkan kode atau nama pada setiap item Terima PO.
- Pengguna melihat gudang pemilik rak saat memilih dan setelah rak terpilih.
- Pencarian tetap hanya mencakup rak aktif milik gudang penerima yang diizinkan.

Tidak mengubah penugasan akun, otorisasi, pemilihan gudang penerima, API penerimaan, harga, kuantitas, barang rusak, maupun penolakan vendor. Tidak menambah dependency atau kolom database.

## 2. Dasar dari implementasi saat ini

1. `lib/features/gudang/presentation/widgets/inbound_item_draft_tile.dart:264-284` menggunakan DropdownButtonFormField tanpa pencarian. Opsi hanya menampilkan kode dan nama rak.
2. `lib/features/gudang/data/models/rak_model.dart:3-11,29-49` sudah menyediakan id, kode, nama, gudangId, namaGudang, dan status. Informasi gudang tidak perlu diminta lewat API baru.
3. `lib/features/gudang/presentation/providers/gudang_provider.dart:25-43` sudah memuat daftar khusus penerimaan, terikat akun dan gudang penerima, lalu menyaring status AKTIF.
4. Endpoint `/gudang/rak` saat ini mengembalikan seluruh daftar yang sesuai scope, bukan satu halaman terpotong. Karena itu pencarian lokal dapat menjangkau seluruh opsi yang tersedia pada gudang tersebut.
5. Pola bottom sheet pencarian sudah dipakai proyek, misalnya `aset_picker_bottom_sheet.dart`, dengan AppSearchBar dan daftar pilihan.

## 3. Perilaku yang dipilih

### Membuka pemilih rak

- Pengguna mengetuk bidang Rak Simpan Gudang pada item penerimaan.
- Buka bottom sheet Pilih Rak Simpan dengan identitas gudang penerima yang tetap terlihat.
- Gunakan AppSearchBar yang sudah ada dengan petunjuk `Cari kode atau nama rak...`.
- Daftar pilihan hanya berasal dari konteks `rakPenerimaanProvider(gudangId)` yang berlaku. Jangan memakai provider denah rak umum atau memuat rak lintas gudang sebagai fallback.

Pola bottom sheet dipakai untuk memisahkan teks pencarian sementara dari nilai rak yang dipilih. Mengetik kata kunci tidak mengubah ID rak pada draft.

### Pencarian

- Cari sebagian teks pada kode atau nama rak, tidak peka huruf besar/kecil; trim spasi di awal/akhir.
- Berfungsi sejak satu huruf, termasuk dua/tiga huruf dan kode lengkap; tidak ada batas minimal tiga huruf.
- Filter secara lokal terhadap daftar scoped yang sudah dimuat. Tidak mengirim request baru setiap mengetik dan tidak menambah provider query global.
- Pakai perilaku debounce dan tombol hapus AppSearchBar yang sudah tersedia; tidak membuat timer pencarian kedua.
- Menghapus kata kunci menampilkan kembali seluruh opsi sah pada gudang yang sama.
- Kata kunci tidak boleh memperluas pencarian ke gudang lain atau mengubah gudang penerima.

### Informasi yang tampil

| Lokasi tampilan | Informasi |
|---|---|
| Header pemilih | Gudang Penerima: nama gudang saat ini |
| Setiap hasil | Baris utama kode dan nama rak; baris kedua Gudang: namaGudang |
| Bidang setelah memilih | Kode/nama rak terpilih dan nama gudangnya, bukan ID saja |

- Gunakan namaGudang dari data rak. Jika nama kosong atau `-`, gunakan nama gudang penerima hanya jika gudangId rak cocok dengan konteks tersebut; jangan menebak dari awalan kode rak.
- Nama panjang harus tetap bisa dibaca lewat baris informasi terpisah/wrapping yang wajar tanpa overflow pada lebar 320 px.
- Rak yang sedang dipilih dapat diberi indikator pilihan pada daftar, tanpa pemilihan otomatis hasil pertama.

### Memilih, membatalkan, dan berganti konteks

- Hanya ketukan pada hasil yang sah yang mengubah lokasiGudangId untuk item yang membuka pemilih.
- Menutup sheet dengan tombol tutup, kembali, atau gesture tidak mengubah pilihan sebelumnya.
- Pencarian merupakan state lokal sheet; dibuka kembali dengan query kosong, sedangkan rak terpilih tetap ditampilkan.
- Pilihan setiap item PO independen. Memilih rak untuk item A tidak mengganti item B.
- Pertahankan perilaku sebelumnya: pergantian gudang/akun mengosongkan pilihan rak, tetapi tidak menghapus kuantitas, batch, tanggal, surat jalan, atau catatan.
- Saat sheet terbuka, pergantian akun/gudang atau refresh opsi tidak boleh menyebabkan hasil dari konteks lama diterapkan. Setelah sheet selesai, periksa kembali mounted, identitas konteks, target aktif, serta keanggotaan/status rak pada opsi terbaru. Jika tidak lagi sah, abaikan hasil dan minta pengguna memilih ulang.
- Validasi backend tetap menjadi kontrol terakhir; fitur ini tidak mengirim penerimaan secara otomatis.

### Loading, error, dan kosong

- Gudang belum ditentukan/tidak sah: pemilih rak tidak dapat dibuka; alasan yang sudah ada tetap ditampilkan.
- Opsi rak loading/error: tampilkan status dan retry yang sudah ada, bukan Rak Tidak Ditemukan.
- Gudang memang tidak mempunyai rak aktif: tampilkan Tidak ada rak aktif di gudang penerima.
- Daftar tersedia tetapi query tidak cocok: tampilkan Rak Tidak Ditemukan dan saran menghapus/mengganti kata kunci.
- Pilihan yang menjadi nonaktif/berpindah gudang tidak boleh tetap dianggap sah hanya karena masih tersimpan di draft.

## 4. Urutan implementasi

### Task 1 — Pemilih rak yang dapat dicari dan berlabel gudang

Dependensi: tidak ada. Ukuran: M.

Berkas rencana:
- Baru: `lib/features/gudang/presentation/widgets/rak_picker_bottom_sheet.dart`.
- Ubah: `lib/features/gudang/presentation/widgets/inbound_item_draft_tile.dart`.
- Baru: `test/features/gudang/rak_picker_bottom_sheet_test.dart`.

Checklist:
- [x] Buat pemilih khusus rak memakai showModalBottomSheet, AppSearchBar, dan daftar standar proyek; tidak membuat framework pencarian generik.
- [x] Tambahkan pencarian lokal kode/nama, indikator pilihan, informasi gudang pada hasil, dan empty state yang dibedakan dari kegagalan data.
- [x] Ganti bidang dropdown lama dengan pemicu pemilih dan ringkasan rak/gudang terpilih. Pertahankan heading, kuantitas, batch, tanggal, dan posisi bagian lain.
- [x] Uji query 1/2/3 huruf, huruf campuran, kode, spasi tepi, hasil kosong, clear, dan batal tanpa mengubah pilihan.

Acceptance: pengguna menemukan rak yang cocok dan mengenali gudangnya; pencarian tidak memanggil API per pengetikan dan tidak memilih hasil secara otomatis.

### Task 2 — Integrasi aman dengan draft dan konteks penerimaan

Dependensi: Task 1. Ukuran: M.

Berkas rencana:
- `lib/features/gudang/presentation/screens/form_penerimaan_po_screen.dart` bila diperlukan untuk callback/context guard.
- `lib/features/gudang/presentation/widgets/inbound_item_draft_tile.dart`.
- `test/features/gudang/penerimaan_rak_scope_test.dart`.
- `test/features/gudang/form_penerimaan_po_test.dart`.

Checklist:
- [x] Terapkan hasil pemilih hanya ke item pembuka dan hanya bila konteks akun/gudang serta rak masih valid.
- [x] Pastikan pergantian target/akun dan pemuatan ulang setelah 422 tetap menolak pilihan stale, termasuk jika perubahan terjadi ketika sheet terbuka.
- [x] Pertahankan input lain pada draft dan independensi pilihan antar item.
- [x] Migrasikan tes interaksi dropdown lama menjadi membuka pemilih, mengetik, memilih, atau membatalkan; jangan mempertahankan assertion yang hanya bergantung pada jenis widget lama.

Acceptance: rak lintas gudang/nonaktif tidak dapat dipilih, hasil sheet lama tidak menimpa konteks baru, dan simpan tetap diblokir untuk pilihan yang tidak sah.

### Task 3 — Verifikasi dan dokumentasi

Dependensi: Task 2. Ukuran: S.

- [x] Jalankan tes widget baru, tes form/scope yang terdampak, dan regresi data/payload penerimaan yang sudah ada.
- [x] Periksa tampilan pada lebar 320 px, keyboard terbuka, nama rak/gudang panjang, dan daftar yang perlu discroll.
- [ ] Build dan pasang APK debug ke HP dengan konfigurasi koneksi yang sudah terverifikasi.
- [ ] Pada HP, cari rak yang benar-benar tersedia, lihat nama gudangnya, pilih/batalkan, serta periksa dua item berbeda tanpa menyimpan penerimaan operasional.
- [ ] Catat hasil aktual pada dokumen ini; jangan menyamakan tes widget dengan konfirmasi interaksi di HP.

Perintah verifikasi yang direncanakan, setelah berkas baru dibuat:

```sh
flutter test --no-pub test/features/gudang/rak_picker_bottom_sheet_test.dart test/features/gudang/penerimaan_rak_scope_test.dart test/features/gudang/form_penerimaan_po_test.dart test/features/gudang/penerimaan_rak_data_test.dart
```

## 5. Hasil implementasi dan verifikasi

Implementasi selesai pada mobile tanpa perubahan backend, payload, model, atau skema:

- `lib/features/gudang/presentation/widgets/rak_picker_bottom_sheet.dart` (baru): bottom sheet pencarian lokal kode/nama, header/nama gudang, indikator rak terpilih, status loading/error/empty terpisah, serta memvalidasi ulang opsi scoped saat memilih.
- `lib/features/gudang/presentation/widgets/inbound_item_draft_tile.dart`: dropdown rak diganti pemicu pemilih dengan ringkasan kode/nama rak dan nama gudang.
- `lib/features/gudang/presentation/screens/form_penerimaan_po_screen.dart`: `_pickRak` menangkap konteks akun/gudang, menaikkan generasi konteks saat pilihan rak direset, dan menolak hasil sheet yang basi.

Hasil pengujian terfokus: **46 tes lulus** pada empat berkas (picker, scope form, form penerimaan, dan data/payload penerimaan). Dua kegagalan tes awal berasal dari harness, bukan produksi: debounce 300 ms `AppSearchBar` belum dimajukan, teks error Riverpod terbungkus `ApiException(...)`, dan scroll menyasar `Scrollable` milik kolom pencarian. Setelah diperbaiki, seluruh tes hijau. Bukan klaim bahwa seluruh suite proyek dijalankan.

Tambahan implementasi: daftar pilihan dibungkus `Material` transparan agar `ListTile` dapat menggambar ripple/selection di dalam sheet berwarna (memperbaiki assertion framework).

APK debug dibangun dengan `dart_defines/wifi.json` + `API_BASE_URL=http://127.0.0.1:8000/api/v1`, dipasang (`adb install -r -d`) dan diluncurkan pada 2412DPC0AG. Tunnel `adb reverse tcp:8000 tcp:8000` aktif.

Belum dikonfirmasi: interaksi manual pada HP (mencari rak nyata, melihat nama gudang, memilih/membatalkan, dua item berbeda). Izin input ADB perangkat membatasi tap otomatis, dan tidak ada penerimaan barang operasional yang dilakukan.

## 6. Risiko dan batas pekerjaan

- Pencarian lokal cocok karena API saat ini sudah memuat semua rak dalam satu gudang. Jika kelak endpoint dipaginasi, strategi pencarian harus ikut diubah; jangan hanya mencari pada halaman pertama.
- Bottom sheet tidak boleh memegang snapshot lama sebagai otorisasi memilih. Opsi terbaru dan konteks saat hasil diterapkan harus diperiksa kembali.
- Informasi gudang bersifat penjelas lokasi, bukan hak untuk menerima ke gudang lain.
- Tidak ada perubahan backend, payload, model, atau skema yang diperlukan untuk fitur ini. Bila implementasi menemukan data nama gudang hilang, telusuri kontrak yang ada sebelum menambah endpoint.
- Implementasi ini tidak mencatat penerimaan barang operasional, tidak mengubah backend, dan belum di-commit/push.
