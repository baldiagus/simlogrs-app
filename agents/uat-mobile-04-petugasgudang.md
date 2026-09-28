# DOKUMEN UAT CLIENT MOBILE: PETUGAS GUDANG
## SIMLOG RS NON-MEDIS v2 (FLUTTER CLIENT)

---

### Identitas Peran & Kredensial
* **Peran (Role)**: Petugas Gudang Pelaksana (`petugas_gudang`)
* **Email Akun**: `petugasgudang@simlogrs.local`
* **Kata Sandi**: `password`
* **Wewenang Khusus di Mobile**:
  - Pelaksana operasional fisik di lantai gudang logistik.
  - Pemeriksa barang masuk kiriman vendor (*Inbound Receiving PO*).
  - Eksekutor pemindaian barcode/QR untuk *Picking FEFO* alokasi kirim SPPB.
  - Penginput hasil hitung fisik tanpa melihat saldo sistem (*Blind Count Opname*).

---

### Skenario 1: Penerimaan Fisik Komoditas dari Vendor (Inbound PO ke Rak)
* **Kode Kasus Uji**: `UAT-MOB-STF-01`
* **Tujuan**: Memastikan Petugas Gudang dapat mencocokkan surat jalan, menetapkan nomor batch, tanggal kedaluwarsa, dan rak penyimpanan fisik.
* **Langkah-langkah Pengujian**:
  1. Login menggunakan chip **Petugas Gudang** (`petugasgudang@simlogrs.local`).
  2. Pada Beranda, ketuk kartu aksi cepat **Penerimaan PO**.
  3. Cari PO berstatus `DIKIRIM_VENDOR` yang barang fisiknya tiba di gudang.
  4. Tekan tombol ungu **Proses Penerimaan Fisik**.
  5. Masukkan **Nomor Surat Jalan** vendor (misal: `SJ-2026-9921`).
  6. Pada baris komoditas barang:
     - Masukkan **Nomor Batch Fisik** dari kemasan (misal: `BATCH-2026-X1`).
     - Pilih **Tanggal Kedaluwarsa** menggunakan DatePicker.
     - Pilih **Rak Penyimpanan** (misal: *RAK A Utama*).
     - Masukkan **Jumlah Diterima** (misal: `10`) dan **Jumlah Rusak** (`0`).
  7. Tekan tombol **Simpan Penerimaan Barang**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Penerimaan berhasil disimpan dengan nomor bukti resmi `RCV-...` (HTTP 201).
  - Stok batch baru otomatis bertambah di rak yang dipilih dan kartu stok mencatat mutasi `MASUK`.
  - Status PO diperbarui otomatis menjadi `DITERIMA_LENGKAP` atau `DITERIMA_SEBAGIAN`.
* **Kriteria Pengecualian (Validation Guard)**:
  - Jika nomor batch atau rak penyimpanan tidak dipilih, sistem memblokir submit dengan snackbar peringatan.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 2: Pemindaian Barcode & Eksekusi Picking FEFO Alokasi Kirim SPPB
* **Kode Kasus Uji**: `UAT-MOB-STF-02`
* **Tujuan**: Memvalidasi pengambilan komoditas di rak sesuai prinsip First-Expired, First-Out menggunakan pemindai kamera gawai.
* **Langkah-langkah Pengujian**:
  1. Di Beranda, ketuk kartu aksi cepat **Picking FEFO**.
  2. Buka daftar antrean picking permohonan amprah yang berstatus `DISETUJUI_GUDANG`.
  3. Tekan tombol **Eksekusi Picking**.
  4. Arahkan kamera scanner ke barcode batch barang di rak, atau ketuk tombol eksekusi picking otomatis.
* **Kriteria Keberhasilan (Primary Path)**:
  - Algoritma FEFO mengalokasikan batch dengan tanggal kedaluwarsa paling awal.
  - Dokumen pengiriman resmi `SPPB-YYYYMM-XXX` diterbitkan secara atomik berstatus `DIKIRIM`.
  - Saldo stok batch di rak otomatis berkurang via *pessimistic locking* (`lockForUpdate`).
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 3: Input Hitung Fisik Blind Count di Depan Rak Opname
* **Kode Kasus Uji**: `UAT-MOB-STF-03`
* **Tujuan**: Memastikan petugas dapat merekam jumlah fisik barang di depan rak tanpa bias saldo sistem.
* **Langkah-langkah Pengujian**:
  1. Di Beranda, buka modul **Stock Opname**.
  2. Pilih sesi opname aktif berstatus `BERJALAN`.
  3. Tekan tombol **Hitung Fisik (Count)**.
  4. Masukkan nomor batch atau pindai barcode rak.
  5. Masukkan **Jumlah Fisik Riil** hasil hitungan tangan (misal: `45`).
  6. Tekan tombol **Kirim Hasil Hitung**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Hasil hitung fisik tersimpan dengan status `PROSES_COUNT`.
  - Petugas gudang tidak diperlihatkan selisih sebelum proses finalisasi diotorisasi oleh Kepala Gudang.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 4: Pembatasan Wewenang Otorisasi & Pencegahan IDOR
* **Kode Kasus Uji**: `UAT-MOB-STF-04`
* **Tujuan**: Memvalidasi bahwa hak akses Petugas Gudang terisolasi secara ketat dari modul pengawasan dan keuangan.
* **Langkah-langkah Pengujian**:
  1. Buka layar **Pagu & Realisasi Anggaran** (jika mencoba akses via route langsung).
  2. Buka layar **Pusat Audit SPI**.
  3. Periksa apakah Petugas Gudang dapat mengotorisasi selisih penyesuaian stok.
* **Kriteria Keberhasilan (Security Guard Path)**:
  - Akses ke modul Pagu & Realisasi ditolak dengan tampilan **Akses Ditolak (403)**.
  - Akses ke Pusat Audit SPI diblokir dengan tampilan **Akses Ditolak (403)**.
  - Tombol Otorisasi Penyesuaian tidak muncul di antarmuka Petugas Gudang.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................
