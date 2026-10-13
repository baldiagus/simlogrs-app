import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/anggaran_models.dart';
import '../../data/repositories/anggaran_repository.dart';

/// Tahun anggaran yang sedang dipilih pengguna; default 2026.
final selectedTahunAnggaranProvider = StateProvider<String>((ref) => '2026');

/// Memuat data screening anggaran untuk tahun terpilih; otomatis dimuat ulang saat tahun berubah.
final screeningAnggaranProvider = FutureProvider.autoDispose<AnggaranScreeningModel>((ref) async {
  final repo = ref.watch(anggaranRepositoryProvider);
  final tahun = ref.watch(selectedTahunAnggaranProvider);
  return repo.getScreeningAnggaran(tahun: tahun);
});

/// Memuat rincian pengeluaran satu unit (per unit dan tahun) untuk bottom sheet drilldown.
final unitDrilldownProvider = FutureProvider.autoDispose.family<UnitDrilldownModel, ({int unitId, String tahun})>((ref, arg) async {
  final repo = ref.watch(anggaranRepositoryProvider);
  return repo.getUnitDetail(arg.unitId, tahun: arg.tahun);
});
