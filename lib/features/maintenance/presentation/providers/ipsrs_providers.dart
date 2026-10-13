import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/jadwal_preventif_model.dart';
import '../../data/models/rekam_medis_aset_model.dart';
import '../../data/repositories/ipsrs_repository.dart';

// Jadwal Preventif Providers
/// State filter status jadwal preventif.
final preventifStatusFilterProvider = StateProvider.autoDispose<String>((ref) => 'SEMUA');
/// State teks pencarian jadwal preventif.
final preventifSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Provider daftar jadwal preventif sesuai filter status dan pencarian.
final jadwalPreventifListProvider = FutureProvider.autoDispose<List<JadwalPreventifItemModel>>((ref) async {
  final repo = ref.watch(ipsrsRepositoryProvider);
  final status = ref.watch(preventifStatusFilterProvider);
  final cari = ref.watch(preventifSearchQueryProvider);

  return repo.getJadwalPreventif(status: status, cari: cari);
});

// Rekam Medis Providers
/// State filter kondisi aset di katalog rekam medis.
final rekamMedisKondisiFilterProvider = StateProvider.autoDispose<String?>((ref) => null);
/// State teks pencarian katalog rekam medis.
final rekamMedisSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Provider katalog rekam medis sesuai filter kondisi dan pencarian.
final rekamMedisKatalogProvider = FutureProvider.autoDispose<List<RekamMedisAsetKatalogModel>>((ref) async {
  final repo = ref.watch(ipsrsRepositoryProvider);
  final kondisi = ref.watch(rekamMedisKondisiFilterProvider);
  final cari = ref.watch(rekamMedisSearchQueryProvider);

  return repo.getKatalogRekamMedis(kondisi: kondisi, cari: cari);
});

/// Provider detail rekam medis per ID aset.
final rekamMedisDetailProvider = FutureProvider.autoDispose.family<RekamMedisDetailResponse, int>((ref, asetId) async {
  final repo = ref.watch(ipsrsRepositoryProvider);
  return repo.getRekamMedisAset(asetId);
});
