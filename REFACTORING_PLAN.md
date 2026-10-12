# Rencana Refactoring — Kepatuhan Aturan Organisasi Kode Flutter

Diperiksa: 2026-10-12
Total file Dart: 207 | ≤300 baris: 167 (81%) | 301–500: 34 | >500: 6

---

## Prioritas 1: Wajib Ditinjau (>500 baris)

| # | File | Baris | Rencana Pemisahan |
|---|---|---|---|
| 1 | `lib/features/pengadaan/presentation/screens/pengadaan_hub_screen.dart` | 695 | Pecah isi masing-masing tab ke widget file terpisah per tab. |
| 2 | `lib/features/aset/presentation/screens/sirkulasi_aset_hub_screen.dart` | 610 | Pindahkan kartu peminjaman dan kartu otorisasi ke widget terpisah. Satukan pemeriksaan izin. |
| 3 | `lib/features/aset/presentation/screens/aset_detail_screen.dart` | 598 | Pindahkan sisa section (riwayat, aksi) ke widget tambahan di luar `aset_detail_sections.dart`. |
| 4 | `lib/features/aset/presentation/widgets/modal_pengalihan_aset_sheet.dart` | 554 | Pisahkan Tahap 1 dan Tahap 2 ke widget terpisah. |
| 5 | `lib/features/audit/presentation/widgets/sheets/form_terbitkan_temuan_sheet.dart` | 548 | Pisahkan bagian form field ke widget terpisah per section. |
| 6 | `lib/features/aset/presentation/screens/pengalihan_hub_screen.dart` | 535 | Pindahkan `_buildPengalihanCard` ke file `pengalihan_card_item.dart`. Satukan perhitungan izin otorisasi dan pembuatan. |

---

## Prioritas 2: Evaluasi (301–500 baris)

| # | File | Baris | Evaluasi |
|---|---|---|---|
| 7 | `lib/features/aset/presentation/screens/form_peminjaman_aset_screen.dart` | 477 | Evaluasi bagian form yang bisa dijadikan widget terpisah. |
| 8 | `lib/features/maintenance/presentation/screens/detail_tiket_screen.dart` | 448 | Evaluasi pemisahan section riwayat log dan aksi tombol. |
| 9 | `lib/features/distribusi/presentation/screens/form_pengajuan_amprah_screen.dart` | 446 | Evaluasi pemisahan picker dan keranjang barang. |
| 10 | `lib/features/maintenance/presentation/screens/lembar_kerja_screen.dart` | 440 | Evaluasi pemisahan form sparepart dan log diagnosa. |
| 11 | `lib/features/aset/presentation/screens/histori_sirkulasi_aset_screen.dart` | 425 | Evaluasi pemisahan timeline dan kartu riwayat. |
| 12 | `lib/features/aset/presentation/widgets/modal_pengalihan_barang_sheet.dart` | 422 | Evaluasi pemisahan section form. |
| 13 | `lib/features/master/presentation/widgets/detail_barang_sections.dart` | 421 | Multi-widget dalam satu file, wajar. Evaluasi jika keterbacaan menurun. |
| 14 | `lib/features/profile/presentation/screens/profile_screen.dart` | 420 | Evaluasi pemisahan section profil dan aksi. |
| 15 | `lib/features/maintenance/presentation/screens/ipsrs_hub_screen.dart` | 420 | Evaluasi pemisahan tab content. |
| 16 | `lib/features/aset/presentation/screens/histori_pengalihan_aset_screen.dart` | 398 | Evaluasi pemisahan timeline card. |
| 17 | `lib/features/distribusi/presentation/screens/detail_amprah_screen.dart` | 392 | Evaluasi pemisahan item list dan aksi. |
| 18 | `lib/features/master/presentation/screens/detail_barang_screen.dart` | 388 | Evaluasi pemisahan tab dan section. |
| 19 | `lib/features/aset/presentation/widgets/aset_detail_sections.dart` | 384 | Multi-widget privat, wajar. Evaluasi jika file terus bertambah. |
| 20 | `lib/features/pengadaan/presentation/screens/riwayat_pr_screen.dart` | 383 | Evaluasi pemisahan filter dan list. |
| 21 | `lib/features/approval/presentation/screens/approval_center_screen.dart` | 382 | Evaluasi pemisahan tab content. |
| 22 | `lib/features/maintenance/presentation/screens/spk_detail_screen.dart` | 378 | Evaluasi pemisahan section detail dan aksi. |
| 23 | `lib/features/pengadaan/presentation/screens/form_pengajuan_pr_screen.dart` | 376 | Evaluasi pemisahan keranjang dan form. |
| 24 | `lib/features/gudang/presentation/screens/form_penerimaan_po_screen.dart` | 376 | Evaluasi pemisahan item draft dan summary. |
| 25 | `lib/features/maintenance/presentation/screens/spk_list_screen.dart` | 375 | Evaluasi pemisahan filter dan kartu SPK. |
| 26 | `lib/features/auth/presentation/screens/login_screen.dart` | 372 | Evaluasi pemisahan form login dan preset chips. |
| 27 | `lib/features/maintenance/presentation/screens/lapor_cepat_screen.dart` | 370 | Evaluasi pemisahan form foto dan deskripsi. |
| 28 | `lib/features/pengadaan/presentation/widgets/terbitkan_po_sheet.dart` | 369 | Evaluasi pemisahan summary dan form harga. |
| 29 | `lib/features/dashboard/presentation/screens/all_activities_screen.dart` | 357 | Evaluasi pemisahan filter dan list item. |
| 30 | `lib/features/distribusi/presentation/screens/amprah_hub_screen.dart` | 346 | Evaluasi pemisahan tab content. |
| 31 | `lib/features/approval/presentation/widgets/approval_card.dart` | 345 | Evaluasi pemisahan header dan action section. |
| 32 | `lib/features/maintenance/presentation/widgets/disposisi_spk_sheet.dart` | 344 | Evaluasi pemisahan form disposisi. |
| 33 | `lib/features/dashboard/presentation/widgets/live_activity_feed.dart` | 331 | Evaluasi pemisahan tile item. |
| 34 | `lib/features/master/presentation/screens/register_aset_screen.dart` | 316 | Evaluasi pemisahan filter dan list. |
| 35 | `lib/features/maintenance/presentation/widgets/rekam_medis_tabs.dart` | 314 | Evaluasi pemisahan tab content. |
| 36 | `lib/features/gudang/presentation/screens/otorisasi_penyesuaian_screen.dart` | 311 | Evaluasi pemisahan list dan detail modal. |
| 37 | `lib/features/gudang/presentation/screens/inbound_po_list_screen.dart` | 309 | Evaluasi pemisahan filter dan kartu PO. |
| 38 | `lib/features/aset/presentation/screens/qr_scanner_screen.dart` | 309 | Evaluasi pemisahan overlay dan aksi scan. |
| 39 | `lib/features/maintenance/presentation/widgets/form_tambah_jadwal_sheet.dart` | 305 | Evaluasi pemisahan picker dan form. |
| 40 | `lib/features/audit/presentation/widgets/tabs/temuan_capa_tab.dart` | 301 | Batas bawah; evaluasi hanya jika bertambah. |

---

## Prioritas 3: Pola yang Perlu Diperhatikan

- [ ] **Duplikasi logika izin otorisasi** di `pengalihan_hub_screen.dart` dan `sirkulasi_aset_hub_screen.dart` — perhitungan `isApproverRole`/`canApprove` diulang di `initState` dan `build`.
- [ ] **Pola boilerplate aksi notifier** di `pengalihan_provider.dart`, `peminjaman_provider.dart`, `aset_provider.dart` — try/catch/invalidate diulang per method.
- [ ] **`catch (_) {}` kosong** di `security_device_service.dart:17` dan `app_formatters.dart:30` — wajar (fallback aman); pastikan tidak ada yang baru ditambahkan tanpa alasan.
- [ ] **Commit dokumen aturan** ke repo sebagai `docs/flutter-code-rules.md` atau di `AGENTS.md` agar menjadi acuan review.

---

## Catatan

- Jangan memecah file hanya untuk memenuhi batas baris jika pemisahan menurunkan keterbacaan.
- Prioritaskan correctness dan arsitektur di atas target ukuran file.
- Setiap refactoring harus diverifikasi dengan `flutter analyze` dan test suite terkait.
- File model dan repository yang memakai `Map<String, dynamic>` untuk JSON parsing adalah pola standar Dart — bukan pelanggaran.
