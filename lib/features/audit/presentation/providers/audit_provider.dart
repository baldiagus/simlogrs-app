import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simlog_mobile/core/models/pagination_meta.dart';
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

/// Alias state paginasi daftar jejak audit.
typedef AuditTrailState = PagedListState<AuditTrailItemModel>;

/// StateNotifier untuk mengelola pemuatan jejak audit dengan paginasi dan filter.
class AuditTrailNotifier extends StateNotifier<PagedListState<AuditTrailItemModel>> {
  final AuditRepository _repository;
  String? _aksi;
  String? _search;
  String? _entitas;

  /// Membuat [AuditTrailNotifier] dengan filter awal opsional.
  AuditTrailNotifier(
    this._repository, {
    String? aksi,
    String? search,
    String? entitas,
  })  : _aksi = aksi,
        _search = search,
        _entitas = entitas,
        super(const PagedListState<AuditTrailItemModel>.initial());

  /// Aksi yang sedang difilter.
  String? get aksi => _aksi;

  /// Kata kunci pencarian yang sedang aktif.
  String? get search => _search;

  /// Jenis entitas yang sedang difilter.
  String? get entitas => _entitas;

  /// Memuat halaman pertama jejak audit.
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.getAuditTrail(
        aksi: _aksi,
        entitas: _entitas,
        search: _search,
        page: 1,
      );
      state = state.copyWith(
        items: res.items,
        page: 1,
        hasMore: res.meta.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Memuat halaman berikutnya bila masih ada data dan tidak sedang memuat.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.page + 1;
    try {
      final res = await _repository.getAuditTrail(
        aksi: _aksi,
        entitas: _entitas,
        search: _search,
        page: nextPage,
      );
      state = state.copyWith(
        items: [...state.items, ...res.items],
        page: nextPage,
        hasMore: res.meta.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Memuat ulang jejak audit dari halaman pertama.
  Future<void> refresh() async {
    try {
      final res = await _repository.getAuditTrail(
        aksi: _aksi,
        entitas: _entitas,
        search: _search,
        page: 1,
      );
      state = state.copyWith(
        items: res.items,
        page: 1,
        hasMore: res.meta.hasMore,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Memperbarui filter aksi dan kata kunci pencarian lalu memuat ulang dari halaman 1.
  Future<void> setFilter({String? aksi, String? search, String? entitas}) async {
    _aksi = aksi;
    _search = search;
    if (entitas != null) _entitas = entitas;
    state = const PagedListState<AuditTrailItemModel>.initial();
    await loadInitial();
  }

  /// Mengatur filter aksi dan memuat ulang halaman pertama.
  Future<void> setAksi(String? aksi) => setFilter(aksi: aksi, search: _search, entitas: _entitas);

  /// Mengatur kata kunci pencarian dan memuat ulang halaman pertama.
  Future<void> setSearch(String? search) => setFilter(aksi: _aksi, search: search, entitas: _entitas);
}

/// Provider state paginasi jejak audit yang memegang filter aksi dan pencarian.
final auditTrailProvider = StateNotifierProvider.autoDispose<
    AuditTrailNotifier,
    PagedListState<AuditTrailItemModel>>((ref) {
  final repo = ref.watch(auditRepositoryProvider);
  return AuditTrailNotifier(repo)..loadInitial();
});

/// Family provider jejak audit per filter untuk skenario isolasi filter.
final auditTrailFamilyProvider = StateNotifierProvider.autoDispose.family<
    AuditTrailNotifier,
    PagedListState<AuditTrailItemModel>,
    AuditTrailFilter>((ref, filter) {
  final repo = ref.watch(auditRepositoryProvider);
  return AuditTrailNotifier(
    repo,
    aksi: filter.aksi,
    entitas: filter.entitas,
    search: filter.search,
  )..loadInitial();
});

/// Alias untuk [auditTrailProvider] agar konsisten penamaan notifier.
final auditTrailNotifierProvider = auditTrailProvider;

/// Filter jenis anomali PO yang dipilih ('SEMUA' berarti tanpa filter).
final kepatuhanPoFilterProvider = StateProvider.autoDispose<String>((ref) => 'SEMUA');
/// Kata kunci pencarian pada tab kepatuhan PO.
final kepatuhanPoSearchProvider = StateProvider.autoDispose<String>((ref) => '');

/// Daftar PO untuk audit kepatuhan; mengikuti filter anomali dan kata kunci pencarian.
final kepatuhanPengadaanProvider = FutureProvider.autoDispose<List<KepatuhanPoModel>>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  final anomali = ref.watch(kepatuhanPoFilterProvider);
  final search = ref.watch(kepatuhanPoSearchProvider);

  final res = await repo.getKepatuhanPengadaan(
    anomali: anomali == 'SEMUA' ? null : anomali,
    search: search.isEmpty ? null : search,
  );
  return res.items;
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

/// Jumlah CAPA berstatus In Progress (halaman pertama register) untuk lencana pintasan dashboard auditee.
final capaMenungguCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(auditRepositoryProvider);
  return (await repo.getRegisterTemuan(status: 'In Progress')).length;
});
