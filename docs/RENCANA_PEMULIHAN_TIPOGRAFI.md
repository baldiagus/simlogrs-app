# Rencana Pemulihan Tipografi dan Layout

Status: implementasi pemulihan diterapkan. Verifikasi terarah selesai; cakupan visual penuh seluruh state/peran belum dibuktikan.

## Sasaran

Mengembalikan kepadatan, proporsi, dan keterbacaan halaman mendekati baseline `screenshots/`, tanpa mengembalikan overflow lama, menghilangkan informasi penting, mengubah alur bisnis, atau mematikan pembesaran teks.

Rekomendasi: pertahankan Plus Jakarta Sans dan JetBrains Mono terlebih dahulu. Perbaiki ukuran teks sesuai peran komponen beserta constraints/layout-nya; jangan menurunkan seluruh skala tema secara seragam. Bila perbandingan visual masih menyimpang, kalibrasi token yang terbukti bermasalah, bukan menambahkan ukuran acak per halaman.

## Bukti dan batas audit saat ini

- Inventaris: 46 file `*screen.dart`, empat keluarga dashboard, serta dialog, sheet, tab, dan variasi aksi lintas peran. Inventaris sumber bukan bukti seluruh halaman sudah lolos visual.
- URL audit: `http://localhost:7357/`, viewport utama 343×762 sesuai contoh pengguna.
- Browser yang benar-benar berhasil digunakan: browser otomatis headless. Ego terpasang di `C:/Program Files/Citro Labs/ego lite/Application/ego.exe`, tetapi relay timeout; executable aktif tidak mempunyai endpoint CDP yang dapat digunakan. Profil audit Ego terpisah sempat menyediakan endpoint/onboarding, tetapi koneksi halaman gagal dan proses kemudian berhenti. Tidak ada klaim audit Ego telah berhasil.
- Baseline: `screenshots/INDEX.md` dan gambar yang dirujuknya. Baseline lama juga memiliki batas cakupan dan bukan contoh sempurna untuk semua komponen. Bandingkan pada viewport dan device scale yang sama; jangan menyalin ukuran piksel gambar mentah sebagai ukuran layout.
- Navigasi audit hanya membaca data dan membuka formulir. Tidak mengirim PR, amprah, opname, evaluasi CAPA, pekerjaan servis, atau transaksi lain.
- Tidak menjalankan build/test/analyzer untuk audit perencanaan ini. Kelulusan tes sebelumnya bukan bukti layout telah benar.

### Permukaan yang dibuka pada audit browser ini

- Login; dashboard auditor, superadmin, kepala gudang, teknisi, kepala ruangan, dan manajemen: mencakup empat keluarga dashboard.
- Audit SPI: Audit Trail, Kepatuhan PO, Selisih Opname, Temuan & CAPA; detail/evaluasi temuan dan formulir registrasi temuan.
- Master barang, detail barang, register aset, dan profil aset fisik.
- Pengadaan: tab PR, PO, penerimaan inbound; detail PR; formulir pengajuan PR.
- Amprah: hub dan detail permintaan, formulir pengajuan; picking distribusi.
- Sirkulasi: pinjaman, otorisasi, siap kembali; formulir peminjaman.
- Pengalihan: hub aset/barang dan formulir pengalihan aset.
- FEFO, buku mutasi, stock opname, hitung fisik, dan dialog inisiasi opname.
- Penerimaan PO: daftar inbound dan formulir pemeriksaan/penerimaan.
- Maintenance: hub laporan rusak, detail tiket, formulir laporan; daftar/detail SPK, lembar kerja, jadwal preventif, katalog/detail rekam medis.
- Profil, perubahan kata sandi, inbox kosong, laporan pagu/pengeluaran dengan dua tab, dan semua aktivitas.

Membuka halaman atau screenshot bagian atas tidak berarti seluruh isi, semua status, bagian bawah, popup, dan pembesaran teks halaman itu telah diaudit. Beberapa screenshot awal memuat loading; gunakan gambar setelah data tampil sebagai bukti konten. Formulir yang belum diisi belum membuktikan tampilan validasi maupun item terpilih.

### Belum terbukti secara visual pada audit ini

- Semua bagian bawah halaman panjang, picker/dropdown, validasi, keyboard terbuka, dan dialog konfirmasi.
- Riwayat PR mandiri; mandatory-password; splash; halaman otorisasi selisih beserta detailnya; histori sirkulasi/pengalihan mandiri.
- Hub IPSRS/komando, disposisi, pembuatan jadwal preventif, tugas preventif; variasi kepala teknisi dan auditee CAPA.
- Cetak/preview QR; variasi kamera berhasil; formulir pengalihan barang; picker aset, suku cadang, vendor, komoditas, lokasi/rak; inspeksi pengembalian dan perpanjangan pinjam.
- Dialog terbitkan/persetujuan PO atau transaksi lain yang dibatasi status data/hak akses.
- Seluruh variasi peran, viewport lain, dan text scaling 150/200% setelah perubahan saat ini.

Permukaan di atas wajib diberi status terpisah: belum diperiksa, terhalang data/akses, gagal, atau lulus. Jangan menandai lulus berdasarkan kemiripan kode.

## Temuan prioritas

| Prioritas | Temuan | Bukti / lokasi | Tindakan |
|---|---|---|---|
| P0 | Hero terlalu tinggi dan sub-metrik menjadi menara kiri | Browser dashboard; `hero_status_card.dart:32–110`. Header selalu Column. Lebar sub-metrik viewport dikurangi total padding 112; pada 390 menjadi 278, memicu fallback `<280`. | Pulihkan header horizontal bila muat; sub-metrik angka pendek tetap sejajar. Gunakan kebutuhan lebar setiap metrik; fallback harus memenuhi lebar kartu dan memiliki alignment yang disengaja. |
| P0 | Evaluasi CAPA overflow horizontal | Console browser: RenderFlex overflow 85 px pada `detail_temuan_sheet.dart:317`, DropdownButtonFormField. | Batasi field ke lebar tersedia, bungkus label terpilih/opsi dan atur tinggi yang memadai; pertahankan makna label. |
| P0 | Form temuan memaksakan tanggal/field berpasangan | Tampilan form audit; `form_terbitkan_temuan_sheet.dart:154,208,234`; custom date field perlu ditinjau. | Header dapat membungkus tanpa menggeser tutup; satu kolom bila pasangan tanggal/lookup tidak cukup lebar; ikon + teks mendapat constraints yang benar. |
| P1 | Label navigasi dan aksi dapat hilang lewat ellipsis | Risiko sumber: `floating_bottom_nav_bar.dart:98–121`, `custom_button.dart:87–109`. | Kebijakan label responsif; teks aksi lengkap, icon dan non-icon konsisten, tombol berpasangan ditumpuk saat perlu. |
| P1 | Shortcut dashboard tetap dua kolom walau ruang teks sempit | Risiko sumber: `quick_action_grid.dart`, `master_shortcut_section.dart`, `gudang_shortcut_grid.dart`, `ipsrs_shortcut_grid.dart`. | Aturan satu/dua kolom berdasarkan ruang teks dan skala; atur posisi ikon tanpa membuat tinggi tetap/aspect ratio paksa. |
| P1 | Hierarki kartu/detail terlalu renggang atau terlalu banyak baris | Terlihat pada sejumlah daftar/detail; judul, identifier monospace, metadata, dan rupiah perlu dibandingkan per komponen. | Kalibrasi role teks, line-height, spacing; jangan menganggap semua metadata sebagai body berukuran sama. Jangan potong nilai uang/tanggal/status penting. |
| P1 | Header pagu/pengeluaran terpotong | Browser 343 px: judul dan subjudul AppBar ter-ellipsis karena berbagi ruang dengan tahun/refresh. | Pisahkan judul penting dari kontrol tahun pada ukuran sempit; jangan mengecilkan seluruh halaman untuk menyelamatkan AppBar. |
| P2 | Sheet pendek/QR dan teks besar berisiko meluap | Risiko sumber: `app_bottom_sheet_wrapper.dart`, `qr_sticker_sheet.dart`; tidak semua sheet otomatis scroll. | Bounded scrolling, tombol tutup/aksi tetap terjangkau, keyboard tidak menutup aksi. Ukuran label fisik QR dipisahkan dari preview layar. |
| P2 | Metadata dan jumlah memakai lebar tetap | Risiko sumber: `rekam_medis_tabs.dart`, `histori_sirkulasi_aset_screen.dart`, `app_quantity_stepper.dart`. | Label/value berubah vertikal saat perlu; input jumlah mengakomodasi digit nyata dan skala font. |

Console juga mencatat overflow horizontal tambahan 13–39 px; Flutter menyingkat pesan setelah exception pertama, sehingga lokasi semuanya belum dapat dipastikan. Saat implementasi, isolasi reproduksi per halaman sebelum menetapkan penyebabnya.

## Tahapan implementasi

### 1. Kunci pembanding dan reproduksi

- Buat matriks 46 screen + empat keluarga dashboard + tab/sheet/aksi unik, berbasis `screenshots/INDEX.md` dan `docs/uat-mobile*.md`.
- Simpan screenshot sebelum perbaikan pada 343×762 dan 390×844 untuk halaman bermasalah; jangan timpa baseline lama.
- Upayakan koneksi Ego melalui CDP pada profil audit, tanpa menutup/mengubah sesi pengguna. Bila tetap tidak tersedia, hasil browser lain diberi label eksplisit, dan validasi Ego tetap tercatat terhalang.
- Catat isi data panjang: jumlah/rupiah, kode aset/transaksi, status panjang, nama unit, label aksi, tanggal, dan nilai dropdown terpilih.

### 2. Perbaiki hero terlebih dahulu

- File utama `lib/features/dashboard/presentation/widgets/hero_status_card.dart`.
- Angka pendek auditor kembali sebagai strip tiga kolom yang seimbang pada ukuran ponsel normal; bukan satu kolom sempit kiri.
- Header judul/aksi sejajar ketika muat; pindah baris hanya bila benar-benar diperlukan.
- Sub-metrik rupiah memakai susunan berbeda bila isinya tidak muat, tanpa memotong nominal.
- Tinggi mengikuti konten yang diperlukan; jangan hardcode tinggi hero agar screenshot terlihat serupa.
- Bandingkan seluruh keluarga dashboard sebelum melanjutkan migrasi komponen lain.

### 3. Perbaiki fondasi komponen dan aturan ukuran teks

- Tinjau `app_theme.dart`: judul halaman 18, bagian 16, kartu 14, isi 13–14, metadata 12, label 12, KPI 32 adalah baseline sekarang, bukan angka yang harus dipaksakan pada setiap komponen.
- Tetapkan pengecualian komponen yang benar-benar perlu kepadatan berbeda (navigasi, chip, metadata kode); semua pengecualian memiliki nama/peran yang jelas, bukan ukuran literal tersebar.
- Prioritaskan `custom_button`, `floating_bottom_nav_bar`, field tanggal/dropdown, sheet wrapper, badge, stepper, dan top bar.
- Perbaiki constraints lebih dahulu; sesuaikan ukuran/line-height hanya berdasarkan pembandingan aktual.
- Pertahankan touch target, kontras, dan pembesaran teks. Dilarang menutupi overflow dengan clip, FittedBox, textScaleFactor paksa, atau ellipsis pada informasi wajib.

### 4. Selesaikan per keluarga halaman

Urutan: audit/CAPA yang sudah terbukti overflow → dashboard/shortcut → pengadaan dan inbound → amprah/picking → aset/sirkulasi/pengalihan → gudang/opname → maintenance/SPK/preventif → anggaran/aktivitas → auth/profil/inbox.

Untuk setiap keluarga: header/AppBar → filter/tab → kartu daftar → detail → form → picker/dialog → footer/aksi → bagian bawah dan empty/error/loading states. Periksa variasi role yang benar-benar mengubah aksi/layout; jangan menggandakan pemeriksaan hanya karena nama akun berbeda.

### 5. Verifikasi dan gerbang selesai

- Viewport utama: 343×762 (repro), 360×800, 390×844, 412px; smoke tablet 768px dan desktop 1280px.
- Setiap layout unik diperiksa pada 100%, 150%, 200% text scaling, termasuk layar pendek dan keyboard aktif pada form. Browser zoom tidak dianggap pengganti otomatis untuk Flutter TextScaler.
- Tidak ada RenderFlex overflow, clipping label wajib, nominal/tanggal terpotong, tombol di luar jangkauan, atau label aksi yang hilang.
- Kepadatan 100% mendekati baseline yang disetujui; pembesaran teks boleh menambah tinggi dan mengganti kolom, bukan disembunyikan.
- Bukti screenshot sebelum/sesudah pada viewport yang sama; status cakupan eksplisit untuk setiap entry. Halaman terhalang data tidak disebut lulus.
- Jalankan analyzer dan tes terkait setelah perubahan terintegrasi; regression test hanya untuk kasus perilaku/overflow yang belum tercakup. Tes lulus tidak menggantikan pemeriksaan browser.
- Tinjau perubahan terhadap tujuan ini: tanpa perubahan otorisasi, transaksi, data, maupun label bisnis yang tidak diminta.

## Keputusan untuk persetujuan

Rekomendasi: pulihkan proporsi/kepadatan lama sambil mempertahankan font baru dan sistem tema; bukan rollback total font maupun mengecilkan semua teks. Baseline lama menjadi rujukan komposisi, bukan kewajiban mengembalikan bug lamanya. Implementasi dilakukan setelah arah ini disepakati.

## Hasil implementasi dan verifikasi

- Hero memakai pengukuran konten untuk header/sub-metrik; auditor kembali sejajar pada 343/390px. Breakdown rupiah panjang memenuhi lebar kartu tanpa ellipsis.
- Shortcut dashboard responsif; tombol/navigasi membungkus label; sheet dapat digulir di atas keyboard; field tanggal/jumlah dan identitas pengguna menyesuaikan ruang.
- Audit/CAPA memperbaiki dropdown terpilih, pasangan tanggal/lookup, header/tab dan metadata. Anggaran memisahkan judul/tahun dari AppBar. Modul operasional memperbaiki pasangan aksi/input, identifier, metadata, nominal, dan preview QR.
- Build web debug terintegrasi berhasil disajikan di `http://127.0.0.1:7360/`.
- Ego berhasil dipakai melalui profil audit headless terpisah dengan CDP. Pemeriksaan final: hero auditor/navigasi 343×762; evaluasi CAPA dengan label lengkap; form registrasi tanggal bertumpuk; dashboard Manajemen dan anggaran 390×844. Console error kosong pada jalur final tersebut. Tidak ada transaksi disimpan.
- Pengujian terintegrasi: 53 lulus, tiga tes navigasi awalnya gagal karena mengetuk banner di luar viewport. Tes diperbaiki agar menggulir target sebelum mengetuk, tanpa menghapus assertion navigasi/otorisasi. Pengujian ulang tiga file terkait: sembilan lulus. Seluruh tes shared responsif, hero, dan CAPA yang dijalankan lulus; ini bukan klaim full-suite.
- Analyzer terintegrasi melaporkan 122 info lint (exit 1); build web berhasil. Info lint tidak dibersihkan sebagai bagian pemulihan layout.
- Pembesaran 150/200% dibuktikan melalui tes widget hero; 200% melalui tes tombol/navigasi/sheet/jumlah dan CAPA. Belum ada klaim seluruh halaman 200% sudah diperiksa visual di Ego. Daftar state/peran/data-gated audit awal tetap menjadi batas cakupan, bukan otomatis lulus setelah perubahan.
