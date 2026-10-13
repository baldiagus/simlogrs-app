import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/master_barang_item_model.dart';
import '../../data/repositories/master_repository.dart';

/// Filter tipe barang (HABIS_PAKAI/ASET/SPAREPART); null berarti semua tipe.
final masterBarangFilterTipeProvider = StateProvider.autoDispose<String?>((ref) => null);
/// Kata kunci pencarian pada daftar master barang.
final masterBarangSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
/// Filter ID kategori barang; null berarti semua kategori.
final masterBarangFilterKategoriProvider = StateProvider.autoDispose<int?>((ref) => null);

/// Daftar master barang yang otomatis dimuat ulang saat filter tipe, kategori, atau pencarian berubah.
final masterBarangListProvider = FutureProvider.autoDispose<List<MasterBarangItemModel>>((ref) async {
  final repo = ref.watch(masterRepositoryProvider);
  final tipe = ref.watch(masterBarangFilterTipeProvider);
  final cari = ref.watch(masterBarangSearchQueryProvider);
  final kategoriId = ref.watch(masterBarangFilterKategoriProvider);

  return repo.getBarangLengkap(
    tipe: tipe,
    cari: cari,
    kategoriId: kategoriId,
  );
});


/// Detail satu barang berdasarkan ID, termasuk aset, batch, dan sebaran ruangan.
final detailBarangProvider = FutureProvider.autoDispose.family<DetailBarangModel, int>((ref, id) async {
  final repo = ref.watch(masterRepositoryProvider);
  return repo.getDetailBarang(id);
});

/// Daftar unit ruangan aktif untuk pilihan filter/lokasi.
final masterUnitListProvider = FutureProvider.autoDispose<List<UnitModel>>((ref) async {
  final repo = ref.watch(masterRepositoryProvider);
  return repo.getUnitList();
});

/// Daftar fasilitas gudang aktif untuk pilihan filter/lokasi.
final masterGudangListProvider = FutureProvider.autoDispose<List<GudangModel>>((ref) async {
  final repo = ref.watch(masterRepositoryProvider);
  return repo.getGudangList();
});
