import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/register_aset_item_model.dart';
import '../../data/repositories/master_repository.dart';

final registerAsetLokasiTipeProvider = StateProvider.autoDispose<String?>((ref) => null);
final registerAsetStatusProvider = StateProvider.autoDispose<String?>((ref) => null);
final registerAsetKondisiProvider = StateProvider.autoDispose<String?>((ref) => null);
final registerAsetSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final registerAsetListProvider = FutureProvider.autoDispose<List<RegisterAsetItemModel>>((ref) async {
  final repo = ref.watch(masterRepositoryProvider);
  final lokasiTipe = ref.watch(registerAsetLokasiTipeProvider);
  final status = ref.watch(registerAsetStatusProvider);
  final kondisi = ref.watch(registerAsetKondisiProvider);
  final cari = ref.watch(registerAsetSearchQueryProvider);

  return repo.getAsetLengkap(
    lokasiTipe: lokasiTipe,
    status: status,
    kondisi: kondisi,
    cari: cari,
  );
});
