# Rencana Pencarian Rekanan / Vendor pada Terbitkan PO

Status: diimplementasikan; tes terfokus dan analisis lulus, APK dipasang serta smoke check visual dilakukan pada HP melalui Wi-Fi. Ketukan/gesture fisik manual belum dikonfirmasi; interaksi HP memakai callback UI melalui debugger karena izin injeksi input ADB ditolak.
Tanggal: 14 November 2026.

Rencana dan checklist fitur ini disimpan dalam satu dokumen, mengikuti pola `docs/RENCANA_PENCARIAN_RAK_TERIMA_PO.md`. Tidak mengganti rencana atau checklist pekerjaan lain yang belum selesai di `tasks/`.

## 1. Tujuan dan batasan

Pada Hub Pengadaan & PO, pengguna dapat mencari dan memilih Rekanan / Vendor Pemasok di form Terbitkan Pesanan Pembelian tanpa menggulir dropdown panjang.

Asumsi yang dipilih untuk rencana:
- Pencarian berdasarkan sebagian **nama atau kode vendor**, tidak peka huruf besar/kecil dan mengabaikan spasi awal/akhir.
- Hanya vendor aktif dari daftar API yang tersedia yang dapat dipilih.
- Pencarian tidak menambah atau mengubah master vendor dan tidak menerbitkan PO otomatis.

Tidak mengubah hak akses, alur persetujuan PR, perhitungan harga/total, estimasi kirim, syarat bayar, catatan, maupun kontrak penerbitan PO. Tidak menambah dependency, endpoint, migrasi, pagination, atau state pencarian global.

## 2. Temuan kode sebagai dasar

| Bagian | Temuan |
|---|---|
| `lib/features/pengadaan/presentation/widgets/terbitkan_po_sheet.dart:200-220` | Pemilihan vendor masih memakai `DropdownButtonFormField<int>` tanpa pencarian; label menampilkan nama dan kode. |
| Form yang sama, baris 35 dan 81-138 | Pilihan disimpan sebagai `_selectedPemasokId`; submit meneruskan ID ini dan input draft ke `poActionProvider`. |
| `lib/features/pengadaan/presentation/providers/pengadaan_provider.dart:182-186` | `pemasokListProvider` sudah memuat daftar melalui repository; dapat dipakai kembali. |
| `lib/features/pengadaan/data/repositories/pengadaan_repository.dart:119-133,167-189` | Daftar berasal dari `GET /pengadaan/pemasok`; penerbitan mengirim `pemasok_id` ke `POST /pengadaan/po`. |
| `lib/features/pengadaan/data/models/po_model.dart:1-29` | `PemasokOptionModel` sudah menyediakan `id`, `nama`, dan `kode`; tidak perlu model pencarian baru. |
| Backend `../simlog-fix2/app/Http/Controllers/Api/V1/Pengadaan/PengadaanPoApiController.php:28-35` | Endpoint mengambil pemasok `AKTIF`, diurutkan berdasarkan nama, memakai `get()` tanpa limit/pagination. Pencarian lokal mencakup seluruh daftar yang dikembalikan. |
| `lib/shared/widgets/app_search_bar.dart:7-25,52-76` | `AppSearchBar` sudah memiliki debounce 300 ms, tombol hapus segera, dan pembatalan timer saat dispose. |
| `lib/features/gudang/presentation/widgets/rak_picker_bottom_sheet.dart:52-190` | Proyek sudah memakai pola bottom sheet + pencarian lokal + daftar pilihan + status loading/error/kosong. |

Referensi `TerbitkanPoSheet` diperiksa melalui LSP: form yang sama juga dibuka dari `pengadaan_hub_pr_tab.dart` dan `riwayat_pr_screen.dart`. Perbaikan dilakukan pada form bersama, bukan menambahkan implementasi pencarian berbeda di setiap pintu masuk.

Sumber dibaca langsung; temuan tidak hanya mengandalkan indeks simbol. Tidak menjalankan tes, build, atau transaksi PO pada tahap perencanaan ini.

## 3. Perilaku yang direncanakan

### Membuka dan mencari

1. Bidang **Rekanan / Vendor Pemasok** menjadi pemicu pemilih, dengan placeholder `Pilih vendor rekanan...` atau nama/kode vendor terpilih.
2. Ketukan membuka bottom sheet **Pilih Rekanan / Vendor** di atas form PO, bukan mengganti atau menutup form tersebut.
3. Gunakan `AppSearchBar` dengan petunjuk `Cari nama atau kode vendor...` dan daftar scroll standar proyek.
4. Kata kunci bekerja sejak satu karakter. Filter memakai pencocokan sebagian nama **atau** kode setelah normalisasi huruf dan spasi tepi.
5. Query kosong menampilkan seluruh daftar dalam urutan API. Tombol hapus mengembalikan seluruh daftar segera.
6. Pakai debounce bawaan 300 ms; tidak menambah timer kedua atau request HTTP setiap mengetik.
7. Setiap hasil menampilkan nama dan kode pada baris yang mudah dibaca. Identitas pilihan tetap berdasarkan ID, termasuk ketika nama vendor sama.

### Memilih, membatalkan, dan membuka kembali

- Hanya ketukan eksplisit pada hasil yang sah yang mengubah `_selectedPemasokId`; tidak memilih hasil pertama otomatis.
- Pemilih ditutup setelah vendor dipilih. Bidang form menampilkan nama dan kode pilihan tersebut.
- Tombol tutup, Back, atau gesture penutupan tidak mengubah pilihan sebelumnya dan tidak menutup form PO di bawahnya.
- Query bersifat lokal dan kembali kosong saat pemilih dibuka lagi; vendor terpilih tetap ditandai dengan ikon/label, bukan warna saja.
- Mengetik atau menghapus query tidak mengubah ID vendor yang sudah dipilih.
- Seluruh input form PO lain tetap utuh selama membuka, memilih, mengganti, atau membatalkan pemilih.

### Status data dan validitas pilihan

| Kondisi | Perilaku |
|---|---|
| Daftar sedang dimuat | Tampilkan indikator memuat, tanpa pilihan yang dapat diketuk. |
| API gagal | Tampilkan pesan gagal dan **Coba Lagi**, bukan pesan hasil pencarian kosong. Retry memuat ulang provider yang sama. |
| API berhasil tetapi daftar kosong | Tampilkan `Belum ada vendor aktif`. |
| Daftar tersedia tetapi tidak ada kecocokan | Tampilkan `Vendor tidak ditemukan` dan petunjuk mengganti/menghapus kata kunci. |
| Daftar diperbarui ketika pemilih terbuka | Render data terbaru; jangan menerapkan ID dari hasil yang sudah tidak tersedia. |
| Vendor terpilih hilang dari daftar terbaru | Jangan mengirim ID lama. Minta pilih ulang dan tahan submit sampai daftar berhasil dimuat serta pilihan sah. |

Form tetap mewajibkan vendor sebelum submit. Validasi terhadap daftar terbaru yang tersedia dilakukan saat menerima hasil pemilih dan sebelum mengirim PO. Validasi/otorisasi server yang sudah ada tetap berlaku; rencana ini tidak mengklaim pemeriksaan status vendor secara real-time jika status baru berubah di server tanpa daftar dimuat ulang.

### Tata letak dan aksesibilitas

- Ikuti `AppColors`, tipografi, dan pola sheet proyek; tidak mendesain ulang hub atau form PO.
- Tangani keyboard dan safe area; daftar tetap bisa digulir dan tombol tutup tetap terjangkau.
- Nama/kode panjang tidak overflow pada lebar 320 px maupun saat teks diperbesar.
- Pemicu dapat difokuskan/diaktifkan, tombol tutup memiliki tooltip, dan pilihan memiliki penanda yang dapat dikenali pembaca layar.
- Periksa `mounted` setelah menunggu hasil sheet; penutupan ketika debounce masih tertunda tidak memanggil `setState` pada widget yang sudah dibuang.

## 4. Rancangan teknis minimum

- Tambahkan widget khusus `PemasokPickerBottomSheet` di folder widget pengadaan. Tanggung jawabnya hanya pencarian dan pemilihan vendor.
- Widget memakai kembali `pemasokListProvider`, `PemasokOptionModel`, `AppSearchBar`, dan komponen status proyek. Jangan mengimpor pemilih rak untuk data vendor atau membuat framework picker generik.
- Gunakan `showModalBottomSheet<int>` / `Navigator.pop(context, pemasokId)`; pembatalan mengembalikan `null` dan mempertahankan pilihan lama.
- Pertahankan `_selectedPemasokId` sebagai sumber pilihan pada form. Nama/kode diturunkan dari opsi yang tersedia, bukan disimpan lagi sebagai state duplikat.
- Ganti dropdown vendor lama sepenuhnya. Dropdown syarat pembayaran dan kontrol lain tetap seperti semula.
- Pencarian lokal melakukan pemindaian daftar per query yang telah di-debounce; daftar dirender dengan `ListView.builder` atau `ListView.separated`. Tidak membuat indeks, cache, atau provider query baru.
- Repository, provider, model, serta backend tidak perlu diubah untuk perilaku pencarian ini. Ketergantungan pada respons daftar lengkap dicatat sebagai batas desain.

## 5. Urutan implementasi dan checklist

### Task 1 — Pemilih vendor yang dapat dicari

Dependensi: tidak ada. Ukuran: S, dua berkas baru.

Berkas:
- `lib/features/pengadaan/presentation/widgets/pemasok_picker_bottom_sheet.dart`.
- `test/features/pengadaan/pemasok_picker_bottom_sheet_test.dart`.

Checklist:
- [x] Implementasikan daftar dari provider yang ada, pencarian nama/kode, penanda pilihan, dan hasil ID saat memilih.
- [x] Bedakan loading, error/retry, daftar kosong, dan hasil pencarian kosong.
- [x] Tambahkan widget test untuk filter, clear, pilihan ID, batal, refresh daftar, dan tutup saat debounce tertunda.

Acceptance: pengguna menemukan vendor dengan nama/kode dan memilih ID yang benar; mengetik tidak menambah request API atau mengubah pilihan sendiri.
Verifikasi: jalankan tes pemilih pada perintah terfokus di bagian 7.

### Task 2 — Integrasi pada form Terbitkan PO

Dependensi: Task 1. Ukuran: M, dua sampai tiga berkas.

Berkas:
- `lib/features/pengadaan/presentation/widgets/terbitkan_po_sheet.dart`.
- Baru: `test/features/pengadaan/terbitkan_po_vendor_search_test.dart`.
- `test/features/pengadaan/terbitkan_po_default_price_test.dart` hanya bila interaksi tesnya perlu disesuaikan; pertahankan assertion harga/total yang relevan.

Checklist:
- [x] Ganti dropdown dengan pemicu sheet dan ringkasan nama/kode; terapkan hasil hanya saat form masih aktif dan ID tersedia pada daftar terbaru.
- [x] Pertahankan draft saat cari/pilih/batal; tolak submit tanpa vendor sah dan gunakan `pemasok_id` yang dipilih pada payload lama.
- [x] Uji alur dari form nyata memakai override provider/repository sesuai pola tes proyek, tanpa memanggil server atau membuat PO operasional.

Acceptance: ID hasil pencarian terkirim sebagai `pemasok_id`, pilihan lama tidak terkirim setelah tidak sah, dan harga/tanggal/syarat bayar/catatan tidak berubah karena interaksi pemilih.
Verifikasi: tes integrasi form dan tes harga default tetap lulus; smoke check pintu masuk Hub Pengadaan dan Riwayat PR.

### Task 3 — Verifikasi pada HP dan pembaruan UAT

Dependensi: Task 2. Ukuran: S.

Berkas dokumentasi:
- `docs/uat-mobile-05-pengadaan.md`.
- `docs/uat-mobile-01-superadmin.md`.

Checklist:
- [x] Jalankan tes terfokus dan analisis folder widget yang berubah, lalu jalankan aplikasi pada HP melalui Wi-Fi.
- [x] Periksa keyboard, penanda pilihan, pembatalan melalui handler Back, dan pemeliharaan draft pada HP melalui debugger. Scroll, nama panjang, teks diperbesar, dan layar kecil diuji lewat widget test; ketukan/gesture fisik manual belum dikonfirmasi.
- [x] Perbarui langkah UAT dari dropdown menjadi cari/pilih vendor serta catat hasil verifikasi dalam dokumen ini.

Acceptance: pencarian bekerja pada perangkat nyata tanpa overflow dan tanpa kehilangan draft; bukti penerbitan/payload berasal dari tes terisolasi, bukan membuat PO operasional tanpa persetujuan.

## 6. Kasus uji penting

| Skenario | Hasil yang harus terbukti |
|---|---|
| Query 1/2/3 karakter, potongan nama, kode, huruf campuran, spasi tepi | Vendor cocok muncul dan yang tidak cocok tidak muncul. |
| Vendor berada jauh di bawah daftar awal | Tetap ditemukan; filter tidak hanya berjalan pada item yang sedang terlihat. |
| Query tidak cocok lalu clear | Status tidak ditemukan tampil; clear memulihkan semua opsi sah. |
| Dua vendor bernama sama | Pemilihan mengikuti kode/ID hasil yang diketuk, bukan nama atau indeks hasil filter. |
| Vendor A terpilih, cari B lalu batal | Vendor A dan seluruh draft tetap tersimpan. |
| Ganti A menjadi B lalu submit dalam tes terisolasi | Payload berisi ID B, dengan harga, tanggal, syarat bayar, dan catatan yang sama dengan input pengguna. |
| Vendor terpilih hilang saat refresh | ID lama tidak diterima sebagai pilihan sah dan tidak dikirim. |
| Loading, kegagalan API, retry, daftar kosong | Masing-masing berbeda dari hasil pencarian kosong; retry benar-benar memuat data. |
| Tutup saat debounce aktif, buka kembali | Tidak ada callback pada widget disposed; query baru kosong dan pilihan tetap benar. |
| Lebar 320 px, teks panjang/diperbesar, keyboard terbuka | Daftar bisa digulir, nama/kode dapat dibaca, dan kontrol utama tidak overflow. |

Tes memakai provider/repository terisolasi mengikuti pola yang sudah ada. Hindari tes yang hanya memeriksa jenis widget atau teks judul tanpa membuktikan filter, pilihan, atau payload.

## 7. Perintah verifikasi saat implementasi

Perintah referensi dari root proyek. Hasil eksekusi aktual dicatat pada bagian 9. Pada terminal Windows gunakan `flutter.bat` bila launcher `flutter` dari shell tidak bekerja.

```powershell
C:\flutter\bin\flutter.bat test test/features/pengadaan/pemasok_picker_bottom_sheet_test.dart test/features/pengadaan/terbitkan_po_vendor_search_test.dart test/features/pengadaan/terbitkan_po_default_price_test.dart test/features/pengadaan/pengadaan_hub_screen_test.dart
C:\flutter\bin\flutter.bat analyze lib/features/pengadaan/presentation/widgets
C:\flutter\bin\flutter.bat devices
C:\flutter\bin\flutter.bat run -d DEVICE_ID --dart-define-from-file=dart_defines/wifi.json
```

Ganti `DEVICE_ID` dengan ID HP dari `flutter devices`. Pastikan IP API pada `wifi.json` masih sesuai jaringan saat pengujian. Perintah `run` sekaligus membangun dan memasang APK debug pada perangkat.

Untuk smoke check, gunakan PR yang memang boleh dilihat akun pengadaan, buka form, cari/pilih/batal tanpa menekan konfirmasi penerbitan PO. Jika ADB menolak injeksi input, lakukan interaksi fisik pada HP sambil mengamati hasil/log; jangan menonaktifkan keamanan perangkat sebagai jalan pintas.

Checkpoint selesai:
- [x] Seluruh perilaku pemilih dan integrasi draft/payload terbukti oleh tes terfokus.
- [x] Analisis bagian yang diubah lulus dan aplikasi berhasil berjalan pada HP.
- [x] Bukti visual pada HP diperiksa. Ini smoke check melalui debugger, bukan klaim bahwa UAT ketukan/gesture manual sudah selesai.
- [x] Tidak ada perubahan API, hak akses, dependency, atau transaksi PO operasional dari proses verifikasi.

## 8. Risiko dan batas desain

| Risiko | Mitigasi |
|---|---|
| Daftar vendor kelak sangat besar atau API berubah menjadi pagination | Saat ini backend mengirim daftar lengkap. Jika ukuran respons/latensi menjadi masalah terukur atau kontrak menjadi berhalaman, rencanakan pencarian server dan pagination; jangan menambahkannya sekarang. |
| Sheet pencarian menutup form induk atau mengubah draft | Gunakan hasil ID pada route pemilih saja; tes batal dan pelestarian seluruh input. |
| Respons terbaru menghapus vendor yang sudah dipilih | Periksa keanggotaan ID pada daftar terbaru sebelum menerima pilihan dan sebelum submit; tampilkan permintaan pilih ulang. |
| Pembaruan status vendor di server belum dimuat klien | Tidak menjanjikan status real-time; tangani kegagalan API penerbitan sesuai alur yang ada tanpa menghapus draft. |
| Fitur hanya bekerja pada satu pintu masuk | Ubah `TerbitkanPoSheet` bersama; periksa Hub Pengadaan dan Riwayat PR, tanpa menduplikasi pemilih. |

Referensi API Flutter: [showModalBottomSheet<T>](https://api.flutter.dev/flutter/material/showModalBottomSheet.html). Rencana telah disetujui untuk dieksekusi; hasil dan batas verifikasi dicatat berikut ini.

## 9. Hasil eksekusi

### Implementasi

- Ditambahkan `pemasok_picker_bottom_sheet.dart` dengan filter lokal nama/kode, debounce bawaan, status data yang terpisah, retry, dan penanda vendor terpilih.
- `TerbitkanPoSheet` menggunakan pemilih yang sama dari Hub Pengadaan maupun Riwayat PR. ID diperiksa terhadap daftar terbaru saat menerima pilihan dan sebelum submit.
- Tidak mengubah repository, model, provider, backend, dependency, atau kontrol form non-vendor.
- Dokumentasi UAT pengadaan dan super admin diperbarui tanpa menandai hasil UAT manual sebagai lulus.

### Tes dan analisis

Hasil terakhir per berkas pada eksekusi terfokus, tidak menghitung ulang tes yang dijalankan lebih dari sekali:

| Berkas | Hasil |
|---|---|
| `pemasok_picker_bottom_sheet_test.dart` | 6 tes lulus: filter/clear/ID, hasil di luar viewport awal, status/retry, refresh, batal/debounce, serta 320 px + keyboard + teks diperbesar. |
| `terbitkan_po_vendor_search_test.dart` | 3 tes lulus: integrasi pencarian; pelestarian draft dan payload penggantian vendor; blokir pilihan kosong/loading/error/hilang. |
| `terbitkan_po_default_price_test.dart` | 2 tes lulus. |
| `pengadaan_hub_screen_test.dart` | 10 tes lulus. |

Total: **21 tes unik lulus**. `flutter analyze --no-pub lib/features/pengadaan/presentation/widgets`: **No issues found**. Tidak menjalankan suite seluruh repositori.

Skenario awal form yang membuka pencarian terlebih dahulu terbukti gagal pada implementasi dropdown lama, lalu lulus setelah fitur dipasang. Kesalahan pada helper tes (tipe tanggal nullable, finder yang juga mencocokkan teks input, dan penantian layout sesudah scroll) diperbaiki tanpa menurunkan assertion perilaku.

Review terpisah terhadap standar proyek dan kesesuaian spesifikasi: tidak ditemukan defect blocking. Tidak menambah abstraksi atau refactor di luar fitur.

### Bukti perangkat Wi-Fi

- APK debug berhasil dibangun dan dipasang pada HP `2412DPC0AG` melalui ADB nirkabel, menggunakan `dart_defines/wifi.json`.
- Membuka PR yang tersedia pada akun aktif, lalu form Terbitkan PO dan pemilih vendor, tanpa menyetujui PR atau mengirim penerbitan PO.
- Daftar dari API tampil; callback pencarian kode `VND-2026-029` memfilter ke vendor yang sesuai. Keyboard asli Android dibuka melalui `EditableTextState.requestKeyboard`; header, kolom pencarian, dan hasil tetap terlihat.
- Memilih vendor memperbarui ringkasan nama/kode di form. Membuka kembali menampilkan ikon centang dan status aksesibilitas `selected=true`.
- Memanggil handler Back untuk membatalkan pemilih mempertahankan vendor, seluruh nilai input, tanggal kirim, dan syarat pembayaran pada form.
- Bukti visual diperiksa dari `%LOCALAPPDATA%/Temp/simlog-vendor-search/`: `vendor-picker.png`, `vendor-filter-keyboard.png`, `vendor-selected.png`, dan `vendor-form-after-cancel.png`.

**Batas verifikasi:** HP menolak `adb shell input tap` dengan izin `INJECT_EVENTS`. Tidak mengubah pengaturan keamanan perangkat. Interaksi di atas memakai callback UI aplikasi yang sudah ada melalui Flutter VM service; filter dipicu melalui `onChanged`, bukan ketikan fisik pada keyboard HP. Ketikan, clear, scroll, dan kasus layar kecil diuji melalui widget test. Gesture sentuh fisik dan sesi UAT manual penuh belum dikonfirmasi. Tidak ada kode instrumentasi/debug sementara yang ditambahkan ke aplikasi dan tidak ada PO operasional yang dibuat.
