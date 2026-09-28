# DOKUMEN UAT CLIENT MOBILE: ADMIN LOGISTIK
## SIMLOG RS NON-MEDIS v2 (FLUTTER CLIENT)

---

### Identitas Peran & Kredensial
* **Peran (Role)**: Admin Logistik (`admin_logistik`)
* **Email Akun**: `adminlogistik@simlogrs.local`
* **Kata Sandi**: `password`
* **Wewenang Khusus di Mobile**:
  - Penanggung jawab alokasi dan pengawasan distribusi komoditas gudang sentral.
  - Otorisator Meja 2 dokumen Amprah Ruangan (`DISETUJUI_GUDANG` / `DITOLAK`).
  - Pengawas sirkulasi aset rumah sakit, pemantauan rak simpan, dan kontrol serapan anggaran logistik.

---

### Skenario 1: Otorisasi Amprah Ruangan (Meja 2 / Persetujuan Logistik Sentral)
* **Kode Kasus Uji**: `UAT-MOB-LOG-01`
* **Tujuan**: Memastikan Admin Logistik dapat mengesahkan permohonan komoditas yang telah disetujui Karu untuk siap dialokasikan ke picking gudang.
* **Langkah-langkah Pengujian**:
  1. Login ke aplikasi menggunakan chip **Admin Logistik** (`adminlogistik@simlogrs.local`).
  2. Buka tab **Approval** (Tab 1 pada bottom bar).
  3. Buka Tab 2 **Amprah Ruangan**.
  4. Cari permohonan amprah yang berstatus `DISETUJUI_KARU` (Menunggu Otorisasi Logistik).
  5. Buka kartu amprah $\rightarrow$ periksa rincian komoditas dan jumlah diminta.
  6. Tekan tombol **Setujui** $\rightarrow$ isi catatan persetujuan $\rightarrow$ tekan **Ya, Setujui**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Permohonan amprah berhasil disahkan dengan status resmi `DISETUJUI_GUDANG`.
  - Dokumen langsung terdisposisi ke antrean *Picking FEFO* petugas gudang.
* **Kriteria Alternatif (Alternate Flow - Penolakan Permintaan)**:
  - Jika stok sentral menipis, tekan tombol **Tolak** $\rightarrow$ masukkan alasan penolakan wajib (misal: *"Stok menipis, prioritaskan ruang rawat inap"*). Status berubah menjadi `DITOLAK` disertai catatan resmi.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 2: Inspeksi Fisik Rak Gudang Sentral & Sebaran Komoditas
* **Kode Kasus Uji**: `UAT-MOB-LOG-02`
* **Tujuan**: Memvalidasi kemampuan inspeksi denah rak, saldo batch aktif, dan status kedaluwarsa secara visual di depan rak.
* **Langkah-langkah Pengujian**:
  1. Pada Beranda, ketuk kartu aksi cepat **Daftar Rak Gudang**.
  2. Gunakan kolom pencarian untuk mencari rak (misal: `RAK A`).
  3. Pilih salah satu rak (misal: *RAK A Utama - Gudang Sentral*).
  4. Amati Tab 1 **Stok Batch Barang**:
     - Periksa nama barang, nomor batch, sisa stok fisik, dan badge status kedaluwarsa (*AMAN*, *MENDEKATI_KADALUWARSA*, *KADALUWARSA*).
  5. Beralih ke Tab 2 **Aset Fisik**:
     - Periksa sarana fisik yang tersimpan di rak tersebut beserta nomor seri dan kondisi (*BAIK* / *RUSAK*).
* **Kriteria Keberhasilan (Primary Path)**:
  - Layar `DaftarRakScreen` dan `DetailRakScreen` memuat seluruh struktur rak secara real-time.
  - Jumlah fisik barang dan aset di dalam rak sesuai dengan saldo buku kartu stok.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 3: Pemantauan Kadaluwarsa FEFO & Mutasi Kartu Stok
* **Kode Kasus Uji**: `UAT-MOB-LOG-03`
* **Tujuan**: Memastikan Admin Logistik dapat mengawasi peringatan batch kritis dan pergerakan stok barang.
* **Langkah-langkah Pengujian**:
  1. Pada Beranda bagian bawah, ketuk kartu mini **Monitoring FEFO**.
  2. Periksa 4 indikator kartu metrik: *Kadaluwarsa*, *Kritis 30 Hari*, *Peringatan 90 Hari*, dan *Batas ROP*.
  3. Gunakan filter status kategori atau pencarian nama komoditas.
  4. Kembali ke Beranda $\rightarrow$ ketuk kartu mini **Buku Mutasi**.
  5. Filter jenis mutasi: `MASUK`, `KELUAR`, atau `PENYESUAIAN`.
* **Kriteria Keberhasilan (Primary Path)**:
  - Data FEFO menampilkan urutan prioritas batch yang harus dikeluarkan terlebih dahulu.
  - Buku mutasi merekam saldo awal, jumlah mutasi, saldo akhir, dan referensi dokumen transaksi (PO, SPPB, atau Opname).
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 4: Screening Pagu & Realisasi Pengeluaran Logistik Ruangan
* **Kode Kasus Uji**: `UAT-MOB-LOG-04`
* **Tujuan**: Memvalidasi akses Admin Logistik terhadap kontrol pagu serapan belanja unit rumah sakit.
* **Langkah-langkah Pengujian**:
  1. Di Beranda, ketuk banner **Pagu & Realisasi Anggaran RS**.
  2. Periksa rekapitulasi beban *Amprah Ruangan* dan *Sparepart IPSRS*.
  3. Pilih unit kerja (misal: `Instalasi Rawat Inap Teratai`).
  4. Ketuk **Rincian Bukti Fisik**.
  5. Amati riwayat nomor SPPB yang telah dikirim ke unit tersebut beserta total nominal rupiahnya.
* **Kriteria Keberhasilan (Primary Path)**:
  - Layar terbuka mulus tanpa pesan penolakan 403.
  - Nilai nominal pengeluaran SPPB dihitung akurat berdasarkan `jumlah_dikirim * harga_satuan_batch`.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................
