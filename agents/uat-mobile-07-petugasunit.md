# DOKUMEN UAT CLIENT MOBILE: PETUGAS / STAF RUANGAN
## SIMLOG RS NON-MEDIS v2 (FLUTTER CLIENT)

---

### Identitas Peran & Kredensial
* **Peran (Role)**: Petugas / Staf Ruangan Pelayanan (`petugas_unit`)
* **Email Akun**: `petugasunit@simlogrs.local`
* **Unit Kerja**: Instalasi Gawat Darurat (IGD)
* **Kata Sandi**: `password`
* **Wewenang Khusus di Mobile**:
  - Penginput permohonan amprah barang habis pakai (ATK/ART/Reagen) ruangan.
  - Penerima fisik distribusi barang dari gudang sentral (konfirmasi RCV via SPPB).
  - Pengaju peminjaman sarana fisik dari ruangan lain saat terjadi lonjakan pasien.
  - Pelapor kerusakan fasilitas sarana di unit kerjanya.

---

### Skenario 1: Pengajuan Permintaan Amprah Rutin Komoditas Ruangan
* **Kode Kasus Uji**: `UAT-MOB-STFU-01`
* **Tujuan**: Memastikan staf ruangan dapat memilih komoditas dari katalog gudang dan mengajukan amprah secara digital.
* **Langkah-langkah Pengujian**:
  1. Login ke aplikasi menggunakan akun `petugasunit@simlogrs.local`.
  2. Di Beranda, ketuk kartu aksi cepat **Amprah Ruangan**.
  3. Tekan tombol floating **Ajukan Amprah Baru** (`+`).
  4. Tekan **Pilih Barang dari Katalog**.
  5. Pilih komoditas barang (misal: *Sarung Tangan Non-Steril*).
  6. Tambahkan kuantitas permintaan (misal: `5 Box`).
  7. Tentukan Urgensi: `REGULER` atau `CITO`.
  8. Masukkan catatan: *"Kebutuhan tindakan darurat shift malam"*.
  9. Tekan tombol **Kirim Permintaan Amprah**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Formulir memvalidasi ketersediaan stok fisik gudang sebelum submit.
  - Permintaan amprah berhasil diajukan dengan nomor kode resmi `REQ-YYYYMM-XXX` berstatus `DIAJUKAN`.
  - Dokumen langsung terdisposisi ke antrean otorisasi Karu IGD.
* **Kriteria Pengecualian (Stok Kosong)**:
  - Jika barang yang dipilih memiliki stok fisik 0 di gudang, sistem memblokir submit dengan snackbar: *"Komoditas di gudang saat ini kosong (0)"*.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 2: Konfirmasi Penerimaan Fisik Barang Distribusi (RCV dari SPPB)
* **Kode Kasus Uji**: `UAT-MOB-STFU-02`
* **Tujuan**: Memvalidasi penerimaan fisik barang yang dikirim petugas gudang ke ruangan IGD.
* **Langkah-langkah Pengujian**:
  1. Buka modul **Amprah Ruangan** $\rightarrow$ buka daftar **Pengiriman Menuju Ruangan (SPPB Inbound)**.
  2. Cari nomor SPPB berstatus `DIKIRIM`.
  3. Periksa kesesuaian fisik barang yang diantar petugas gudang dengan rincian di layar gawai.
  4. Tekan tombol hijau **Konfirmasi Terima Barang**.
  5. Masukkan catatan verifikasi penerima: *"Barang diterima lengkap dalam kondisi baik"*.
  6. Tekan **Ya, Konfirmasi Penerimaan**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Status SPPB diperbarui menjadi `DITERIMA`.
  - Dokumen serah terima `RCV-YYYYMM-XXX` otomatis diterbitkan dan transaksi amprah induk dinyatakan `SELESAI`.
* **Kriteria Pengecualian (Isolasi Unit)**:
  - Staf IGD dicegah mengonfirmasi penerimaan barang untuk SPPB yang ditujukan ke ruangan lain (HTTP 403 Forbidden).
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 3: Pengajuan Peminjaman Sarana/Aset dari Ruangan Lain
* **Kode Kasus Uji**: `UAT-MOB-STFU-03`
* **Tujuan**: Meminjam alat sarana pendukung dari ruangan lain saat terjadi lonjakan pasien di IGD.
* **Langkah-langkah Pengujian**:
  1. Pada Beranda, ketuk kartu aksi **Sirkulasi Aset**.
  2. Tekan tombol floating **Ajukan Pinjam Aset** (`+`).
  3. Tekan **Pilih Aset Tersedia**.
  4. Pilih sarana yang berstatus `TERSEDIA` dan berlokasi di ruangan lain (misal: *Syringe Pump* dari Rawat Inap).
  5. Pilih Tanggal Pinjam dan Tanggal Kembali Rencana menggunakan DatePicker.
  6. Masukkan Keperluan: *"Pasien kritis rujukan laka lantas"*.
  7. Tekan tombol **Kirim Pengajuan Peminjaman**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Dokumen peminjaman berhasil terbit dengan status `DIAJUKAN`.
  - Permintaan otomatis masuk ke antrean otorisasi Karu ruangan pemilik aset.
* **Kriteria Pengecualian (Validasi Ruangan Sendiri)**:
  - Sistem melarang meminjam aset yang tercatat di ruangan sendiri (dicegah oleh katalog filter).
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 4: Pengujian Masking Data Finansial pada Katalog Barang
* **Kode Kasus Uji**: `UAT-MOB-STFU-04`
* **Tujuan**: Memastikan data sensitif harga wholesale/beli tidak bocor ke staf operasional ruangan.
* **Langkah-langkah Pengujian**:
  1. Buka katalog master barang di aplikasi.
  2. Buka salah satu rincian komoditas barang.
  3. Periksa informasi harga beli dan daftar stok batch.
* **Kriteria Keberhasilan (Data Protection Guard)**:
  - Nilai `harga_beli_terakhir` dan `harga_satuan` pada batch tertulis `Rp 0` (di-masking aman).
  - Staf ruangan hanya melihat `harga_estimasi` sebagai panduan perkiraan anggaran.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................
