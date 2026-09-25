import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/jadwal_preventif_model.dart';
import '../../data/models/rekam_medis_aset_model.dart';
import '../../data/repositories/ipsrs_repository.dart';

// Jadwal Preventif Providers
final preventifStatusFilterProvider = StateProvider.autoDispose<String>((ref) => 'SEMUA');
final preventifSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final jadwalPreventifListProvider = FutureProvider.autoDispose<List<JadwalPreventifItemModel>>((ref) async {
  final repo = ref.watch(ipsrsRepositoryProvider);
  final status = ref.watch(preventifStatusFilterProvider);
  final cari = ref.watch(preventifSearchQueryProvider);

  return repo.getJadwalPreventif(status: status, cari: cari);
});

// Rekam Medis Providers
final rekamMedisKondisiFilterProvider = StateProvider.autoDispose<String?>((ref) => null);
final rekamMedisSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final rekamMedisKatalogProvider = FutureProvider.autoDispose<List<RekamMedisAsetKatalogModel>>((ref) async {
  final repo = ref.watch(ipsrsRepositoryProvider);
  final kondisi = ref.watch(rekamMedisKondisiFilterProvider);
  final cari = ref.watch(rekamMedisSearchQueryProvider);

  return repo.getKatalogRekamMedis(kondisi: kondisi, cari: cari);
});

final rekamMedisDetailProvider = FutureProvider.autoDispose.family<RekamMedisDetailResponse, int>((ref, asetId) async {
  final repo = ref.watch(ipsrsRepositoryProvider);
  return repo.getRekamMedisAset(asetId);
});
