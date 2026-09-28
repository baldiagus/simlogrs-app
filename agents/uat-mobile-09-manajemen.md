# DOKUMEN UAT CLIENT MOBILE: MANAJEMEN DIREKSI
## SIMLOG RS NON-MEDIS v2 (FLUTTER CLIENT)

---

### Identitas Peran & Kredensial
* **Peran (Role)**: Manajemen Direksi Rumah Sakit (`manajemen`)
* **Email Akun**: `manajemen@simlogrs.local`
* **Kata Sandi**: `password`
* **Wewenang Khusus di Mobile**:
  - Pengawas eksekutif strategis (*Executive Monitoring & Governance*).
  - Pemantau realisasi anggaran logistik ruangan dan pemakaian suku cadang IPSRS.
  - Pengawas risiko temuan audit internal SPI dan laju penutupan tindak lanjut (*CAPA Closing Rate*).
  - Mode pelacakan dokumen (*Read-Only Tracking*) tanpa tombol intervensi teknis lapangan.

---

### Skenario 1: Monitoring Metrik Eksekutif Makro & Serapan Pagu Belanja
* **Kode Kasus Uji**: `UAT-MOB-MGT-01`
* **Tujuan**: Memastikan Direksi dapat memantau serapan anggaran dan beban operasional rumah sakit secara komprehensif.
* **Langkah-langkah Pengujian**:
  1. Login ke aplikasi menggunakan chip **Manajemen** (`manajemen@simlogrs.local`).
  2. Di Beranda, perhatikan judul aksi: *Aksi Eksekutif Direksi*.
  3. Ketuk banner toska **Pagu & Realisasi Anggaran RS**.
  4. Amati kartu KPI makro:
     - Total Pengeluaran Amprah Unit.
     - Total Konsumsi Sparepart IPSRS.
  5. Pada Tab 1 **Pengeluaran Ruangan**, amati unit-unit dengan serapan anggaran tertinggi.
  6. Pilih salah satu unit yang mendekati batas pagu $\rightarrow$ ketuk **Rincian Bukti Fisik**.
  7. Beralih ke Tab 2 **Suku Cadang IPSRS** $\rightarrow$ amati *Top 5 Aset Penyerap Biaya Pemeliharaan*.
* **Kriteria Keberhasilan (Primary Path)**:
  - Seluruh indikator keuangan terisi angka riil dari database (Zero Dummy Data).
  - Direksi dapat mengidentifikasi aset yang mengalami pembengkakan biaya pemeliharaan (*cost driver*).
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 2: Pemantauan Risiko Temuan Audit & Status Closing CAPA
* **Kode Kasus Uji**: `UAT-MOB-MGT-02`
* **Tujuan**: Memvalidasi visibilitas Direksi terhadap risiko operasional dan efektivitas tindak lanjut SPI.
* **Langkah-langkah Pengujian**:
  1. Pada Beranda, ketuk banner ungu **Pusat Audit Internal SPI & CAPA**.
  2. Amati ringkasan metrik: *Total Temuan*, *Closed*, *In Progress*, *In Review*, dan *Closing Rate %*.
  3. Beralih ke Tab 4 **Temuan & CAPA**.
  4. Filter temuan dengan tingkat risiko: `Mayor`.
  5. Buka kartu temuan audit risiko Mayor $\rightarrow$ telaah uraian temuan dan bukti tindak lanjut auditee.
* **Kriteria Keberhasilan (Primary Path)**:
  - Data register CAPA memuat status mutakhir, auditor yang menerbitkan, dan evaluasi closing.
  - Direksi mendapatkan informasi akurat mengenai kepatuhan tata kelola tanpa hambatan akses.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 3: Read-Only Tracking Pesanan Pembelian (PO) Vendor
* **Kode Kasus Uji**: `UAT-MOB-MGT-03`
* **Tujuan**: Memastikan Direksi dapat melacak pengadaan barang tanpa risiko mengubah data secara tidak sengaja.
* **Langkah-langkah Pengujian**:
  1. Buka tab **Approval** pada bottom bar (Tab 1).
  2. Buka Tab 2 **Pesanan (PO)**.
  3. Cari PO tertentu menggunakan kolom pencarian nomor PO atau nama vendor.
  4. Buka salah satu kartu PO.
  5. Periksa rincian item barang, kuantitas pesanan, syarat pembayaran, dan total nominal biaya PO.
* **Kriteria Keberhasilan (Read-Only Guard Path)**:
  - Seluruh rincian dokumen PO tampil lengkap dan transparan.
  - Tombol aksi penerbitan PO atau tombol update status kirim vendor **TIDAK MUNCUL** pada akun Direksi (terkunci dalam mode *Read-Only*).
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 4: Pemantauan Seluruh SPK Perbaikan Rumah Sakit (Pantau SPK)
* **Kode Kasus Uji**: `UAT-MOB-MGT-04`
* **Tujuan**: Memvalidasi pemantauan kelaikan fasilitas medis dan kecepatan respon teknisi IPSRS.
* **Langkah-langkah Pengujian**:
  1. Di Beranda, ketuk kartu aksi cepat **Pantau SPK** (*Semua SPK RS (Lihat)*).
  2. Amati daftar SPK dari seluruh unit rumah sakit.
  3. Filter berdasarkan status: `DITUGASKAN`, `DIPROSES`, atau `SELESAI`.
  4. Buka salah satu SPK untuk melihat diagnosa dan lembar kerja teknisi.
* **Kriteria Keberhasilan (Primary Path)**:
  - Direksi dapat memantau beban kerja teknisi lintas instalasi secara menyeluruh tanpa wewenang mengubah lembar kerja teknis.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................
