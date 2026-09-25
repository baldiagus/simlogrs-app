import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/buku_mutasi_model.dart';
import '../../data/models/fefo_monitoring_model.dart';
import '../../data/models/penyesuaian_stok_model.dart';
import '../../data/models/stock_opname_model.dart';
import '../../data/repositories/persediaan_repository.dart';

// FEFO Providers
final fefoKategoriFilterProvider = StateProvider.autoDispose<String>((ref) => 'SEMUA');
final fefoSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final fefoMonitoringProvider = FutureProvider.autoDispose<FefoMonitoringResponse>((ref) async {
  final repo = ref.watch(persediaanRepositoryProvider);
  final kategori = ref.watch(fefoKategoriFilterProvider);
  final cari = ref.watch(fefoSearchQueryProvider);

  return repo.getMonitoringFefo(kategori: kategori, cari: cari);
});

// Buku Mutasi Providers
final mutasiJenisFilterProvider = StateProvider.autoDispose<String?>((ref) => null);
final mutasiSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final bukuMutasiListProvider = FutureProvider.autoDispose<List<BukuMutasiItemModel>>((ref) async {
  final repo = ref.watch(persediaanRepositoryProvider);
  final jenis = ref.watch(mutasiJenisFilterProvider);
  final cari = ref.watch(mutasiSearchQueryProvider);

  return repo.getBukuMutasi(jenis: jenis, cari: cari);
});

// Stock Opname Providers
final opnameStatusFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

final stockOpnameListProvider = FutureProvider.autoDispose<List<StokOpnameSesiModel>>((ref) async {
  final repo = ref.watch(persediaanRepositoryProvider);
  final status = ref.watch(opnameStatusFilterProvider);

  return repo.getDaftarOpname(status: status);
});

// Otorisasi Penyesuaian Providers
final penyesuaianStatusFilterProvider = StateProvider.autoDispose<String>((ref) => 'MENUNGGU');

final otorisasiPenyesuaianListProvider = FutureProvider.autoDispose<List<PenyesuaianStokHeaderModel>>((ref) async {
  final repo = ref.watch(persediaanRepositoryProvider);
  final status = ref.watch(penyesuaianStatusFilterProvider);

  return repo.getDaftarPenyesuaian(status: status);
});
