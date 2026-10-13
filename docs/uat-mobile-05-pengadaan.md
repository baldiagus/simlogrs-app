# DOKUMEN UAT CLIENT MOBILE: BAGIAN PENGADAAN
## SIMLOG RS NON-MEDIS v2 (FLUTTER CLIENT)

---

### Identitas Peran & Kredensial
* **Peran (Role)**: Staf / Pejabat Bagian Pengadaan (`pengadaan`)
* **Email Akun**: `pengadaan@simlogrs.local`
* **Kata Sandi**: `password`
* **Wewenang Khusus di Mobile**:
  - Verifikator dokumen Permintaan Pengadaan (PR) lintas unit ruangan dan gudang.
  - Penerbit resmi Pesanan Pembelian (PO) ke rekanan vendor terpilih.
  - Pengelola status pelacakan pengiriman rekanan vendor (`DIKIRIM_VENDOR`).
  - Pemantau realisasi serapan anggaran belanja operasional rumah sakit.

---

### Skenario 1: Verifikasi & Otorisasi Permintaan Pengadaan (PR Approval)
* **Kode Kasus Uji**: `UAT-MOB-BUY-01`
* **Tujuan**: Memastikan Bagian Pengadaan dapat menelaah permohonan PR dan memberikan persetujuan pengadaan.
* **Langkah-langkah Pengujian**:
  1. Login ke aplikasi menggunakan chip **Pengadaan** (`pengadaan@simlogrs.local`).
  2. Buka tab **Approval** pada bottom bar (Tab 1).
  3. Amati daftar dokumen PR berstatus `DIAJUKAN`.
  4. Buka salah satu kartu PR $\rightarrow$ telaah rincian komoditas, kuantitas, urgensi, dan alasan pemohon.
  5. Tekan tombol **Setujui** $\rightarrow$ masukkan catatan resmi $\rightarrow$ tekan **Ya, Setujui**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Dokumen PR berhasil disetujui dan statusnya berubah menjadi `DISETUJUI`.
  - Tombol aksi pada kartu PR otomatis berganti menjadi **Terbitkan PO (Pesanan Pembelian)**.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 2: Penerbitan Pesanan Pembelian (PO) ke Rekanan Vendor Terpilih
* **Kode Kasus Uji**: `UAT-MOB-BUY-02`
* **Tujuan**: Memvalidasi modal pembuatan PO, penetapan vendor, tanggal estimasi kirim, syarat pembayaran, dan negosiasi harga satuan.
* **Langkah-langkah Pengujian**:
  1. Pada kartu PR berstatus `DISETUJUI`, tekan tombol ungu **Terbitkan PO (Pesanan Pembelian)**.
  2. Pada lembar formulir bawah (*bottom sheet*):
     - Pilih **Rekanan / Vendor Pemasok** dari daftar dropdown (misal: *PT Sumber Makmur Logistik*).
     - Tentukan **Estimasi Tanggal Kirim** menggunakan DatePicker.
     - Pilih **Syarat Pembayaran**: `TEMPO_30_HARI`, `TEMPO_60_HARI`, atau `TUNAI`.
     - Masukkan catatan pesanan: *"Pengiriman dilakukan pada jam kerja gudang sentral"*.
     - Pada baris komoditas barang, masukkan harga satuan negosiasi (misal: `Rp 45.000`).
  3. Perhatikan kalkulasi **Total Biaya PO** di bagian bawah yang terakumulasi otomatis.
  4. Tekan tombol **Terbitkan PO Sekarang**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Dokumen PO resmi berhasil diterbitkan dengan format nomor kode `PO-YYYY-XXX` (HTTP 201).
  - Status PR induk otomatis berganti menjadi `DIPROSES`.
  - Sistem merekonsiliasi barang secara akurat tanpa terjadi kolisi controller antar item.
* **Kriteria Pengecualian (Business Logic Guard)**:
  - Sistem menolak penerbitan PO jika ada item dengan harga $\le 0$ atau kuantitas melebihi yang disetujui pada PR.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 3: Pembaruan Status Pelacakan Pengiriman Vendor (Update Kirim)
* **Kode Kasus Uji**: `UAT-MOB-BUY-03`
* **Tujuan**: Memperbarui status pesanan menjadi sedang dikirim oleh rekanan vendor agar siap diterima gudang.
* **Langkah-langkah Pengujian**:
  1. Buka Tab 2 **Pesanan (PO)** pada Approval Center.
  2. Filter status menggunakan chip: pilih `Diterbitkan`.
  3. Cari PO yang baru diterbitkan.
  4. Tekan tombol toska **Update Status: Sedang Dikirim Vendor**.
  5. Konfirmasi pembaruan status pada dialog pop-up.
* **Kriteria Keberhasilan (Primary Path)**:
  - Status PO berhasil diperbarui menjadi `DIKIRIM_VENDOR`.
  - PO otomatis masuk ke daftar antrean *Penerimaan Inbound* petugas gudang sentral.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 4: Pemantauan Pagu & Realisasi Anggaran Pengadaan
* **Kode Kasus Uji**: `UAT-MOB-BUY-04`
* **Tujuan**: Memastikan Bagian Pengadaan dapat mengawasi ketersediaan pagu sebelum merilis pesanan pembelian baru.
* **Langkah-langkah Pengujian**:
  1. Buka Beranda $\rightarrow$ ketuk banner toska **Pagu & Realisasi Anggaran RS**.
  2. Amati total serapan belanja pengadaan vs sisa pagu anggaran tahun berjalan.
  3. Periksa status unit: pastikan unit tidak dalam kondisi `Over-Budget`.
* **Kriteria Keberhasilan (Primary Path)**:
  - Seluruh data pagu, realisasi amprah, konsumsi sparepart, dan serapan persentase (%) dapat diakses penuh oleh peran Pengadaan.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................
