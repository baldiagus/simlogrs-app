# DOKUMEN UAT CLIENT MOBILE: KEPALA GUDANG
## SIMLOG RS NON-MEDIS v2 (FLUTTER CLIENT)

---

### Identitas Peran & Kredensial
* **Peran (Role)**: Kepala Gudang Logistik (`kepala_gudang`)
* **Email Akun**: `kepalagudang@simlogrs.local`
* **Kata Sandi**: `password`
* **Wewenang Khusus di Mobile**:
  - Penanggung jawab fisik fasilitas gudang logistik sentral.
  - Otorisator tunggal penyesuaian selisih stok fisik (*Variance Authorization*).
  - Inisiator jadwal stock opname berkala dan pengaju Permintaan Pengadaan Gudang (PR).
  - Otorisator perizinan peminjaman sarana fisik yang berada di fasilitas gudang.

---

### Skenario 1: Otorisasi Dokumen Penyesuaian Stok (Approval Selisih Opname)
* **Kode Kasus Uji**: `UAT-MOB-WH-01`
* **Tujuan**: Memastikan Kepala Gudang dapat mengesahkan dokumen penyesuaian hasil hitung fisik yang memiliki selisih kuantitas.
* **Langkah-langkah Pengujian**:
  1. Login ke aplikasi menggunakan chip **Kepala Gudang** (`kepalagudang@simlogrs.local`).
  2. Pada Beranda bagian bawah, ketuk kartu **Otorisasi Penyesuaian**.
  3. Cari dokumen penyesuaian stok yang berstatus `MENUNGGU`.
  4. Ketuk kartu dokumen untuk membuka rincian selisih batch (*jumlah sistem vs fisik*, nominal rupiah selisih).
  5. Tekan tombol **Sahkan Penyesuaian (Approve)**.
  6. Konfirmasi persetujuan pada dialog modal.
* **Kriteria Keberhasilan (Primary Path)**:
  - Status penyesuaian berhasil disahkan menjadi `DISETUJUI` (HTTP 200).
  - Kartu stok otomatis mencatat mutasi jenis `PENYESUAIAN` dan saldo batch diperbarui secara atomik.
* **Kriteria Pengecualian (Security Guard)**:
  - Kepala Gudang dicegah mengesahkan penyesuaian stok yang berasal dari fasilitas gudang lain yang bukan wewenangnya (HTTP 403 Forbidden).
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 2: Pengajuan Permintaan Pengadaan Khusus Gudang (PR Gudang)
* **Kode Kasus Uji**: `UAT-MOB-WH-02`
* **Tujuan**: Memvalidasi alur pengajuan PR komoditas logistik untuk akun gudang (menggunakan atribut `gudang_id` tanpa `unit_id`).
* **Langkah-langkah Pengujian**:
  1. Pada Beranda, ketuk ikon aksi permohonan atau buka riwayat PR.
  2. Tekan tombol floating **Ajukan PR Baru** (`+`).
  3. Tekan **Pilih Barang dari Katalog**.
  4. Pilih komoditas ATK/ART yang stoknya menipis (misal: *Kertas HVS 80gr*).
  5. Tentukan kuantitas permintaan (misal: `50 Rim`).
  6. Pilih Urgensi: `REGULER` atau `MENDESAK`.
  7. Masukkan catatan: *"Restok buffer gudang sentral untuk triwulan IV"*.
  8. Tekan tombol **Kirim Permintaan Pengadaan**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Permintaan berhasil terkirim dengan status `DIAJUKAN` (HTTP 201).
  - Backend memvalidasi `gudang_id` pengguna tanpa memicu error validasi *unit_id required*.
  - Dokumen PR langsung muncul di antrean persetujuan Bagian Pengadaan.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 3: Pemantauan Sesi Stock Opname & Blind Count Fisik
* **Kode Kasus Uji**: `UAT-MOB-WH-03`
* **Tujuan**: Memastikan Kepala Gudang dapat memantau progres penghitungan fisik yang sedang dijalankan petugas di lorong rak.
* **Langkah-langkah Pengujian**:
  1. Di Beranda, ketuk kartu mini **Stock Opname**.
  2. Buka sesi opname aktif yang berstatus `BERJALAN` atau `PROSES_COUNT`.
  3. Amati indikator: *Total Item Terdaftar*, *Total Terhitung*, dan *Batch Selisih*.
  4. Lakukan pull-to-refresh untuk memantau pembaruan hitung fisik secara berkala.
* **Kriteria Keberhasilan (Primary Path)**:
  - Daftar sesi opname memuat seluruh rekapitulasi data fisik secara akurat.
  - Jumlah batch terhitung bertambah real-time saat petugas gudang mengirimkan data scan.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 4: Otorisasi Peminjaman Sarana Gudang (Sirkulasi Aset)
* **Kode Kasus Uji**: `UAT-MOB-WH-04`
* **Tujuan**: Menguji pemberian izin peminjaman alat/sarana yang tersimpan di gudang oleh ruangan lain.
* **Langkah-langkah Pengujian**:
  1. Ketuk kartu aksi **Sirkulasi Aset** di Beranda.
  2. Beralih ke Tab 2 **Otorisasi**.
  3. Cari permohonan pinjam aset dengan penanda tipe penyedia `GUDANG`.
  4. Periksa nama ruangan peminjam, tanggal rencana kembali, dan keperluan peminjaman.
  5. Tekan tombol **Setujui Izin Pinjam**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Permintaan peminjaman berubah status menjadi `DISETUJUI`.
  - Tombol aksi serah terima fisik aktif di gawai petugas gudang.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................
