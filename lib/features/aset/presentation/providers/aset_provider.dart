import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/models/aset_detail_model.dart';
import '../../data/repositories/aset_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../master/presentation/providers/register_aset_provider.dart';
import 'peminjaman_provider.dart';
/// Provider [AsetRepository] untuk operasi data aset via klien HTTP bersama.
final asetRepositoryProvider = Provider<AsetRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return AsetRepository(client);
});

/// State aksi aset: status loading, pesan error/sukses, dan hasil aset hasil scan.
class AsetActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final AsetDetailModel? aset;

  /// Membuat state aksi aset; default idle tanpa pesan dan tanpa aset.
  const AsetActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.aset,
  });

  /// Menyalin state dengan nilai baru; pesan error/sukses selalu di-reset kecuali diisi ulang.
  AsetActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    AsetDetailModel? aset,
  }) {
    return AsetActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      aset: aset ?? this.aset,
    );
  }
}

/// Notifier aksi aset: scan QR, serah terima, dan pengembalian fisik.
class AsetActionNotifier extends StateNotifier<AsetActionState> {
  final AsetRepository _repository;
  final Ref _ref;

  /// Membuat notifier dengan repository aset dan [Ref] untuk invalidasi provider terkait.
  AsetActionNotifier(this._repository, this._ref) : super(const AsetActionState());

  /// Mencari aset berdasarkan hasil scan [query] (kode/QR) dan menyimpannya di state; null jika gagal.
  Future<AsetDetailModel?> scanAset(String query) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final detail = await _repository.scanQr(query);
      state = state.copyWith(isLoading: false, aset: detail);
      return detail;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return null;
    }
  }

  /// Mengonfirmasi serah terima fisik peminjaman [peminjamanId], lalu memuat ulang aset yang sedang di-scan.
  Future<bool> konfirmasiSerahTerima(int peminjamanId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final res = await _repository.serahTerima(peminjamanId);
      final kode = res['kode']?.toString() ?? 'Peminjaman';
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Serah terima fisik untuk $kode berhasil dikonfirmasi.',
      );
      // Reload current scanned asset if available
      if (state.aset != null) {
        await scanAset(state.aset!.kodeAset);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  /// Mencatat pengembalian fisik peminjaman beserta hasil [inspeksi] dan [catatan], lalu menyegarkan daftar terkait.
  Future<bool> konfirmasiPengembalian({
    required int peminjamanId,
    required List<Map<String, dynamic>> inspeksi,
    String? catatan,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final res = await _repository.kembalikan(
        peminjamanId: peminjamanId,
        inspeksi: inspeksi,
        catatan: catatan,
      );
      final kodeRet = res['kode_pengembalian']?.toString() ?? 'Selesai';
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Pengembalian fisik ($kodeRet) berhasil dicatat.',
      );
      _ref.invalidate(daftarPeminjamanSayaProvider);
      _ref.invalidate(daftarPeminjamanAktifDipinjamProvider);
      _ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider);
      _ref.invalidate(registerAsetListProvider);
      _ref.invalidate(dashboardSummaryProvider);
      // Reload current scanned asset if available
      if (state.aset != null) {
        await scanAset(state.aset!.kodeAset);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  /// Mengembalikan state ke kondisi awal (tanpa loading, pesan, maupun aset).
  void clearState() {
    state = const AsetActionState();
  }
}

/// Provider [AsetActionNotifier] untuk aksi scan dan serah terima/pengembalian aset.
final asetActionProvider =
    StateNotifierProvider<AsetActionNotifier, AsetActionState>((ref) {
  final repository = ref.watch(asetRepositoryProvider);
  return AsetActionNotifier(repository, ref);
});
