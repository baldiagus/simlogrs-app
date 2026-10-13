import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/pagination_meta.dart';
import '../../data/models/notifikasi_model.dart';
import '../../data/repositories/notifikasi_repository.dart';

/// Jumlah notifikasi belum dibaca; sumber badge lonceng dan diperbarui oleh inbox serta [belumDibacaSinkronProvider].
final belumDibacaProvider = StateProvider<int>((ref) => 0);

/// Menyinkronkan [belumDibacaProvider] dari server (GET /notifikasi) tanpa memunculkan error ke UI.
/// Panggil `ref.invalidate(belumDibacaSinkronProvider)` setelah push FCM masuk untuk menyegarkan badge.
final belumDibacaSinkronProvider = FutureProvider.autoDispose<void>((ref) async {
  final repo = ref.watch(notifikasiRepositoryProvider);
  try {
    final hasil = await repo.getDaftar(hanyaBelumDibaca: true);
    ref.read(belumDibacaProvider.notifier).state = hasil.belumDibaca;
  } catch (_) {
    // Badge bersifat pelengkap: kegagalan jaringan dibiarkan senyap, nilai terakhir dipertahankan.
  }
});

/// Mengelola daftar inbox notifikasi berhalaman, filter belum dibaca, dan aksi baca secara optimistis.
class NotifikasiListNotifier extends StateNotifier<PagedListState<NotifikasiModel>> {
  final NotifikasiRepository _repository;
  final StateController<int> _belumDibaca;
  bool _hanyaBelumDibaca;

  /// Membuat [NotifikasiListNotifier]; [_belumDibaca] adalah pengendali [belumDibacaProvider].
  NotifikasiListNotifier(
    this._repository,
    this._belumDibaca, {
    bool hanyaBelumDibaca = false,
  })  : _hanyaBelumDibaca = hanyaBelumDibaca,
        super(const PagedListState<NotifikasiModel>.initial());

  /// True bila daftar hanya menampilkan notifikasi belum dibaca.
  bool get hanyaBelumDibaca => _hanyaBelumDibaca;

  /// Memuat halaman pertama dan menyelaraskan jumlah belum dibaca.
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.getDaftar(hanyaBelumDibaca: _hanyaBelumDibaca);
      _belumDibaca.state = res.belumDibaca;
      state = state.copyWith(
        items: res.halaman.items,
        page: 1,
        hasMore: res.halaman.meta.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Memuat halaman berikutnya bila masih ada dan tidak sedang memuat.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.page + 1;
    try {
      final res = await _repository.getDaftar(page: nextPage, hanyaBelumDibaca: _hanyaBelumDibaca);
      _belumDibaca.state = res.belumDibaca;
      state = state.copyWith(
        items: [...state.items, ...res.halaman.items],
        page: nextPage,
        hasMore: res.halaman.meta.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  /// Memuat ulang dari halaman pertama tanpa menampilkan loading layar penuh (pull-to-refresh).
  Future<void> refresh() async {
    try {
      final res = await _repository.getDaftar(hanyaBelumDibaca: _hanyaBelumDibaca);
      _belumDibaca.state = res.belumDibaca;
      state = state.copyWith(
        items: res.halaman.items,
        page: 1,
        hasMore: res.halaman.meta.hasMore,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Mengganti filter belum dibaca lalu memuat ulang dari halaman pertama.
  Future<void> setHanyaBelumDibaca(bool nilai) async {
    if (_hanyaBelumDibaca == nilai) return;
    _hanyaBelumDibaca = nilai;
    state = const PagedListState<NotifikasiModel>.initial();
    await loadInitial();
  }

  /// Menandai satu notifikasi dibaca secara optimistis; dikembalikan ke semula bila server gagal.
  Future<void> tandaiDibaca(int id) async {
    final index = state.items.indexWhere((n) => n.id == id);
    if (index < 0 || state.items[index].dibaca) return;
    final itemsSemula = state.items;
    final hitungSemula = _belumDibaca.state;

    state = state.copyWith(items: _tandai(itemsSemula, id));
    _belumDibaca.state = hitungSemula > 0 ? hitungSemula - 1 : 0;
    try {
      _belumDibaca.state = await _repository.tandaiDibaca(id);
    } catch (_) {
      state = state.copyWith(items: itemsSemula);
      _belumDibaca.state = hitungSemula;
    }
  }

  /// Menandai seluruh notifikasi dibaca secara optimistis; dikembalikan ke semula bila server gagal.
  Future<void> bacaSemua() async {
    final itemsSemula = state.items;
    final hitungSemula = _belumDibaca.state;

    state = state.copyWith(items: [for (final n in itemsSemula) n.copyWith(dibaca: true)]);
    _belumDibaca.state = 0;
    try {
      await _repository.bacaSemua();
    } catch (_) {
      state = state.copyWith(items: itemsSemula);
      _belumDibaca.state = hitungSemula;
    }
  }

  /// Mengembalikan salinan [items] dengan notifikasi ber-ID [id] bertanda dibaca.
  static List<NotifikasiModel> _tandai(List<NotifikasiModel> items, int id) {
    return [for (final n in items) n.id == id ? n.copyWith(dibaca: true) : n];
  }
}

/// Provider daftar inbox notifikasi; langsung memuat halaman pertama saat dipakai.
final notifikasiListProvider = StateNotifierProvider.autoDispose<
    NotifikasiListNotifier, PagedListState<NotifikasiModel>>((ref) {
  final repo = ref.watch(notifikasiRepositoryProvider);
  return NotifikasiListNotifier(repo, ref.read(belumDibacaProvider.notifier))..loadInitial();
});
