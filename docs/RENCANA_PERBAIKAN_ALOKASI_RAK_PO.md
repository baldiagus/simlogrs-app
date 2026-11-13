# Rencana Perbaikan Alokasi Rak pada Terima PO

Status: implementasi dan tes terfokus selesai; APK debug terpasang di HP. Interaksi Terima PO langsung pada HP belum diverifikasi.
Tanggal: 13 November 2026.

Repositori: mobile `simlogrs-app` dan backend `../simlog-fix2`.
Dokumen ini menjadi checklist pekerjaan tersendiri. Rencana katalog PR dan berkas `tasks/` tidak ditimpa.

## 1. Tujuan dan batas perubahan

Menghilangkan pilihan rak yang tidak cocok dengan gudang penerima sebelum pengguna mengirim penerimaan, sekaligus mempertahankan penolakan server terhadap alokasi lintas gudang.

Invarian: satu dokumen penerimaan memiliki satu gudang penerima; setiap item yang diterima harus memakai rak aktif milik gudang tersebut. Beberapa rak berbeda dalam gudang yang sama tetap diperbolehkan.

Tidak mengubah desain umum halaman, approval PR/PO, status vendor, harga kontrak, perhitungan barang rusak, metode stok, ataupun permission pengguna. Tidak membuat migrasi, mengubah penugasan akun, memindahkan rak, atau menerima barang operasional pada tahap perencanaan.

## 2. Bukti sebelum implementasi

### Daftar rak dan gudang penerima belum menggunakan konteks yang sama

- `lib/features/gudang/presentation/screens/form_penerimaan_po_screen.dart:146` membaca `daftarRakProvider` umum.
- `lib/features/gudang/presentation/providers/gudang_provider.dart:17-20` hanya mengirim kata kunci, tanpa gudang_id.
- Repository sebenarnya sudah mendukung `getDaftarRak({cari, gudangId})` di `lib/features/gudang/data/repositories/gudang_repository.dart:15-22`.
- Backend `GudangTataLetakApiController.php:29-45` dapat mengembalikan rak lintas gudang bagi admin atau pemilik permission melihat master lokasi ketika gudang_id tidak diberikan. Pengguna lain dibatasi pada penugasan gudangnya.

### Rak dipilih otomatis tanpa pemeriksaan gudang

`lib/features/gudang/presentation/widgets/inbound_item_draft_tile.dart:249-255` mengisi draft dengan `raks.first.id` saat nilainya kosong, bahkan ketika pengguna belum memilih rak. Hal ini terjadi di dalam build.

Dropdown hanya menampilkan kode/nama rak. `RakModel` sudah memiliki gudangId, namaGudang, dan status; tidak perlu menambah schema/model untuk mengetahui asal rak.

### Backend menolak perbedaan gudang secara sengaja

`../simlog-fix2/app/Http/Controllers/Api/V1/Gudang/GudangPenerimaanPoApiController.php`:
- Baris 119-131: gudang penerima diambil dari penugasan akun. Admin tanpa penugasan dapat menggunakan input gudang_id, lalu fallback ke gudang rak pertama atau gudang aktif pertama.
- Baris 137-140 dan 395-410: rak dari gudang berbeda ditolak HTTP 422 dengan pesan Alokasi rak tidak valid.
- Pemeriksaan dilakukan sebelum transaksi pencatatan penerimaan/stok.

Payload mobile saat ini belum mengirim gudang_id: `GudangRepository.submitPenerimaanPo():95-102`.

Kesimpulan: ada jalur yang membolehkan pengguna melihat/memilih rak lebih luas daripada gudang yang digunakan saat menyimpan. Pesan tersebut bukan alasan untuk menghapus validasi backend.

Batas bukti: akun, kode PO, rak terpilih, dan gudang pada transaksi keluhan belum dipetakan secara spesifik. Penelusuran ini menetapkan jalur penyebab dari sumber, bukan mengklaim seluruh transaksi gagal dengan sebab yang sama.

## 3. Kebijakan gudang penerima yang dipakai rencana

Pilihan konservatif berikut mempertahankan prioritas penugasan akun pada backend saat ini:

| Kondisi akun | Gudang penerima | Perilaku form |
|---|---|---|
| Memiliki penugasan gudang, termasuk admin | Gudang penugasan akun | Tampilkan identitas gudang; tidak dapat diganti lewat form |
| Super admin/admin logistik tanpa penugasan | Satu gudang aktif yang dipilih secara eksplisit | Tampilkan pemilih gudang sebelum memuat rak |
| Pengguna non-global tanpa penugasan | Tidak tersedia | Blokir simpan dengan penjelasan penugasan gudang belum tersedia |

- Tidak menebak gudang dari tipe barang, urutan rak, atau gudang aktif pertama.
- Tidak mengasumsikan model PO saat ini sudah menentukan gudang tujuan; konteks yang dipakai API penerimaan saat ini adalah penugasan akun/input admin.
- Jika admin dengan penugasan ingin menerima lintas gudang, itu perubahan kebijakan terpisah yang membutuhkan keputusan pemilik proses, bukan bagian perbaikan ini.
- Admin tanpa penugasan tidak boleh mencampur rak beberapa gudang dalam satu dokumen penerimaan.

## 4. Desain perbaikan minimal

### Mobile

1. Tentukan gudang penerima sebelum memuat opsi rak, mengikuti tabel kebijakan.
2. Buat provider rak khusus penerimaan dengan key gudang_id dan dependensi sesi/akun. Gunakan kembali GudangRepository.getDaftarRak(gudangId: ...); jangan mengganti provider umum menjadi filter penerimaan karena dipakai denah rak, opname, dan modul lain.
3. Tampilkan hanya rak dengan gudangId yang cocok dan status AKTIF. Jangan memuat daftar seluruh rak sebagai fallback jika request scoped gagal.
4. Gunakan daftar gudang aktif yang sudah disediakan MasterRepository.getGudangList() untuk admin tanpa penugasan; jangan menambah repository/endpoint serupa.
5. Hapus pemilihan otomatis raks.first dan mutasi draft dalam build. Pengguna memilih rak secara eksplisit.
6. Ketika gudang penerima berubah, kosongkan pilihan rak seluruh draft, termasuk draft berkuantitas nol yang mungkin nanti diterima. Pertahankan jumlah, batch, tanggal, dan catatan pengguna.
7. Sebelum simpan, periksa rak terpilih masih berada dalam daftar aktif untuk konteks gudang terbaru. Gudang belum dipilih, opsi loading/error/kosong, atau pilihan lama yang sudah invalid harus memblokir simpan dengan pesan yang dapat ditindaklanjuti.
8. Teruskan gudang_id yang sama melalui form → InboundActionNotifier → GudangRepository.submitPenerimaanPo → payload API. Hanya item jumlahDiterima > 0 yang dikirim, sebagaimana sekarang.
9. Pada respons 422, pertahankan draft; tampilkan pesan spesifik dan segarkan opsi rak agar pengguna dapat memperbaiki pilihan. Jangan mengulang submit otomatis.

Perubahan UI hanya identitas/pemilih gudang sesuai peran, placeholder pemilihan rak, dan status empty/error/retry pada bagian alokasi. Layout tombol penerimaan, input kuantitas, serta bagian lain tidak didesain ulang.

### Backend

1. Validasi bentuk/nilai gudang_id yang dikirim dan pastikan gudang penerima aktif.
2. Jika akun mempunyai gudang penugasan, gunakan gudang tersebut; payload gudang berbeda harus ditolak sebagai pelanggaran scope, bukan mengalihkan stok atau diabaikan diam-diam.
3. Admin tanpa penugasan wajib mengirim gudang_id aktif yang dipilih secara eksplisit. Hapus fallback gudang dari rak pertama/gudang aktif pertama pada jalur API ini.
4. Pertahankan validasi keberadaan rak dan kecocokan setiap rak terhadap gudang penerima; tambahkan pemeriksaan status rak aktif saat submit agar perubahan setelah daftar dimuat tetap ditolak.
5. Pertahankan kode respons yang jelas: 403 untuk scope/penugasan yang tidak diizinkan; 422 untuk target/rak hilang, tidak aktif, atau tidak cocok. Pesan harus menunjuk gudang/rak yang perlu diperbaiki, tanpa stack trace.
6. Jalankan pemeriksaan sebelum penulisan penerimaan, stok batch, pergerakan stok, atau perubahan jumlah/status PO. Uji bahwa penolakan tidak menghasilkan perubahan parsial.

Endpoint /gudang/rak dan respons model rak tidak perlu diganti. Tampilan denah rak umum tetap boleh melihat rak sesuai hak aksesnya, termasuk konteks administrasi yang berbeda dari form penerimaan.

## 5. Urutan tugas

### Task 1 — Tegaskan kontrak dan regresi scope API

Dependensi: tidak ada. Ukuran: S/M.

Berkas rencana:
- Backend `app/Http/Controllers/Api/V1/Gudang/GudangPenerimaanPoApiController.php`.
- Backend test baru `tests/Feature/Pengadaan/GudangPenerimaanRakApiTest.php`.

Checklist:
- [x] Buat fixture dua gudang aktif, rak aktif masing-masing, rak nonaktif, dan akun dengan/tanpa penugasan.
- [x] Terapkan resolusi gudang serta validasi scope/status sesuai bagian 3–4.
- [x] Uji penerimaan valid pada gudang yang sesuai menghasilkan stok ke gudang dan rak yang benar.
- [x] Uji rak lintas gudang, rak nonaktif, gudang nonaktif, dan payload gudang berbeda ditolak tanpa perubahan penerimaan/stok/jumlah PO.
- [x] Uji admin tanpa penugasan harus memilih satu target eksplisit; non-global tanpa penugasan tetap tidak dapat menerima.

Acceptance: server tidak pernah menyimpan pasangan gudang_id/lokasi_gudang_id yang tidak cocok, dan penolakan tidak menghasilkan efek bisnis.

### Task 2 — Selaraskan jalur data mobile dan opsi rak

Dependensi: kontrak Task 1. Ukuran: M.

Berkas rencana:
- `lib/features/gudang/data/repositories/gudang_repository.dart`.
- `lib/features/gudang/presentation/providers/gudang_provider.dart`.
- `lib/features/gudang/presentation/providers/inbound_provider.dart`.
- Test repository/provider terfokus baru di `test/features/gudang/`.

Checklist:
- [x] Tambahkan provider scoped penerimaan tanpa mengubah perilaku daftarRakProvider umum.
- [x] Filter rak sesuai gudang dan status; pisahkan cache antar gudang/sesi dan abaikan hasil konteks lama.
- [x] Teruskan gudangId melalui submit penerimaan sampai payload gudang_id.
- [x] Uji filter request, payload target, perubahan konteks, dan error yang tidak dianggap daftar kosong.

Acceptance: gudang yang dipakai untuk mengambil opsi rak sama dengan gudang yang dikirim saat simpan; daftar dari gudang/sesi sebelumnya tidak terbawa.

### Task 3 — Perbaiki pilihan gudang/rak pada form

Dependensi: Task 2. Ukuran: M.

Berkas rencana:
- `lib/features/gudang/presentation/screens/form_penerimaan_po_screen.dart`.
- `lib/features/gudang/presentation/widgets/inbound_item_draft_tile.dart`.
- `test/features/gudang/form_penerimaan_po_test.dart`.
- Test scope/pilihan rak tambahan di `test/features/gudang/` bila diperlukan.

Checklist:
- [x] Tampilkan gudang penugasan atau pemilih gudang untuk admin tanpa penugasan, bukan daftar lintas gudang pada dropdown rak.
- [x] Hapus autopilih rak pertama; beri placeholder sampai pengguna memilih rak yang sah.
- [x] Reset hanya pilihan rak ketika target berubah; batch, jumlah dan catatan tetap utuh.
- [x] Blokir simpan saat konteks/opsi/pilihan belum valid dan tangani loading/error/empty/retry.
- [x] Pertahankan draft saat 422, lalu izinkan koreksi tanpa submit otomatis.
- [x] Perbarui fixture form lama agar memiliki penugasan gudang yang eksplisit; jangan mengganti perilaku aplikasi hanya supaya mock tanpa gudang tetap lulus.

Acceptance: pilihan salah dicegah sebelum submit, rak tidak terpilih diam-diam, dan judul/dropdown/tombol tetap terbaca pada layar sempit.

### Checkpoint — Integrasi dan regresi

- [x] Semua caller submit penerimaan telah meneruskan konteks gudang yang sama.
- [x] Denah rak umum, opname, dan penolakan kiriman vendor tidak diubah perilakunya; tes izin inbound, penolakan, dan model/widget gudang lulus.
- [x] Tes API, repository/provider, serta widget form lulus.
- [x] Uji beberapa item dengan rak berbeda di gudang yang sama, termasuk penerimaan parsial.
- [x] Tes web yang memang membolehkan rak nullable tidak diubah: keluhan ini tentang API/form mobile yang mewajibkan rak, bukan perubahan aturan web global.

## 6. Hasil verifikasi implementasi

37 tes backend lulus (121 assertion), mencakup regresi alokasi dan penolakan kiriman yang sudah ada. 37 tes mobile terfokus lulus: 7 tes data/payload/sesi dan 30 tes form, scope, izin inbound, penolakan, serta model/widget gudang. Bukan klaim bahwa seluruh suite proyek dijalankan.

Backend, hanya database test terisolasi dan transaksi rollback:

```sh
docker exec simrslogv2-app sh .phptest.sh php artisan test --compact tests/Feature/Pengadaan/GudangPenerimaanRakApiTest.php tests/Feature/Pengadaan/InboundTolakKirimanApiTest.php
```

Mobile memakai enam berkas berikut. Pemeriksaan dilakukan per irisan; dua berkas form/scope diuji ulang setelah memperbaiki selector tombol yang berada di luar viewport dan menunggu timer toast dalam teardown tes.

```sh
flutter test --no-pub test/features/gudang/penerimaan_rak_data_test.dart test/features/gudang/form_penerimaan_po_test.dart test/features/gudang/penerimaan_rak_scope_test.dart test/features/gudang/po_inbound_permission_test.dart test/features/gudang/inbound_rejection_test.dart test/features/gudang/gudang_test.dart
```

Jangan menjalankan migrate:fresh, mengganti penugasan akun produksi, atau mengirim penerimaan nyata sebagai cara mereproduksi masalah.

### Pemeriksaan di HP setelah implementasi

- [ ] Dengan akun berpenugasan, halaman menampilkan gudang yang benar dan hanya rak aktifnya.
- [ ] Dengan admin tanpa penugasan, daftar rak belum dimuat sebelum memilih target; pergantian target menghapus pilihan rak lama.
- [ ] Tidak ada rak terpilih otomatis; kondisi belum memilih/loading/error/kosong menjelaskan alasan simpan diblokir.
- [ ] Error 422 mempertahankan input pengguna dan memungkinkan koreksi.
- [ ] Uji penyimpanan hanya memakai fixture/lingkungan uji; tidak menerima stok bisnis nyata.
- [ ] Catat akun uji/peran, kode PO uji, gudang dan rak, status respons, serta bukti layar tanpa token/password.

Jika tap ADB masih dibatasi keamanan perangkat, langkah layar memerlukan interaksi pengguna. Hasil tes otomatis tidak boleh dilaporkan sebagai verifikasi langsung HP.

APK `app-debug.apk` berhasil dibangun, dipasang, dan diluncurkan pada 2412DPC0AG dengan `--dart-define-from-file=dart_defines/wifi.json --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1` melalui tunnel `adb reverse tcp:8000 tcp:8000`. Penilaian visual/perilaku form pada lebar 320 px sudah tercakup tes widget; langkah HP di atas tetap belum dicentang karena interaksi manual belum dikonfirmasi. Tidak ada penerimaan barang operasional yang dilakukan.

Implementasi backend memeriksa ulang gudang dan rak di dalam transaksi dengan shared row locks sebelum mencatat penerimaan, sehingga perubahan master di antara pemeriksaan awal dan penulisan ditolak. Transaksi pengujian memakai database terisolasi `simlog_rs_test` dan rollback.

## 7. Risiko pelaksanaan

- Perubahan syarat target eksplisit untuk admin tanpa penugasan membutuhkan pembaruan APK dan backend yang terkoordinasi; APK lama belum mengirim gudang_id.
- Rak dapat dinonaktifkan/dipindahkan setelah dropdown dimuat. Backend harus memeriksa ulang saat submit; UI bukan sumber otorisasi.
- Rencana mempertahankan penugasan akun sebagai pembatas, termasuk pada admin yang sudah berpenugasan. Kebutuhan menerima ke gudang lain tidak diselesaikan dengan bypass validasi.
- Penyebab transaksi spesifik belum dipastikan sampai konteks PO/rak/gudangnya dicatat. Jangan mengubah data master untuk menutupi ketidaksinkronan form.
