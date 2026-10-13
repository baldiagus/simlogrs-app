import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/audit_models.dart';
import '../../data/repositories/audit_repository.dart';

/// Ringkasan angka dashboard audit SPI, diambil dari repository dan dibuang saat tidak dipakai.
final auditSummaryProvider = FutureProvider.autoDispose<AuditSummaryModel>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  return repo.getSummary();
});

/// Parameter filter jejak audit; punya kesetaraan nilai agar aman jadi key family provider.
class AuditTrailFilter {
  final String? aksi;
  final String? entitas;
  final String? search;
  final int page;

  const AuditTrailFilter({this.aksi, this.entitas, this.search, this.page = 1});

  /// Dua filter dianggap sama bila aksi, entitas, search, dan halaman sama.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditTrailFilter &&
          runtimeType == other.runtimeType &&
          aksi == other.aksi &&
          entitas == other.entitas &&
          search == other.search &&
          page == other.page;

  /// Hash konsisten dengan `==` agar family provider memakai key yang sama untuk filter sama.
  @override
  int get hashCode => Object.hash(aksi, entitas, search, page);
}

/// Jejak audit per filter (aksi, entitas, search, halaman); tiap kombinasi filter di-cache terpisah.
final auditTrailProvider =
    FutureProvider.autoDispose.family<List<AuditTrailItemModel>, AuditTrailFilter>((ref, filter) async {
  final repo = ref.watch(auditRepositoryProvider);
  return repo.getAuditTrail(
    aksi: filter.aksi,
    entitas: filter.entitas,
    search: filter.search,
    page: filter.page,
  );
});

/// Filter jenis anomali PO yang dipilih ('SEMUA' berarti tanpa filter).
final kepatuhanPoFilterProvider = StateProvider.autoDispose<String>((ref) => 'SEMUA');
/// Kata kunci pencarian pada tab kepatuhan PO.
final kepatuhanPoSearchProvider = StateProvider.autoDispose<String>((ref) => '');

/// Daftar PO untuk audit kepatuhan; mengikuti filter anomali dan kata kunci pencarian.
final kepatuhanPengadaanProvider = FutureProvider.autoDispose<List<KepatuhanPoModel>>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  final anomali = ref.watch(kepatuhanPoFilterProvider);
  final search = ref.watch(kepatuhanPoSearchProvider);

  return repo.getKepatuhanPengadaan(
    anomali: anomali == 'SEMUA' ? null : anomali,
    search: search.isEmpty ? null : search,
  );
});

/// Data selisih opname fisik vs sistem untuk tab audit selisih opname.
final selisihOpnameProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  return repo.getSelisihOpname();
});

/// Nilai filter register temuan; punya kesetaraan nilai agar aman jadi key provider.
class TemuanFilter {
  final String? status;
  final String? risiko;
  final String? search;

  const TemuanFilter({this.status, this.risiko, this.search});

  /// Dua filter dianggap sama bila status, risiko, dan search sama.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemuanFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          risiko == other.risiko &&
          search == other.search;

  /// Hash konsisten dengan `==` agar family/provider tidak refetch tanpa perubahan filter.
  @override
  int get hashCode => Object.hash(status, risiko, search);
}

/// Filter aktif (status, risiko, kata kunci) untuk register temuan CAPA.
final temuanFilterProvider = StateProvider.autoDispose<TemuanFilter>((ref) => const TemuanFilter());

/// Daftar register temuan CAPA; otomatis refetch saat [temuanFilterProvider] berubah.
final registerTemuanProvider = FutureProvider.autoDispose<List<TemuanCapaModel>>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  final filter = ref.watch(temuanFilterProvider);

  return repo.getRegisterTemuan(
    status: filter.status,
    risiko: filter.risiko,
    search: filter.search,
  );
});
