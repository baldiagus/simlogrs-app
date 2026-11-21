# Rencana Perbaikan Ringkasan Audit dan Beranda

Status: implementasi diterapkan; 38 tes terarah lulus. Verifikasi visual halaman terautentikasi terhalang koneksi API.

## 1. Temuan dan penyebab

### Empat kartu ringkasan Audit SPI berubah menjadi 2 × 2

- `lib/features/audit/presentation/screens/audit_spi_hub_screen.dart:167–174` memilih empat kolom hanya jika lebar konten minimal `600 × skala teks`; selebihnya dua kolom melalui `Wrap`.
- Pada viewport 343px dan skala 100%, padding horizontal 32px menyisakan 311px. Syarat 600px tidak terpenuhi, sehingga hasilnya pasti dua kolom.
- Pembanding `screenshots/auditor/02-audit-spi.png` memperlihatkan empat kartu sejajar, tetapi label terakhir terpotong. Pulihkan komposisinya, bukan pemotongan teksnya.

### Status FCM muncul pada seluruh beranda

- `lib/shared/widgets/user_top_bar.dart:61–75` menempatkan label status FCM di samping sapaan melalui `ValueListenableBuilder` dan `_FcmStatusLabel`.
- Pencarian sumber menemukan `UserTopBar` pada empat keluarga dashboard (eksekutif, gudang, IPSRS, ruangan) serta loading/error Beranda.
- Penelusuran referensi LSP timeout dua kali; cakupan tersebut berasal dari pencarian sumber, bukan hasil LSP.

### Hero Manajemen terlalu tinggi

- `lib/features/dashboard/presentation/widgets/hero_status_card.dart:33–76` memindahkan aksi ke bawah judul bila gabungannya tidak muat.
- Pada baris 101–139, bila nominal sub-metrik membutuhkan lebar lebih besar daripada kolom yang tersedia, seluruh sub-metrik diubah menjadi susunan vertikal.
- Kombinasi judul/aksi bertumpuk, nominal utama, dan tiga sub-metrik bertumpuk membuat kartu memanjang. Ini konsekuensi fallback pemulihan sebelumnya, bukan kebutuhan data dashboard.
- Gambar tambahan terbaru 519×200 hanya memperlihatkan potongan latar, bukan isi kartu. Analisis komposisi memakai kode saat ini dan screenshot Manajemen 390×844 pada percakapan sebelumnya; tidak mengklaim pemeriksaan runtime baru.

## 2. Rencana perubahan

### A. Ringkasan Audit SPI: empat kartu satu baris

- Ganti aturan `Wrap` dua/empat kolom dengan satu strip empat kartu berurutan: Open CAPA, Closing Rate, Anomali PO, Selisih Opname.
- Pada 343/360/390/412px, skala 100%: empat kartu sama lebar, seluruhnya terlihat tanpa geser horizontal. Pada 343px dengan padding 16px dan gap 8px, lebar awal tiap kartu sekitar 71,75px; padding dalam dan pembungkusan label disesuaikan berdasarkan hasil render.
- Label boleh dua baris; sediakan slot label konsisten agar keempat nilai tetap sejajar dan tinggi kartu sama.
- Jangan gunakan ellipsis, pengecilan otomatis, atau mematikan pembesaran teks.
- Saat pembesaran 150/200% atau nilai panjang benar-benar tidak muat: rekomendasi tetap satu baris dengan kartu lebih lebar dan strip dapat digeser horizontal, bukan kembali menjadi 2 × 2. Beri petunjuk scroll yang terlihat; pastikan seluruh metrik dapat dijangkau.
- Perubahan hanya header ringkasan, bukan tab, filter, daftar audit, perhitungan KPI, atau hak akses.

### B. Hapus label FCM dari seluruh Beranda

- Hapus seluruh label diagnostik dari `UserTopBar`: FCM Aktif, FCM Tidak Tersedia, Token Belum Terdaftar, Izin Ditolak, dan FCM Belum Siap, termasuk titik warnanya.
- Hapus listener UI, kelas label privat, dan import layanan push yang menjadi tidak terpakai pada file ini.
- Pertahankan sapaan, nama, unit/gudang, avatar, lonceng, jumlah belum dibaca, dan logout.
- Jangan menghapus inisialisasi Firebase, registrasi token, permintaan izin, sinkronisasi inbox, atau penerimaan notifikasi. Penghapusan ini murni tampilan diagnostik di Beranda.
- Periksa empat keluarga dashboard serta loading/error Beranda; cakupan akun mengikuti role yang tersedia pada aplikasi.

### C. Hero Manajemen: ubah presentasi agar ringkas

Rekomendasi komposisi pada skala 100%:

- Judul pendek `Pengeluaran RS`, dengan aksi `Rincian` pada baris yang sama bila muat; tujuan aksi tetap halaman pengeluaran/anggaran yang sekarang.
- Total pengeluaran tetap rupiah lengkap sebagai angka utama.
- Tiga sub-metrik kembali satu baris: Amprah, Servis, Ruangan. Nilai uang sub-metrik boleh memakai notasi lokal ringkas dengan satuan eksplisit, misalnya `Rp 8,03 jt`, `Rp 7,21 jt`, dan `9`.
- Nilai tepat tetap tersedia pada semantik aksesibilitas dan halaman Rincian; pembulatan hanya presentasi ringkasan. Jangan mengubah nilai API/model atau perhitungan total. Format ringkas perlu menangani ribu/juta/miliar, nol, serta batas pembulatan tanpa menyesatkan satuan.
- Pemilihan presentasi harus berdasarkan identitas/target metrik yang stabil dari kontrak data setelah diperiksa, bukan mencocokkan teks judul atau nominal tertentu. Hindari perubahan global yang memendekkan label atau nominal role lain.
- Jika format ringkas masih tidak muat pada nilai ekstrem/pembesaran teks, izinkan layout adaptif tanpa clipping; target kepadatan berlaku pada skala normal, bukan tinggi tetap untuk semua skala.
- Gunakan padding/radius dan hierarki hero yang sama dengan role lain. Sasaran: tidak ada lagi breakdown vertikal tiga item pada lebar ponsel normal. Jangan memaksa tinggi piksel sama dengan clipping atau kotak tinggi tetap.

## 3. Urutan pelaksanaan setelah disepakati

1. Kunci persetujuan fallback kartu audit saat teks diperbesar serta notasi uang ringkas pada hero Manajemen.
2. Periksa kontrak metrik Manajemen dan tujuan aksi; simpan screenshot sebelum perubahan pada ukuran yang sama.
3. Tambah/perbarui regresi yang menangkap gejala pengguna: empat metrik audit sejajar, label FCM absen tetapi inbox tetap berfungsi, hero Manajemen tidak menjadi breakdown vertikal pada skala 100%.
4. Implementasikan perubahan lokal header audit, top bar, dan presentasi hero Manajemen. Pertahankan perilaku role lain.
5. Jalankan tes terarah dan analyzer setelah integrasi; bandingkan screenshot sebelum/sesudah pada 343×762 dan 390×844. Smoke 360/412px dan pembesaran 150/200% melalui Flutter TextScaler.
6. Periksa browser aktual, tidak mengirim transaksi. Proses Ego audit sebelumnya dilaporkan berhenti dengan exit 1; bangun ulang koneksi atau catat eksplisit bila memakai browser lain. Jangan menyatakan Ego lulus berdasarkan hasil sesi lama.

Catatan kontrak data: `SubMetricModel` saat ini hanya menyediakan `label`, `nilai` berbentuk String, dan `warna`; belum ada kode metrik atau nominal numerik terpisah. Saat implementasi, periksa payload Manajemen sebelum memilih format ringkas. Jangan mengambil urutan item atau mengurai semua string sebagai uang secara sembarang. Bila kontrak tidak menyediakan cara aman mengenali nominal, putuskan penyesuaian kontrak yang eksplisit atau kurangi sub-metrik hero; jangan membuat fallback angka palsu.

## 4. Kriteria penerimaan

- Pada 343px/100%, empat kartu Audit SPI terlihat sekaligus dalam satu baris; nilai sejajar, label lengkap, tinggi kartu seragam, tanpa overflow.
- Pada skala besar, semua label dan nilai dapat dijangkau tanpa menonaktifkan scaling; rekomendasi mempertahankan satu strip horizontal.
- Tidak ada teks/titik status FCM pada Beranda role mana pun, termasuk loading/error; lonceng dan badge belum dibaca tetap bekerja.
- Hero Manajemen pada 343/390px/100% tidak lagi menumpuk tiga sub-metrik ke bawah; total tepat, satuan ringkas jelas, tombol Rincian tetap bekerja.
- Perbandingan hero memakai viewport dan skala teks yang sama. Tidak ada pemaksaan tinggi yang memotong teks pada skala besar.
- Tidak ada perubahan data, otorisasi, layanan push, transaksi, font global, atau alur halaman lain.

## 5. Keputusan yang perlu disepakati

1. Audit: empat kartu terlihat sekaligus pada skala normal; ketika teks diperbesar, tetap satu baris dengan scroll horizontal bila perlu.
2. Manajemen: total utama tetap lengkap, sementara tiga sub-metrik memakai label pendek dan nominal ringkas; rincian nominal tepat tetap di halaman tujuan.

## 6. Hasil pelaksanaan

- Header audit sekarang satu strip empat kartu sama lebar/tinggi; kebutuhan lebar diukur dari label dan nilai. Nilai tetap sejajar, tanpa ellipsis. Ketika konten membesar, strip dapat digeser dan menampilkan petunjuk geser.
- Label dan titik status FCM dihapus dari `UserTopBar`, termasuk listener UI dan import yang tidak diperlukan. Layanan push dan sinkronisasi unread tidak diubah.
- Hero Manajemen menggunakan flag presentasi eksplisit dari view, dibatasi target `pagu_realisasi`; judul Pengeluaran RS dan aksi Rincian. Total tetap lengkap, sub-metrik ringkas dengan nilai asli pada semantik. String format uang yang tidak didukung ditampilkan apa adanya; tidak dikonversi menjadi nol. Role lain mempertahankan presentasi sebelumnya.
- Tes terarah lima file: 38 lulus, mencakup strip audit 343px/100–200%, seluruh status FCM dan unread badge, hero Manajemen 343/390px dengan font produksi, batas pembulatan nominal, skala 150/200%, dan navigasi inbox pada keluarga dashboard.
- Analyzer pada tujuh file perubahan saat integrasi: No issues found. Pemeriksaan ini bukan analyzer seluruh repo.
- Build web debug berhasil di port 7360. Browser Chromium berhasil membuka login, tetapi percobaan masuk menampilkan Tidak dapat terhubung ke server; konfigurasi API menunjuk 192.168.0.66:8000. Halaman audit/Manajemen aktual belum diperiksa visual pada sesi ini. Ego berhasil membuka halaman, tetapi semantik Flutter tidak tersedia pada percobaan tersebut; tidak diklaim lolos visual.
- Tidak mengirim transaksi, mengubah konfigurasi API, atau menonaktifkan text scaling. Tampilan akhir perlu dibandingkan di browser setelah backend dapat dijangkau; kelulusan tes widget bukan pengganti bukti visual tersebut.
