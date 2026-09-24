import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/models/rak_model.dart';
import '../../data/models/aset_rak_model.dart';
import '../../data/repositories/gudang_repository.dart';

final gudangRepositoryProvider = Provider<GudangRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return GudangRepository(client);
});

final rakSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final daftarRakProvider = FutureProvider.autoDispose<List<RakModel>>((ref) async {
  final repository = ref.watch(gudangRepositoryProvider);
  final query = ref.watch(rakSearchQueryProvider);
  return await repository.getDaftarRak(cari: query);
});

final detailRakProvider =
    FutureProvider.autoDispose.family<RakDetailModel, int>((ref, id) async {
  final repository = ref.watch(gudangRepositoryProvider);
  return await repository.getDetailRak(id);
});
