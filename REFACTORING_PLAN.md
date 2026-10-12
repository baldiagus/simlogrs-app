# Master Checklist & Rencana Refactoring — Kepatuhan Kode Flutter

Dokumen ini disusun berdasarkan aturan di `FLUTTER_CODE_RULES.md`.
Status inventaris per 2026-10-12:
- **Total file Dart di `lib/`**: 207 file
- **Memenuhi target (≤300 baris)**: 167 file (80.7%)
- **Mendekati batas (250–300 baris)**: 19 file `lib/` + 2 file `test/`
- **Wajib dievaluasi (301–500 baris)**: 34 file `lib/` + 1 file `test/`
- **Wajib direfaktor (>500 baris)**: 0 file (6 file Tier 1 selesai direfaktor; semua kini <=300 baris)
- **Method `build()` melebihi batas 80–100 baris**: 94 file

---

## Tier 1: Wajib Ditinjau & Direfaktor (>500 baris)

File-file ini menggabungkan beberapa tanggung jawab UI/tab/section besar dalam satu file dan menjadi prioritas utama:

- [x] **1. `lib/features/pengadaan/presentation/screens/pengadaan_hub_screen.dart` (695 baris)** -> **SELESAI, kini 231 baris**
  - *Masalah*: Menumpuk 3 tab utama (Aktif, Riwayat, Penerimaan Inbound), dialog otorisasi, dan filter status.
  - *Tindakan*: Ekstrak masing-masing tab ke file terpisah: `pengadaan_aktif_tab.dart`, `pengadaan_riwayat_tab.dart`, `pengadaan_inbound_tab.dart`.

- [x] **2. `lib/features/aset/presentation/screens/sirkulasi_aset_hub_screen.dart` (610 baris)** -> **SELESAI, kini 243 baris**
  - *Masalah*: Menumpuk tab Pinjaman Aktif, Riwayat, dan Otorisasi beserta kartu render dan action modal.
  - *Tindakan*: Ekstrak `_buildPeminjamanCard` dan `_buildOtorisasiCard` ke folder `widgets/`, satukan kalkulasi izin role.

- [x] **3. `lib/features/aset/presentation/screens/aset_detail_screen.dart` (598 baris)** -> **SELESAI, kini 299 baris**
  - *Masalah*: `build()` method mencapai 484 baris, menumpuk info spesifikasi, status operasional, histori peminjaman, dan QR dialog.
  - *Tindakan*: Pindahkan section riwayat dan section tombol aksi ke widget terpisah di `aset_detail_sections.dart`.

- [x] **4. `lib/features/aset/presentation/widgets/modal_pengalihan_aset_sheet.dart` (554 baris)** -> **SELESAI, kini 244 baris**
  - *Masalah*: `build()` method mencapai 427 baris, menggabungkan Form Tahap 1 (pemilihan aset & penyedia) dan Tahap 2 (jumlah, tanggal, alasan).
  - *Tindakan*: Ekstrak Tahap 1 dan Tahap 2 ke sub-widget `_PengalihanTahap1Section` dan `_PengalihanTahap2Section`.

- [x] **5. `lib/features/audit/presentation/widgets/sheets/form_terbitkan_temuan_sheet.dart` (548 baris)** -> **SELESAI, kini 288 baris**
  - *Masalah*: `build()` method mencapai 433 baris berisi form audit kompleks dengan banyak controller dan dropdown kriteria.
  - *Tindakan*: Pisahkan section data temuan, kriteria kepatuhan, dan section penugasan PIC ke komponen terpisah.

- [x] **6. `lib/features/aset/presentation/screens/pengalihan_hub_screen.dart` (535 baris)** -> **SELESAI, kini 283 baris**
  - *Masalah*: Menggabungkan konfigurasi TabBar, filter kategori ASET/BARANG, Empty State, dan kartu pengalihan (`_buildPengalihanCard`).
  - *Tindakan*: Pindahkan `_buildPengalihanCard` ke file tersendiri `pengalihan_card_item.dart`, satukan duplikasi kalkulasi role approver.

---

## Tier 2: Wajib Dievaluasi (301–500 baris)

File berikut dievaluasi untuk ekstraksi widget jika method `build()` terlalu panjang atau menumpuk business logic:

### Modul Aset & Master
- [ ] `lib/features/aset/presentation/screens/form_peminjaman_aset_screen.dart` (477 baris, build: 348 baris)
- [ ] `lib/features/aset/presentation/screens/histori_sirkulasi_aset_screen.dart` (425 baris, build: 332 baris)
- [ ] `lib/features/aset/presentation/widgets/modal_pengalihan_barang_sheet.dart` (422 baris, build: 325 baris)
- [ ] `lib/features/master/presentation/widgets/detail_barang_sections.dart` (421 baris — multi-widget)
- [ ] `lib/features/aset/presentation/screens/histori_pengalihan_aset_screen.dart` (398 baris, build: 307 baris)
- [ ] `lib/features/master/presentation/screens/detail_barang_screen.dart` (388 baris, build: 360 baris)
- [ ] `lib/features/aset/presentation/widgets/aset_detail_sections.dart` (384 baris — multi-widget)
- [ ] `lib/features/master/presentation/screens/register_aset_screen.dart` (316 baris)
- [ ] `lib/features/aset/presentation/screens/qr_scanner_screen.dart` (309 baris)

### Modul Maintenance & IPSRS
- [ ] `lib/features/maintenance/presentation/screens/detail_tiket_screen.dart` (448 baris, build: 394 baris)
- [ ] `lib/features/maintenance/presentation/screens/lembar_kerja_screen.dart` (440 baris, build: 263 baris)
- [ ] `lib/features/maintenance/presentation/screens/ipsrs_hub_screen.dart` (420 baris)
- [ ] `lib/features/maintenance/presentation/screens/spk_detail_screen.dart` (378 baris, build: 285 baris)
- [ ] `lib/features/maintenance/presentation/screens/spk_list_screen.dart` (375 baris)
- [ ] `lib/features/maintenance/presentation/screens/lapor_cepat_screen.dart` (370 baris)
- [ ] `lib/features/maintenance/presentation/widgets/disposisi_spk_sheet.dart` (344 baris)
- [ ] `lib/features/maintenance/presentation/widgets/rekam_medis_tabs.dart` (314 baris)
- [ ] `lib/features/maintenance/presentation/widgets/form_tambah_jadwal_sheet.dart` (305 baris)

### Modul Distribusi & Logistik
- [ ] `lib/features/distribusi/presentation/screens/form_pengajuan_amprah_screen.dart` (446 baris, build: 349 baris)
- [ ] `lib/features/distribusi/presentation/screens/detail_amprah_screen.dart` (392 baris, build: 325 baris)
- [ ] `lib/features/distribusi/presentation/screens/amprah_hub_screen.dart` (346 baris, build: 260 baris)

### Modul Pengadaan
- [ ] `lib/features/pengadaan/presentation/screens/riwayat_pr_screen.dart` (383 baris)
- [ ] `lib/features/pengadaan/presentation/screens/form_pengajuan_pr_screen.dart` (376 baris, build: 279 baris)
- [ ] `lib/features/pengadaan/presentation/widgets/terbitkan_po_sheet.dart` (369 baris)

### Modul Gudang & Persediaan
- [ ] `lib/features/gudang/presentation/screens/form_penerimaan_po_screen.dart` (376 baris)
- [ ] `lib/features/gudang/presentation/screens/otorisasi_penyesuaian_screen.dart` (311 baris)
- [ ] `lib/features/gudang/presentation/screens/inbound_po_list_screen.dart` (309 baris)

### Modul Approval, Auth, Dashboard, Audit, Profile
- [ ] `lib/features/profile/presentation/screens/profile_screen.dart` (420 baris, build: 319 baris)
- [ ] `lib/features/approval/presentation/screens/approval_center_screen.dart` (382 baris)
- [ ] `lib/features/auth/presentation/screens/login_screen.dart` (372 baris, build: 300 baris)
- [ ] `lib/features/dashboard/presentation/screens/all_activities_screen.dart` (357 baris)
- [ ] `lib/features/approval/presentation/widgets/approval_card.dart` (345 baris, build: 310 baris)
- [ ] `lib/features/dashboard/presentation/widgets/live_activity_feed.dart` (331 baris)
- [ ] `lib/features/audit/presentation/widgets/tabs/temuan_capa_tab.dart` (301 baris)

### Test Suite > 300 baris
- [ ] `test/features/aset/aset_detail_screen_test.dart` (326 baris)

---

## Tier 3: Waspada / Danger Zone (250–300 baris)

File-file ini mendekati plafon 300 baris. Perlu diperhatikan saat menambah fitur agar tidak menembus batas:

- [ ] `lib/features/anggaran/presentation/widgets/unit_drilldown_sheet.dart` (298 baris, build: 274 baris)
- [ ] `lib/features/gudang/presentation/screens/fefo_monitoring_screen.dart` (289 baris)
- [ ] `lib/features/maintenance/data/repositories/maintenance_repository.dart` (283 baris)
- [ ] `lib/features/maintenance/presentation/screens/rekam_medis_detail_screen.dart` (283 baris)
- [ ] `lib/features/aset/data/models/aset_detail_model.dart` (278 baris — model parsing, wajar)
- [ ] `lib/features/pengadaan/presentation/widgets/riwayat_pr_card_item.dart` (275 baris)
- [ ] `lib/features/aset/data/repositories/aset_repository.dart` (274 baris)
- [ ] `lib/features/maintenance/presentation/screens/jadwal_preventif_screen.dart` (272 baris)
- [ ] `lib/features/audit/presentation/screens/audit_spi_hub_screen.dart` (268 baris)
- [ ] `lib/features/audit/data/repositories/audit_repository.dart` (266 baris)
- [ ] `lib/features/gudang/presentation/screens/detail_rak_screen.dart` (265 baris)
- [ ] `lib/features/anggaran/presentation/screens/pagu_realisasi_screen.dart` (263 baris)
- [ ] `lib/features/maintenance/presentation/widgets/tiket_card_item.dart` (262 baris)
- [ ] `lib/features/shell/presentation/screens/main_shell_screen.dart` (262 baris)
- [ ] `lib/features/pengadaan/presentation/providers/pengadaan_provider.dart` (261 baris)
- [ ] `lib/features/audit/presentation/widgets/tabs/kepatuhan_po_tab.dart` (255 baris)
- [ ] `lib/features/master/presentation/screens/master_barang_screen.dart` (255 baris)
- [ ] `lib/features/pengadaan/presentation/widgets/pr_detail_sheet.dart` (255 baris)
- [ ] `lib/features/maintenance/presentation/screens/lapor_rusak_hub_screen.dart` (251 baris)
- [ ] `test/features/aset/modal_pengalihan_aset_test.dart` (263 baris)
- [ ] `test/features/dashboard/dashboard_role_views_test.dart` (263 baris)

---

## Pola Arsitektur yang Perlu Dibereskan

- [ ] **Kalkulasi Role & Permission Berulang di UI**:
  - `pengalihan_hub_screen.dart` dan `sirkulasi_aset_hub_screen.dart` mengulang periksa role di `initState` dan `build`.
  - Solusi: Sediakan helper method atau computed property pada `UserModel` (contoh: `user.canApprovePengalihan`).
- [ ] **Boilerplate Action Notifier**:
  - `pengalihan_provider.dart`, `peminjaman_provider.dart`, dan `aset_provider.dart` mengulang try/catch/invalidate di setiap method action.
- [ ] **Method `build()` Menggelembung**:
  - 94 widget memiliki `build()` >80 baris. Target refactoring adalah memindahkan sub-tree kompleks ke widget private terpisah atau file widget mandiri.

---

## Verifikasi & Definition of Done

Setiap pekerjaan refactoring wajib memenuhi:
1. Tidak ada perubahan business logic atau API contract.
2. `dart format .` telah dijalankan.
3. `flutter analyze` tidak menghasilkan error atau warning baru.
4. Seluruh test suite (`flutter test`) lulus 100%.
5. File hasil refactoring berada di rentang ideal 100–250 baris (maksimal 300 baris).
