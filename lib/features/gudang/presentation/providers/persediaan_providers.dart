import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/buku_mutasi_model.dart';
import '../../data/models/fefo_monitoring_model.dart';
import '../../data/models/penyesuaian_stok_model.dart';
import '../../data/models/stock_opname_model.dart';
import '../../data/repositories/persediaan_repository.dart';

// FEFO Providers
/// Filter kategori monitoring FEFO ('SEMUA' = tanpa filter).
final fefoKategoriFilterProvider = StateProvider.autoDispose<String>((ref) => 'SEMUA');
/// Kata kunci pencarian monitoring FEFO.
final fefoSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Data monitoring FEFO (batch menurut urutan kedaluwarsa), mengikuti filter kategori dan pencarian.
final fefoMonitoringProvider = FutureProvider.autoDispose<FefoMonitoringResponse>((ref) async {
  final repo = ref.watch(persediaanRepositoryProvider);
  final kategori = ref.watch(fefoKategoriFilterProvider);
  final cari = ref.watch(fefoSearchQueryProvider);

  return repo.getMonitoringFefo(kategori: kategori, cari: cari);
});

// Buku Mutasi Providers
/// Filter jenis mutasi pada buku mutasi (null = semua jenis).
final mutasiJenisFilterProvider = StateProvider.autoDispose<String?>((ref) => null);
/// Kata kunci pencarian buku mutasi.
final mutasiSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Daftar riwayat mutasi stok, mengikuti filter jenis dan pencarian.
final bukuMutasiListProvider = FutureProvider.autoDispose<List<BukuMutasiItemModel>>((ref) async {
  final repo = ref.watch(persediaanRepositoryProvider);
  final jenis = ref.watch(mutasiJenisFilterProvider);
  final cari = ref.watch(mutasiSearchQueryProvider);

  return repo.getBukuMutasi(jenis: jenis, cari: cari);
});

// Stock Opname Providers
/// Filter status sesi stock opname (null = semua status).
final opnameStatusFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Daftar sesi stock opname, mengikuti filter status.
final stockOpnameListProvider = FutureProvider.autoDispose<List<StokOpnameSesiModel>>((ref) async {
  final repo = ref.watch(persediaanRepositoryProvider);
  final status = ref.watch(opnameStatusFilterProvider);

  return repo.getDaftarOpname(status: status);
});

// Otorisasi Penyesuaian Providers
/// Filter status otorisasi penyesuaian stok; default 'MENUNGGU'.
final penyesuaianStatusFilterProvider = StateProvider.autoDispose<String>((ref) => 'MENUNGGU');

/// Daftar penyesuaian stok untuk diotorisasi, mengikuti filter status.
final otorisasiPenyesuaianListProvider = FutureProvider.autoDispose<List<PenyesuaianStokHeaderModel>>((ref) async {
  final repo = ref.watch(persediaanRepositoryProvider);
  final status = ref.watch(penyesuaianStatusFilterProvider);

  return repo.getDaftarPenyesuaian(status: status);
});

// Master Gudang Provider
/// Daftar master gudang, mis. untuk pilihan gudang saat memulai opname.
final masterGudangListProvider = FutureProvider.autoDispose<List<GudangModel>>((ref) async {
  final repo = ref.watch(persediaanRepositoryProvider);
  return repo.getMasterGudangList();
});
