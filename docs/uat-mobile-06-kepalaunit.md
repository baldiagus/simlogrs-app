# DOKUMEN UAT CLIENT MOBILE: KEPALA RUANGAN (KARU)
## SIMLOG RS NON-MEDIS v2 (FLUTTER CLIENT)

---

### Identitas Peran & Kredensial
* **Peran (Role)**: Kepala Ruangan / Kepala Unit Pelayanan (`kepala_unit`)
* **Email Akun**: `kepalaunit@simlogrs.local`
* **Unit Kerja**: Instalasi Gawat Darurat (IGD)
* **Kata Sandi**: `password`
* **Wewenang Khusus di Mobile**:
  - Otorisator Meja 1 permohonan komoditas amprah ruangan staf IGD (`DISETUJUI_KARU`).
  - Otorisator izin peminjaman alat sarana medis/non-medis milik ruangan IGD.
  - Penanggung jawab pengembalian fisik dan perpanjangan masa pinjam sarana.
  - Pelapor resmi kerusakan sarana fasilitas ruangan ke posko teknisi IPSRS.

---

### Skenario 1: Otorisasi Permintaan Amprah Ruangan (Approval Meja 1)
* **Kode Kasus Uji**: `UAT-MOB-KARU-01`
* **Tujuan**: Memastikan Karu dapat memeriksa kewajaran kebutuhan barang rutin yang diajukan staf sebelum diteruskan ke logistik sentral.
* **Langkah-langkah Pengujian**:
  1. Login ke aplikasi menggunakan chip **Karu IGD** (`kepalaunit@simlogrs.local`).
  2. Buka tab **Approval** pada bottom bar (Tab 1).
  3. Buka Tab 2 **Amprah Ruangan**.
  4. Buka permohonan amprah berstatus `DIAJUKAN` yang berasal dari staf IGD.
  5. Telaah rincian kuantitas barang yang diminta.
  6. Tekan tombol **Setujui** $\rightarrow$ isi catatan persetujuan $\rightarrow$ tekan **Ya, Setujui**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Dokumen berhasil disahkan oleh Karu dengan status `DISETUJUI_KARU` (HTTP 200).
  - Dokumen otomatis terdisposisi ke antrean Meja 2 Admin Logistik Sentral.
* **Kriteria Pengecualian (Security Guard)**:
  - Karu dicegah mengesahkan permohonan amprah yang diajukan oleh ruangan/unit lain (HTTP 403 Forbidden).
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 2: Otorisasi Izin Peminjaman Sarana/Aset Unit Kerja
* **Kode Kasus Uji**: `UAT-MOB-KARU-02`
* **Tujuan**: Menguji pemberian izin peminjaman alat medis/sarana milik ruangan IGD oleh ruangan pelayanan lain.
* **Langkah-langkah Pengujian**:
  1. Pada Beranda, ketuk kartu aksi cepat **Sirkulasi Aset**.
  2. Beralih ke Tab 2 **Otorisasi**.
  3. Cari permohonan pinjam aset berstatus `DIAJUKAN` di mana unit penyedia adalah `Instalasi Gawat Darurat`.
  4. Periksa nama sarana aset, unit peminjam (misal: *ICU*), dan keperluan peminjaman.
  5. Tekan tombol **Setujui Izin Pinjam**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Status peminjaman berubah menjadi `DISETUJUI` (HTTP 200).
  - Peminjam mendapatkan notifikasi bahwa alat siap diserahterimakan secara fisik.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 3: Perpanjangan Masa Pinjam & Pengembalian Fisik Aset
* **Kode Kasus Uji**: `UAT-MOB-KARU-03`
* **Tujuan**: Memastikan Karu dapat mengelola masa pinjam sarana yang sedang digunakan di ruangannya.
* **Langkah-langkah Pengujian**:
  1. Buka modul **Sirkulasi Aset** $\rightarrow$ Tab 1 **Pinjaman Saya**.
  2. Pilih transaksi aset yang sedang berstatus `DIPINJAM`.
  3. Tekan tombol **Perpanjang**.
  4. Pilih tanggal kembali baru dan masukkan alasan perpanjangan (misal: *"Tindakan darurat pasien masih berlangsung"*).
  5. Tekan tombol **Konfirmasi Perpanjang Peminjaman**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Tanggal rencana kembali berhasil diperbarui dan status perpanjangan tercatat permanen.
* **Kriteria Alternatif (Pengembalian Fisik)**:
  - Jika sarana telah selesai digunakan, tekan tombol **Kembalikan Fisik** $\rightarrow$ pilih kondisi fisik (*BAIK* / *RUSAK_RINGAN*) $\rightarrow$ tekan **Konfirmasi Pengembalian**. Status transaksi berganti menjadi `SELESAI` dan aset kembali `TERSEDIA`.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 4: Pelaporan Cepat Kerusakan Sarana Medis/Ruangan (Lapor Cepat)
* **Kode Kasus Uji**: `UAT-MOB-KARU-04`
* **Tujuan**: Memvalidasi pengiriman laporan kerusakan fasilitas langsung dari gawai mobile dengan bukti foto kamera.
* **Langkah-langkah Pengujian**:
  1. Buka Tab 2 **IPSRS Fieldwork** pada bottom bar.
  2. Tekan tombol floating **Lapor Cepat Kerusakan** (`+`).
  3. Ambil foto bukti kerusakan fisik menggunakan kamera HP.
  4. Pilih aset dari daftar sarana IGD atau pindai stiker QR pada aset.
  5. Tentukan Prioritas: `CITO`, `TINGGI`, atau `SEDANG`.
  6. Masukkan deskripsi masalah: *"Roda brankar macet total dan tuas hidrolik tidak naik"*.
  7. Tekan tombol **Kirim Laporan Servis**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Berkas foto dikompresi otomatis tanpa membebani bandwidth (WebP/JPEG 80%).
  - Tiket kerusakan baru berhasil diterbitkan dengan nomor resmi `MNT-YYYYMM-XXX` berstatus `DILAPORKAN`.
  - Jika prioritas CITO, status aset otomatis berubah menjadi `DALAM_MAINTENANCE` (*Rusak Berat*).
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................
