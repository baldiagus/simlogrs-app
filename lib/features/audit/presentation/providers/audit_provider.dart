import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/audit_models.dart';
import '../../data/repositories/audit_repository.dart';

final auditSummaryProvider = FutureProvider.autoDispose<AuditSummaryModel>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  return repo.getSummary();
});

class AuditTrailFilter {
  final String? aksi;
  final String? entitas;
  final String? search;
  final int page;

  const AuditTrailFilter({this.aksi, this.entitas, this.search, this.page = 1});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditTrailFilter &&
          runtimeType == other.runtimeType &&
          aksi == other.aksi &&
          entitas == other.entitas &&
          search == other.search &&
          page == other.page;

  @override
  int get hashCode => Object.hash(aksi, entitas, search, page);
}

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

final kepatuhanPoFilterProvider = StateProvider.autoDispose<String>((ref) => 'SEMUA');
final kepatuhanPoSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final kepatuhanPengadaanProvider = FutureProvider.autoDispose<List<KepatuhanPoModel>>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  final anomali = ref.watch(kepatuhanPoFilterProvider);
  final search = ref.watch(kepatuhanPoSearchProvider);

  return repo.getKepatuhanPengadaan(
    anomali: anomali == 'SEMUA' ? null : anomali,
    search: search.isEmpty ? null : search,
  );
});

final selisihOpnameProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  return repo.getSelisihOpname();
});

class TemuanFilter {
  final String? status;
  final String? risiko;
  final String? search;

  const TemuanFilter({this.status, this.risiko, this.search});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemuanFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          risiko == other.risiko &&
          search == other.search;

  @override
  int get hashCode => Object.hash(status, risiko, search);
}

final temuanFilterProvider = StateProvider.autoDispose<TemuanFilter>((ref) => const TemuanFilter());

final registerTemuanProvider = FutureProvider.autoDispose<List<TemuanCapaModel>>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  final filter = ref.watch(temuanFilterProvider);

  return repo.getRegisterTemuan(
    status: filter.status,
    risiko: filter.risiko,
    search: filter.search,
  );
});
