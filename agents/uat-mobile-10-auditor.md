# DOKUMEN UAT CLIENT MOBILE: AUDITOR INTERNAL (SPI)
## SIMLOG RS NON-MEDIS v2 (FLUTTER CLIENT)

---

### Identitas Peran & Kredensial
* **Peran (Role)**: Auditor Internal Satuan Pemeriksa Intern (`auditor`)
* **Email Akun**: `auditor@simlogrs.local`
* **Kata Sandi**: `password`
* **Wewenang Khusus di Mobile**:
  - Pemeriksa kepatuhan tata kelola logistik rumah sakit (*Governance, Risk & Compliance*).
  - Penyelidik forensik digital audit trail mutasi data (*Snapshot Diff Before vs After*).
  - Pendeteksi anomali transaksi pengadaan (PO tanpa PR, keterlambatan vendor, selisih RCV).
  - Penerbit resmi Temuan Audit CAPA ke unit atau gudang terperiksa.
  - Penilai formal evaluasi penutupan temuan perbaikan (*CAPA Closing Authority*).

---

### Skenario 1: Forensik Digital Audit Trail (Snapshot Diff Nilai Sebelum vs Sesudah)
* **Kode Kasus Uji**: `UAT-MOB-AUD-01`
* **Tujuan**: Memastikan Auditor dapat menelusuri riwayat perubahan data sensitif hingga tingkat atribut lama vs baru.
* **Langkah-langkah Pengujian**:
  1. Login ke aplikasi menggunakan chip **Auditor SPI** (`auditor@simlogrs.local`).
  2. Di Beranda, ketuk banner ungu **Pusat Audit Internal SPI & CAPA**.
  3. Buka Tab 1 **Audit Trail**.
  4. Cari catatan log yang bertipe aksi `UBAH`.
  5. Ketuk kartu log untuk membuka modal **Inspeksi Diff Perubahan Data**.
  6. Periksa perbandingan dua kolom:
     - **Data Sebelum Perubahan (Nilai Lama)**.
     - **Data Sesudah Perubahan (Nilai Baru)**.
     - Metadata pelaku: Nama Pegawai, Peran, Alamat IP, dan Waktu Eksekusi.
* **Kriteria Keberhasilan (Primary Path)**:
  - Seluruh log mutasi termuat lengkap tanpa error 403.
  - Modal forensik menampilkan struktur perubahan nilai secara presisi dalam format JSON/Key-Value yang mudah dibaca.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 2: Deteksi Kepatuhan Pengadaan & Penerbitan CAPA dari Anomali PO
* **Kode Kasus Uji**: `UAT-MOB-AUD-02`
* **Tujuan**: Menguji deteksi otomatis transaksi pengadaan yang melanggar SOP dan penerbitan investigasi CAPA seketika.
* **Langkah-langkah Pengujian**:
  1. Pada modul Audit SPI Hub, buka Tab 2 **Kepatuhan PO**.
  2. Gunakan filter chip: pilih `Anomali`.
  3. Pilih transaksi yang memiliki tag merah `TANPA_PR` atau `TERLAMBAT`.
  4. Periksa rincian nilai transaksi dan nama vendor rekanan.
  5. Tekan tombol merah **Terbitkan Temuan CAPA**.
  6. Pada formulir yang muncul:
     - Tentukan Tingkat Risiko: `Mayor`.
     - Tentukan Batas Waktu Tindakan Perbaikan (Due Date).
     - Periksa uraian ringkasan temuan otomatis.
  7. Tekan tombol **Daftarkan Temuan ke Register CAPA**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Dokumen temuan investigasi resmi berhasil diterbitkan dengan format nomor kode `AUD-YYYYMM-XXX` (HTTP 201).
  - Status anomali langsung terdaftar ke sistem monitoring tindak lanjut auditee berstatus `In Progress`.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 3: Registrasi Temuan Audit Baru Mandiri (Form Lengkap Selaras Web)
* **Kode Kasus Uji**: `UAT-MOB-AUD-03`
* **Tujuan**: Memvalidasi formulir penerbitan temuan audit hasil uji petik fisik mandiri di lapangan (selaras 100% dengan formulir web).
* **Langkah-langkah Pengujian**:
  1. Buka Tab 4 **Temuan & CAPA**.
  2. Tekan tombol floating **Temuan Baru** (`+`).
  3. Pada formulir `_FormTerbitkanTemuanSheet`:
     - Masukkan **Objek Pemeriksaan Audit**: *"Gudang Logistik Sentral & Depo Farmasi"*.
     - Pilih **Tingkat Risiko**: `Mayor (Risiko Kritis / Keuangan)`.
     - Pilih **Tanggal Audit**: Tetapkan tanggal hari ini via DatePicker.
     - Pilih **Batas Waktu (Due Date)**: Tetapkan 30 hari ke depan via DatePicker.
     - Pilih **Unit Terperiksa (Opsional)** dari dropdown (misal: *Instalasi Farmasi*).
     - Pilih **Gudang Terperiksa (Opsional)** dari dropdown (misal: *Gudang Sentral*).
     - Masukkan **Uraian Ringkasan Temuan Ketidaksesuaian**: *"Uji petik fisik menemukan selisih pencatatan tanggal kedaluwarsa antara sistem dan fisik di rak"*.
  4. Tekan tombol **Daftarkan Temuan ke SPI**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Dokumen temuan audit berhasil terdaftar dengan nomor kode `AUD-YYYYMM-XXX` (HTTP 201).
  - Kartu temuan pada register CAPA menampilkan nama objek, label risiko merah Mayor, tanggal jatuh tempo, serta lokasi unit/gudang terperiksa secara terpisah dan presisi.
* **Kriteria Pengecualian (Validasi Tanggal)**:
  - Jika tanggal due date dipilih lebih awal dari tanggal audit, sistem memblokir submit dengan snackbar: *"Batas waktu (due date) tidak boleh mendahului tanggal audit"*.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 4: Evaluasi Penutupan Temuan (Closing CAPA: Closed / In Progress)
* **Kode Kasus Uji**: `UAT-MOB-AUD-04`
* **Tujuan**: Memastikan Auditor SPI memiliki wewenang mengevaluasi bukti perbaikan auditee dan menutup temuan secara formal.
* **Langkah-langkah Pengujian**:
  1. Buka Tab 4 **Temuan & CAPA**.
  2. Filter status menggunakan dropdown: pilih `In Review`.
  3. Buka salah satu temuan yang telah dikirimi tindak lanjut perbaikan oleh unit terperiksa.
  4. Telaah analisis akar masalah (*Root Cause*) dan tindakan korektif yang diunggah auditee.
  5. Gulir ke bagian **Evaluasi Closing Auditor SPI**:
     - Pilih Hasil Evaluasi: `Closed (Puas & Masalah Selesai)`.
     - Masukkan Catatan Evaluasi: *"Tindakan perbaikan dan revisi SOP telah diverifikasi lengkap dan valid"*.
  6. Tekan tombol **Simpan Evaluasi Auditor**.
* **Kriteria Keberhasilan (Primary Path)**:
  - Status temuan resmi berubah menjadi `Closed`.
  - Nama Auditor tercatat permanen sebagai pejabat penutup (*evaluator*) di riwayat temuan.
  - Tingkat penyelesaian temuan (*Closing Rate %*) pada metrik ringkasan otomatis meningkat.
* **Kriteria Alternatif (Revisi / In Progress)**:
  - Jika bukti perbaikan auditee belum memadai, auditor memilih opsi `In Progress (Tolak / Perlu Perbaikan Lanjut)` disertai catatan kekurangan. Status temuan kembali menjadi `In Progress` agar auditee melakukan revisi.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................
