# DOKUMEN UAT CLIENT MOBILE: TEKNISI SARANA IPSRS
## SIMLOG RS NON-MEDIS v2 (FLUTTER CLIENT)

---

### Identitas Peran & Kredensial
* **Peran (Role)**: Teknisi Pemeliharaan Sarana & Prasarana (`teknisi`)
* **Email Akun**: `teknisi@simlogrs.local`
* **Kata Sandi**: `password`
* **Wewenang Khusus di Mobile**:
  - Pelaksana teknis perbaikan sarana fasilitas (*Mobile Fieldwork Technician*).
  - Penerima Surat Perintah Kerja (SPK) perbaikan yang dialokasikan oleh supervisor.
  - Penginput lembar kerja teknisi, jam servis riil, hasil uji kelaikan, dan pemakaian sparepart.
  - Eksekutor jadwal pemeliharaan preventif berkala dan pencatat rekam medis sarana.

---

### Skenario 1: Penerimaan & Peninjauan SPK Perbaikan Aktif di Lapangan
* **Kode Kasus Uji**: `UAT-MOB-TECH-01`
* **Tujuan**: Memastikan teknisi dapat meninjau detail kerusakan fisik sarana langsung di lokasi unit pelapor.
* **Langkah-langkah Pengujian**:
  1. Login ke aplikasi menggunakan chip **Teknisi IPSRS** (`teknisi@simlogrs.local`).
  2. Perhatikan antarmuka khusus: Tab 1 pada bottom bar otomatis menampilkan **Tugas SPK**.
  3. Buka daftar SPK berstatus `DITUGASKAN`.
  4. Buka salah satu SPK $\rightarrow$ telaah rincian kerusakan:
     - Nama aset, nomor seri, dan lokasi ruangan pelapor.
     - Foto fisik kerusakan yang diunggah pelapor.
     - Tingkat urgensi / prioritas (`CITO`, `TINGGI`, `SEDANG`).
* **Kriteria Keberhasilan (Primary Path)**:
  - Seluruh rincian teknis SPK dan foto bukti kerusakan tampil jelas di layar gawai.
  - Teknisi hanya dapat melihat rincian SPK yang ditugaskan kepada dirinya atau mode pengawasan SPK.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 2: Pengisian Lembar Kerja Teknisi & Alokasi Suku Cadang FEFO
* **Kode Kasus Uji**: `UAT-MOB-TECH-02`
* **Tujuan**: Merekam hasil penanganan teknis, jam kerja aktual, dan pemakaian komponen suku cadang IPSRS.
* **Langkah-langkah Pengujian**:
  1. Pada kartu detail SPK, tekan tombol hijau **Isi Lembar Kerja (Pengerjaan)**.
  2. Pada formulir `LembarKerjaScreen`:
     - Tentukan **Jam Mulai** dan **Jam Selesai** menggunakan TimePicker.
     - Masukkan **Diagnosa Kerusakan**: *"Bearing dinamo aus dan kabel power terkelupas"*.
     - Masukkan **Tindakan Perbaikan**: *"Penggantian bearing dan isolasi wiring power"*.
     - Pilih **Hasil Servis**: `BERHASIL`.
     - Centang **Uji Fungsi & Kelaikan Fisik**: *Lolos Uji Kelaikan*.
  3. Tekan tombol **Tambah Suku Cadang / Sparepart**:
     - Pilih suku cadang bertipe `SPAREPART` dari picker.
     - Masukkan kuantitas yang dipasang (misal: `1 Unit`).
  4. Masukkan catatan tambahan: *"Alat telah diuji fungsi 30 menit tanpa kendala"*.
  5. Tekan tombol **Simpan & Selesaikan Lembar Kerja**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Lembar kerja berhasil disimpan (HTTP 201).
  - Stok suku cadang di gudang IPSRS otomatis terpotong berbasis FEFO (*pessimistic lock*).
  - Status SPK otomatis diperbarui menjadi `SELESAI` dan tiket komplain induk ditutup.
* **Kriteria Pengecualian (Validasi Komoditas)**:
  - Jika teknisi mencoba memilih komoditas non-sparepart (misal: ATK), sistem memblokir dengan peringatan: *"Hanya barang bertipe SPAREPART yang dapat digunakan pada lembar kerja"*.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 3: Eksekusi Jadwal Pemeliharaan Preventif Berkala
* **Kode Kasus Uji**: `UAT-MOB-TECH-03`
* **Tujuan**: Memvalidasi konversi jadwal pemeliharaan rutin sarana menjadi SPK aktif di lapangan.
* **Langkah-langkah Pengujian**:
  1. Pada Beranda, ketuk kartu aksi **Jadwal Preventif**.
  2. Filter jadwal pemeliharaan menggunakan chip: `HARI_INI` atau `MENDATANG`.
  3. Pilih jadwal servis berkala yang jatuh tempo.
  4. Tekan tombol **Eksekusi Servis Preventif (Terbitkan SPK)**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Sistem otomatis menerbitkan dokumen SPK baru dengan nomor kode `SPK-YYYYMM-XXX`.
  - Tanggal agenda berikutnya pada jadwal preventif dimajukan otomatis sesuai interval siklus pemeliharaan.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 4: Pindai QR Code untuk Inspeksi Rekam Medis Aset
* **Kode Kasus Uji**: `UAT-MOB-TECH-04`
* **Tujuan**: Memeriksa riwayat pemeliharaan sarana secara instan di depan unit alat medis.
* **Langkah-langkah Pengujian**:
  1. Ketuk ikon **Kamera Scanner QR** di AppBar beranda.
  2. Arahkan kamera ke stiker QR fisik aset.
  3. Amati layar profil detail aset yang terbuka otomatis.
  4. Gulir ke bagian **Riwayat Servis & Lembar Kerja Masa Lalu**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Pemindai mengenali kode QR dalam waktu < 1.5 detik.
  - Riwayat servis memuat tanggal perbaikan sebelumnya, nama teknisi yang menangani, diagnosa, dan riwayat pergantian sparepart masa lalu.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................
