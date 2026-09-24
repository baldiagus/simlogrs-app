import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/models/aset_detail_model.dart';
import '../../data/repositories/aset_repository.dart';

final asetRepositoryProvider = Provider<AsetRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return AsetRepository(client);
});

class AsetActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final AsetDetailModel? aset;

  const AsetActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.aset,
  });

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

class AsetActionNotifier extends StateNotifier<AsetActionState> {
  final AsetRepository _repository;

  AsetActionNotifier(this._repository) : super(const AsetActionState());

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

  void clearState() {
    state = const AsetActionState();
  }
}

final asetActionProvider =
    StateNotifierProvider<AsetActionNotifier, AsetActionState>((ref) {
  final repository = ref.watch(asetRepositoryProvider);
  return AsetActionNotifier(repository);
});
