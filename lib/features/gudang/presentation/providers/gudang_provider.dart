import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/models/rak_model.dart';
import '../../data/models/aset_rak_model.dart';
import '../../data/repositories/gudang_repository.dart';

/// Provider repository gudang; membungkus akses API gudang memakai DioClient bersama.
final gudangRepositoryProvider = Provider<GudangRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return GudangRepository(client);
});

/// Kata kunci pencarian rak; berubah memicu pemuatan ulang [daftarRakProvider].
final rakSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Daftar rak gudang, difilter berdasarkan [rakSearchQueryProvider].
final daftarRakProvider = FutureProvider.autoDispose<List<RakModel>>((ref) async {
  final repository = ref.watch(gudangRepositoryProvider);
  final query = ref.watch(rakSearchQueryProvider);
  return await repository.getDaftarRak(cari: query);
});

/// Detail satu rak (beserta isi stoknya) berdasarkan ID rak.
final detailRakProvider =
    FutureProvider.autoDispose.family<RakDetailModel, int>((ref, id) async {
  final repository = ref.watch(gudangRepositoryProvider);
  return await repository.getDetailRak(id);
});
