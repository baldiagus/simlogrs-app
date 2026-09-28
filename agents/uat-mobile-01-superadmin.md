# DOKUMEN UAT CLIENT MOBILE: SUPER ADMINISTRATOR
## SIMLOG RS NON-MEDIS v2 (FLUTTER CLIENT)

---

### Identitas Peran & Kredensial
* **Peran (Role)**: Super Administrator (`super_admin`)
* **Email Akun**: `superadmin@simlogrs.local`
* **Kata Sandi**: `password`
* **Wewenang Khusus di Mobile**:
  - Akses tak terbatas (*unrestricted global viewer & bypass authority*).
  - Berwenang membuka seluruh modul: Approval PR/PO, Sirkulasi Aset, Gudang, IPSRS, Pusat Audit SPI, dan Pagu & Realisasi Anggaran.
  - Memiliki badge penanda *Super Admin* pada bilah navigasi dan profil.

---

### Skenario 1: Verifikasi Akses Global Beranda & Quick Actions
* **Kode Kasus Uji**: `UAT-MOB-ADM-01`
* **Tujuan**: Memastikan Super Admin mendapatkan seluruh pintasan aksi operasional dan banner pemantauan tingkat tinggi.
* **Langkah-langkah Pengujian**:
  1. Buka aplikasi SIMLOG RS mobile.
  2. Pada layar login, ketuk chip **Super Admin** (email otomatis terisi `superadmin@simlogrs.local` dan sandi terisi).
  3. Tekan tombol **Masuk ke Sistem**.
  4. Amati layar Beranda (`HomeScreen`).
  5. Periksa kartu aksi cepat pada `QuickActionGrid`.
* **Kriteria Keberhasilan (Primary Path)**:
  - Berhasil masuk ke Beranda tanpa error.
  - Quick Action Grid menampilkan pintasan lengkap: *Approval Cepat*, *Sirkulasi Aset*, *Daftar Rak Gudang*, *Penerimaan PO*, *Picking FEFO*, dan *Lapor Rusak*.
  - Muncul banner ungu: **Pusat Audit Internal SPI & CAPA** (subjudul: *Audit trail, kepatuhan PO, selisih opname, register temuan*).
  - Muncul banner toska: **Pagu & Realisasi Anggaran RS** (subjudul: *Screening pengeluaran logistik ruangan & suku cadang IPSRS*).
  - Modul **Persediaan & Opname Gudang** (Monitoring FEFO, Buku Mutasi, Stock Opname) tampil aktif di bawah beranda.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 2: Approval Center (Otorisasi PR dan Penerbitan PO)
* **Kode Kasus Uji**: `UAT-MOB-ADM-02`
* **Tujuan**: Menguji kemampuan Super Admin dalam mengesahkan PR dan menerbitkan PO langsung dari gawai mobile.
* **Langkah-langkah Pengujian**:
  1. Ketuk tab **Approval** pada bottom navigation bar (Tab 1).
  2. Pada Tab 1 **Pengadaan (PR)**, pilih salah satu PR berstatus `DIAJUKAN`.
  3. Tekan tombol **Setujui** $\rightarrow$ masukkan catatan opsional $\rightarrow$ tekan **Ya, Setujui**.
  4. Buka kembali PR yang telah disetujui $\rightarrow$ tekan tombol **Terbitkan PO (Pesanan Pembelian)**.
  5. Pada bottom sheet yang muncul:
     - Pilih Rekanan / Vendor Pemasok dari dropdown.
     - Pilih Estimasi Tanggal Kirim dan Syarat Bayar (misal: *TEMPO_30_HARI*).
     - Masukkan harga negosiasi satuan per item barang.
  6. Tekan tombol **Terbitkan PO Sekarang**.
  7. Beralih ke Tab 2 **Pesanan (PO)** pada Approval Center.
* **Kriteria Keberhasilan (Primary Path)**:
  - PR berhasil disetujui dan status berganti menjadi `DISETUJUI` / `DIPROSES`.
  - Formulir PO menghitung total biaya secara atomik tanpa kolisi antar baris item.
  - PO berhasil terbit dengan status `DITERBITKAN` (HTTP 201) dan langsung tercantum di Tab 2 Pesanan PO.
* **Kriteria Pengecualian (Exception Path)**:
  - Jika harga satuan diisi $\le 0$, muncul notifikasi validasi: *"Harga satuan untuk ... wajib lebih dari 0"*.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 3: Pagu & Realisasi Anggaran dan Detail Drilldown
* **Kode Kasus Uji**: `UAT-MOB-ADM-03`
* **Tujuan**: Memastikan Super Admin dapat meninjau realisasi belanja rumah sakit dan rincian transaksi fisik per unit kerja.
* **Langkah-langkah Pengujian**:
  1. Kembali ke Beranda $\rightarrow$ ketuk banner **Pagu & Realisasi Anggaran RS**.
  2. Amati dua kartu metrik makro (*Amprah Ruangan* dan *Sparepart IPSRS*).
  3. Ganti dropdown Tahun Anggaran ke `TA 2026` lalu tarik layar ke bawah (*pull-to-refresh*).
  4. Pada Tab 1 **Pengeluaran Ruangan**, cari salah satu unit (misal: `IGD`).
  5. Tekan tombol **Rincian Bukti Fisik**.
  6. Beralih ke Tab 2 **Suku Cadang IPSRS** $\rightarrow$ amati *Top 5 Aset Penyerap Biaya* dan *Log Konsumsi Suku Cadang Terakhir*.
* **Kriteria Keberhasilan (Primary Path)**:
  - Layar `PaguRealisasiScreen` terbuka tanpa penolakan hak akses.
  - Modal drilldown menampilkan riwayat SPPB distribusi dan log penggantian suku cadang unit terkait.
  - Angka serapan persentase dan progress bar warna status (*Normal*, *Waspada*, *Over-Budget*) tampil akurat.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................

---

### Skenario 4: Pembersihan Sesi Logout & Proteksi Keamanan
* **Kode Kasus Uji**: `UAT-MOB-ADM-04`
* **Tujuan**: Memastikan state cache memori dan token dibersihkan tuntas saat Super Admin logout.
* **Langkah-langkah Pengujian**:
  1. Buka Tab 3 **Profil** $\rightarrow$ periksa informasi email `superadmin@simlogrs.local`.
  2. Tekan tombol **Keluar dari Sistem (Logout)**.
  3. Konfirmasi dialog logout.
  4. Login kembali menggunakan akun peran staf biasa (`petugasunit@simlogrs.local`).
  5. Periksa apakah data approval admin atau log audit tertinggal di memori aplikasi.
* **Kriteria Keberhasilan (Primary Path)**:
  - Aplikasi kembali ke `LoginScreen`.
  - Token Sanctum di `FlutterSecureStorage` terhapus.
  - Seluruh provider data (`dashboardSummaryProvider`, `approvalPendingProvider`, `poListProvider`, `registerTemuanProvider`) di-reset bersih.
* **Hasil Pengujian**: [ &nbsp;&nbsp; ] Lolos &nbsp;&nbsp;&nbsp; [ &nbsp;&nbsp; ] Gagal &nbsp;&nbsp;&nbsp; Catatan: ........................................
