import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/master_barang_item_model.dart';
import '../../data/repositories/master_repository.dart';

final masterBarangFilterTipeProvider = StateProvider.autoDispose<String?>((ref) => null);
final masterBarangSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final masterBarangFilterKategoriProvider = StateProvider.autoDispose<int?>((ref) => null);

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

final masterKategoriListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(masterRepositoryProvider);
  return repo.getKategoriList();
});

final detailBarangProvider = FutureProvider.autoDispose.family<DetailBarangModel, int>((ref, id) async {
  final repo = ref.watch(masterRepositoryProvider);
  return repo.getDetailBarang(id);
});

final masterUnitListProvider = FutureProvider.autoDispose<List<UnitModel>>((ref) async {
  final repo = ref.watch(masterRepositoryProvider);
  return repo.getUnitList();
});

final masterGudangListProvider = FutureProvider.autoDispose<List<GudangModel>>((ref) async {
  final repo = ref.watch(masterRepositoryProvider);
  return repo.getGudangList();
});
