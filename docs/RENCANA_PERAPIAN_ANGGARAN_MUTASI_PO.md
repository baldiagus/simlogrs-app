# Rencana Perapian UI Anggaran, Buku Mutasi, dan Pesanan PO

## Status dan Cakupan

Dokumen ini merupakan rencana implementasi, bukan catatan perubahan yang sudah diterapkan. Cakupan: header Anggaran, kartu dan modal detail Buku Mutasi Stok, serta kartu dan modal detail tab Pesanan (PO). Endpoint, perhitungan, permission, dan proses transaksi dipertahankan.

Arah desain mengikuti frontend-design-direction: operasional, ringkas, mudah dipindai, dan konsisten dengan komponen proyek. Daftar menampilkan informasi inti; rincian panjang dibuka melalui modal bottom sheet seperti referensi modal detail PR dari pengguna, bukan dialog kecil di tengah layar.

## 1. Halaman Anggaran — Revisi Terakhir

### Susunan header

Teks “Anggaran” pada AppBar diganti menjadi “Pagu & Realisasi Anggaran”. Dropdown tahun sejajar dengan judul dan tepat di sebelah kiri tombol sinkron/muat ulang.

```text
Kembali | Pagu & Realisasi Anggaran | TA 2026 ▾ | Sinkron
        Pengeluaran Ruangan | Suku Cadang IPSRS
```

- Tombol kembali, judul baru, dropdown tahun, dan tombol sinkron berada dalam satu baris header.
- Tab Pengeluaran Ruangan dan Suku Cadang IPSRS tetap berada di bawah AppBar.
- Hapus judul “Pagu & Realisasi Anggaran” dari isi halaman agar tidak berulang.
- Hapus subjudul “Screening Pengeluaran Logistik & Suku Cadang”.
- Hapus dropdown tahun pada posisi lama di isi halaman.
- Pertahankan ringkasan Amprah Ruangan, ringkasan Sparepart IPSRS, serta konten tab aktif.

### Responsivitas dan perilaku

- Judul menggunakan ruang fleksibel dan boleh membungkus menjadi dua baris pada layar sempit; tinggi header menyesuaikan agar tidak terpotong.
- Dropdown tahun dan tombol sinkron tetap berdampingan, tidak tertimpa judul, dengan area sentuh minimal 48 dp.
- Pergantian tahun memperbarui seluruh data terkait, bukan hanya label tahun.
- Tombol sinkron memuat ulang data untuk tahun yang sedang dipilih.
- Filter tahun tetap tersedia saat loading atau error.
- Istilah judul mengikuti permintaan pengguna; perubahan tampilan tidak menambahkan fungsi pengelolaan pagu.

Revisi ini menggantikan rencana awal yang menempatkan dropdown sebagai pengganti judul AppBar dan judul pada baris header terpisah.

File utama: `lib/features/anggaran/presentation/screens/pagu_realisasi_screen.dart`.

## 2. Buku Mutasi Stok

### Kartu daftar

| Posisi | Informasi |
|---|---|
| Baris atas | Badge jenis transaksi dan tanggal/waktu. |
| Judul utama | Nama barang tebal, maksimal dua baris. Nama lengkap tetap tersedia di modal. |
| Baris jumlah | Perubahan jumlah beserta satuan; tanda plus/minus tetap ditampilkan. |
| Metadata | Nomor batch dan nama gudang secara ringkas. |
| Bagian bawah | Saldo sebelum → sesudah dan penanda Detail. |

Pindahkan lokasi rak lengkap, keterangan transaksi panjang, referensi dokumen, nama petugas, dan informasi lain yang tersedia pada model ke modal detail. Hindari paragraf italic panjang dan penggunaan monospace pada seluruh metadata; monospace hanya untuk kode/nomor dokumen bila diperlukan.

### Modal detail mutasi

Ketuk kartu atau Detail untuk membuka bottom sheet dengan susunan:

```text
Detail Mutasi Stok
├── Nama barang lengkap
├── Jenis transaksi · Tanggal/waktu
├── Perubahan jumlah dan satuan
├── Saldo sebelum → Saldo sesudah
├── Informasi persediaan
│   ├── Nomor batch
│   ├── Gudang
│   └── Rak/lokasi
├── Referensi dokumen
├── Keterangan lengkap
└── Dicatat oleh
```

- Ikuti referensi modal PR: sudut atas membulat, drag handle, dan latar belakang redup.
- Konten panjang dapat digulir tanpa terpotong; sediakan tombol tutup yang jelas.
- Informasi yang tidak tersedia ditandai secara jujur tanpa nilai contoh.
- Referensi dokumen menjadi tautan hanya jika navigasi dan aksesnya tersedia.

File utama: `lib/features/gudang/presentation/screens/buku_mutasi_screen.dart`.

## 3. Tab Pesanan (PO)

### Kartu daftar

Ringkas kartu PO; pindahkan daftar komoditas lengkap ke modal.

| Posisi | Informasi |
|---|---|
| Baris atas | Kode PO dan badge status. |
| Judul utama | Nama pemasok/vendor. |
| Metadata | Referensi PR dan unit, jika tersedia. |
| Nilai utama | Total nilai PO. |
| Bagian bawah | Estimasi tanggal kirim, jumlah item, dan Detail. |

### Modal detail PO

```text
Kode PO
├── Status
├── Pemasok/vendor
├── Referensi PR dan unit
├── Ringkasan
│   ├── Total nilai PO
│   └── Estimasi tanggal kirim
├── Rincian barang
│   └── Setiap item
│       ├── Nama barang
│       ├── Jumlah dipesan dan satuan
│       ├── Jumlah diterima [jika tersedia]
│       ├── Harga satuan
│       └── Subtotal
└── Aksi proses PO [sesuai permission dan status]
```

- Gunakan pola bottom sheet yang sama dengan modal PR dan detail mutasi.
- Pertahankan aksi kirim/update pengiriman yang sudah tersedia; jangan hilangkan saat kartu diringkas.
- Pengguna read-only dapat melihat detail tanpa tombol transaksi.
- Setelah aksi berhasil, status daftar dan modal harus konsisten.
- Tidak membuat request detail baru apabila data yang diperlukan sudah tersedia pada model PO.

File utama:

- `lib/features/pengadaan/presentation/widgets/pengadaan_hub_po_tab.dart`
- `lib/features/pengadaan/presentation/widgets/approval_po_card.dart`

## 4. Standar Visual dan Interaksi

Gunakan komponen dan token proyek yang tersedia, terutama `AppBottomSheetWrapper`, warna status, badge, dan tipografi aplikasi. Tidak menambahkan dependensi hanya untuk perubahan visual.

| Elemen | Ketentuan |
|---|---|
| Judul barang/vendor | 15–16 sp, semibold/bold. |
| Nilai/jumlah utama | 16–18 sp, bold. |
| Metadata | 12–13 sp dengan kontras yang jelas. |
| Jarak antarbagian | Konsisten 12–16 dp. |
| Warna status | Disertai teks/ikon; tidak mengandalkan warna saja. |
| Modal | Header tetap terlihat, konten dapat digulir, dan tersedia tombol tutup. |
| Layar lebar | Lebar modal dibatasi dan diposisikan terpusat. |
| Teks panjang | Membungkus tanpa overflow atau menimpa elemen lain. |
| Aksesibilitas | Label kontrol jelas, target sentuh memadai, fokus keyboard terlihat, dan fokus kembali ke pemicu setelah modal ditutup. |
| Gerakan | Gunakan transisi yang tersedia tanpa animasi dekoratif; hormati pengaturan pengurangan gerakan. |

## 5. Kondisi Konten

| Kondisi | Pemicu | Umpan balik dan langkah aman berikutnya |
|---|---|---|
| Loading | Memuat halaman, mengganti tahun, atau refresh. | Indikator stabil; header/filter tetap tersedia; cegah aksi transaksi berulang saat sedang diproses. |
| Kosong | Tidak ada data atau tidak cocok dengan pencarian/filter. | Pesan sesuai konteks dan pilihan mengubah filter/pencarian. |
| Error | Permintaan gagal. | Pesan spesifik dan tombol coba lagi; filter yang dipilih tidak hilang. |
| Data sebagian | Field tertentu tidak tersedia. | Tampilkan informasi yang tersedia dan tandai bagian yang tidak tersedia, tanpa data palsu. |
| Sukses | Detail dibuka atau aksi transaksi berhasil. | Tampilkan detail yang sesuai dan perbarui status/data terkait setelah aksi. |
| Akses terbatas | Permission atau status dokumen tidak mengizinkan aksi. | Jangan tampilkan aksi terlarang; jika server menolak, jelaskan batas akses dan beri jalur kembali yang aman. |

## 6. Urutan Implementasi

1. Rapikan header Anggaran sesuai revisi terakhir.
2. Ringkas kartu mutasi dan tambahkan modal detail.
3. Ringkas kartu PO dan tambahkan modal detail tanpa menghilangkan aksi.
4. Verifikasi tampilan dan perilaku pada viewport 360 × 800, 402 × 817, serta 1280 × 800.
5. Periksa skala teks diperbesar, nama barang/vendor panjang, banyak item PO, data kosong, error, data sebagian, akses read-only, buka/tutup modal, dan refresh setelah aksi.

## 7. Kriteria Penerimaan dan Bukti

- Header Anggaran menampilkan judul baru, dropdown tahun di kiri tombol sinkron, dan tidak memiliki judul/subjudul/filter duplikat pada isi halaman.
- Semua informasi pada kartu lama tetap dapat diakses melalui kartu ringkas atau modal.
- Modal mutasi dan PO mengikuti pola modal detail PR yang menjadi referensi pengguna.
- Tidak ada overflow, teks bertumpuk, atau kontrol terpotong pada viewport target dan skala teks diperbesar.
- Permission, filter, perhitungan, dan aksi transaksi tetap bekerja sesuai kontrak sebelumnya.
- Verifikasi dilakukan pada UI yang benar-benar dirender; pemeriksaan source saja tidak dianggap bukti visual.
- Simpan bukti tampilan lokal dan catatan hasil per viewport serta kondisi konten sesuai frontend-design-direction. Kondisi yang belum diuji harus dinyatakan belum diuji, bukan diklaim lulus.

## Hasil Implementasi

- Header Anggaran telah diperbarui: judul baru, dropdown tahun di kiri tombol muat ulang, dan header menyesuaikan pembungkusan teks. Judul, subjudul, dan filter duplikat di isi dihapus.
- Kartu Buku Mutasi diringkas; detail lengkap dibuka melalui bottom sheet dengan tombol tutup dan konten yang dapat digulir.
- Kartu PO diringkas; metadata dan rincian item dipindahkan ke bottom sheet. Aksi pengiriman tetap mengikuti status dan permission. Modal ditutup sebelum memanggil alur konfirmasi/pengiriman agar snapshot lama tidak tertinggal.
- Pengujian widget mutasi lulus pada 360 × 800, 402 × 817, dan 1280 × 800 dengan skala teks 1,3; detail yang disembunyikan dari kartu tetap tersedia, dapat digulir, dan modal dapat ditutup.
- Delapan pengujian filter/permission PO lulus, termasuk membuka detail, menyembunyikan aksi read-only, memanggil callback sekali, dan menutup modal sebelum aksi.
- Delapan belas skenario header Anggaran lulus: tiga viewport target, skala teks 1 dan 2, serta kondisi data/loading/error. Pemilihan tahun, refresh tahun terpilih, posisi kontrol, dan target sentuh diperiksa.
- Pengujian overflow drilldown unit yang sudah ada juga lulus dalam pemeriksaan terarah.
- Analisis tiga file UI tidak menemukan error; melaporkan dua info prefer_const_constructors pada kartu ringkasan Anggaran yang tidak diubah.

### Batas Verifikasi

Capture hasil render widget mutasi tersedia di `build/ui-evidence/`. Capture widget test memakai font pengujian (blok/Ahem), sehingga bukan bukti keterbacaan tipografi aplikasi produksi. Pemeriksaan browser/perangkat nyata, keyboard/fokus, kontras, reduced motion, seluruh kondisi data sebagian, dan transaksi backend end-to-end belum dilakukan. Gate visual frontend-design-direction belum dinyatakan lulus; tidak ada klaim keberhasilan pengiriman PO ke backend dari pengujian callback.

### Revisi tab Suku Cadang IPSRS

- Hapus kartu Pos Suku Cadang IPSRS Sentral serta judul/deskripsi Top 5; daftar aset dan riwayat tetap tersedia. Ringkasan biaya atas tetap dipertahankan.
- Revisi akhir: judul disingkat menjadi Anggaran (16 sp semibold), tahun (12 sp) dan refresh kembali sejajar dalam app bar. Baris khusus tahun dihapus; tab dipadatkan menjadi 48 dp pada skala normal. Tinggi total header 107 dp termasuk indikator tab 3 dp, di luar status bar. Pembesaran teks tetap didukung.
- 24 skenario header ringkas lulus dengan font Plus Jakarta Sans dan tema aplikasi: 360×800, 402×817, 437×841, 1280×800; skala 1×/2×; data/loading/error. Judul satu baris pada skala normal, tidak bertabrakan dengan tahun, tinggi header maksimal 108 dp pada skala normal, target sentuh, pemilihan tahun, dan refresh diuji.
- Analisis terarah tidak menemukan error; empat info prefer_const_constructors pada kode yang sudah ada.
- Verifikasi browser/perangkat nyata dan capture visual revisi ini belum dilakukan; gate visual belum dinyatakan lulus.
