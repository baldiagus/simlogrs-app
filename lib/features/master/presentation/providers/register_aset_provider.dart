import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/register_aset_item_model.dart';
import '../../data/repositories/master_repository.dart';

/// Filter tipe lokasi aset (RUANGAN/GUDANG); null berarti semua.
final registerAsetLokasiTipeProvider = StateProvider.autoDispose<String?>((ref) => null);
/// Filter status aset; null berarti semua status.
final registerAsetStatusProvider = StateProvider.autoDispose<String?>((ref) => null);
/// Filter kondisi aset (BAIK/RUSAK_RINGAN/RUSAK_BERAT); null berarti semua.
final registerAsetKondisiProvider = StateProvider.autoDispose<String?>((ref) => null);
/// Kata kunci pencarian pada register aset.
final registerAsetSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Daftar register aset yang dimuat ulang otomatis mengikuti seluruh filter dan pencarian.
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
