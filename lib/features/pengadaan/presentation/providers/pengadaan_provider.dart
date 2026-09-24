import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/master_barang_model.dart';
import '../../data/models/pr_model.dart';
import '../../data/repositories/pengadaan_repository.dart';

final pengadaanRepositoryProvider = Provider<PengadaanRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return PengadaanRepository(client);
});

final katalogBarangProvider =
    FutureProvider.autoDispose.family<List<MasterBarangModel>, String>((ref, query) async {
  final repository = ref.watch(pengadaanRepositoryProvider);
  return await repository.getKatalogBarang(cari: query);
});

final daftarPrProvider = FutureProvider.autoDispose<List<PrHeaderModel>>((ref) async {
  final repository = ref.watch(pengadaanRepositoryProvider);
  return await repository.getDaftarPr();
});

class PrSubmissionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const PrSubmissionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class PrSubmissionNotifier extends StateNotifier<PrSubmissionState> {
  final PengadaanRepository _repository;
  final Ref _ref;

  PrSubmissionNotifier(this._repository, this._ref) : super(const PrSubmissionState());

  Future<bool> submitPr({
    int? unitId,
    required String urgensi,
    String? catatan,
    required List<PrCartItemModel> items,
  }) async {
    if (items.isEmpty) {
      state = const PrSubmissionState(
        errorMessage: 'Keranjang pengadaan masih kosong. Silakan pilih minimal 1 barang.',
      );
      return false;
    }

    state = const PrSubmissionState(isLoading: true);
    try {
      final payloadItems = items.map((e) => e.toSubmissionJson()).toList();
      final res = await _repository.submitPr(
        unitId: unitId,
        urgensi: urgensi,
        catatan: catatan,
        items: payloadItems,
      );

      final kode = res['kode']?.toString() ?? 'PR Baru';
      state = PrSubmissionState(
        isLoading: false,
        successMessage: 'Permintaan pengadaan $kode berhasil diajukan.',
      );

      _ref.invalidate(daftarPrProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = PrSubmissionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }
}

final prSubmissionProvider =
    StateNotifierProvider<PrSubmissionNotifier, PrSubmissionState>((ref) {
  final repository = ref.watch(pengadaanRepositoryProvider);
  return PrSubmissionNotifier(repository, ref);
});
