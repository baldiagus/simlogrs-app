# Perapian Kartu FEFO dan Stock Opname

## Perubahan

- FEFO: pisahkan batch/status, nama barang, kategori, gudang, rak, dan kedaluwarsa. Stok tersedia serta nilai persediaan ditampilkan terpisah dan responsif.
- Ringkasan metrik FEFO memakai dua kolom pada ruang sempit dan empat kolom pada ruang lebar; label tidak dipotong satu baris.
- Stock Opname: tanggal, penginisiasi, dan catatan dipisahkan; catatan tidak italic. Total item dan jumlah terhitung tidak digabung menjadi kalimat padat.
- Sesi tanpa hasil hitung menampilkan “Belum ada hasil hitung”, bukan klaim cocok. Hasil nol selisih pada perhitungan parsial diberi konteks item terhitung.
- Tombol Inisiasi Opname berada di area aksi bawah dengan SafeArea di luar daftar, bukan floating overlay. Permission tetap mengikuti aturan sebelumnya.
- Tombol Hitung Fisik memiliki tinggi minimum 48 dp; navigasi dan refresh dipertahankan.
- Tidak menambahkan modal, dependensi, endpoint, atau kewenangan baru.

## Verifikasi yang Dijalankan

- 6 pengujian layout FEFO lulus: 360×800, 402×817, 1280×800; skala teks 1× dan 2×, dengan metadata panjang.
- 6 pengujian layout opname lulus pada viewport dan skala yang sama; sesi belum dihitung tidak ditampilkan sebagai cocok.
- 4 pengujian akses inisiasi lulus: petugas gudang dan kepala gudang melihat tombol; petugas unit dan auditor tidak.
- Flutter analyze pada dua file layar: No issues found.

## Batas Verifikasi

Pengujian di atas merender widget Flutter dengan data fixture, bukan transaksi backend nyata. Pemeriksaan visual dengan font produksi pada browser/perangkat, fokus keyboard, kontras, reduced motion, serta seluruh kondisi error/data sebagian belum dilakukan. Gate visual frontend-design-direction belum dinyatakan lulus. Tidak ada klaim hasil screenshot produksi atau keberhasilan transaksi backend.
