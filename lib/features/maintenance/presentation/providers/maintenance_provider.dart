import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../gudang/presentation/providers/gudang_provider.dart';
import 'ipsrs_providers.dart';
import 'tiket_maintenance_provider.dart';
import '../../data/models/spk_model.dart';
import '../../data/repositories/maintenance_repository.dart';

/// Provider repository maintenance (tiket dan SPK).
final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return MaintenanceRepository(client);
});

/// Provider daftar SPK per status.
final spkListProvider =
    FutureProvider.autoDispose.family<List<SpkHeaderModel>, String>((ref, status) async {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return await repository.getSpkList(status: status == 'SEMUA' ? null : status);
});

/// Provider detail SPK per ID.
final spkDetailProvider =
    FutureProvider.autoDispose.family<SpkDetailModel, int>((ref, id) async {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return await repository.getSpkDetail(id);
});

class LembarKerjaState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  /// Membuat LembarKerjaState.
  const LembarKerjaState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class LembarKerjaNotifier extends StateNotifier<LembarKerjaState> {
  final MaintenanceRepository _repository;
  final Ref _ref;

  /// Membuat LembarKerjaNotifier.
  LembarKerjaNotifier(this._repository, this._ref) : super(const LembarKerjaState());

  /// Kirim log pengerjaan SPK ke server dan perbarui state; true jika berhasil.
  Future<bool> submitLog({
    required int spkId,
    required String diagnosa,
    required String tindakan,
    required String hasil,
    String? jamMulai,
    String? jamSelesai,
    String? catatan,
    XFile? foto,
    List<Map<String, dynamic>>? spareparts,
  }) async {
    state = const LembarKerjaState(isLoading: true);
    try {
      await _repository.submitLembarKerja(
        spkId: spkId,
        diagnosa: diagnosa,
        tindakan: tindakan,
        hasil: hasil,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        catatan: catatan,
        foto: foto,
        spareparts: spareparts,
      );

      state = const LembarKerjaState(
        isLoading: false,
        successMessage: 'Lembar kerja dan pemakaian suku cadang berhasil disimpan.',
      );

      _ref.invalidate(spkDetailProvider(spkId));
      _ref.invalidate(spkListProvider);
      _ref.invalidate(daftarTiketUnitProvider);
      _ref.invalidate(rekamMedisKatalogProvider);
      _ref.invalidate(daftarRakProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = LembarKerjaState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }
}

/// Provider notifier lembar kerja SPK.
final lembarKerjaProvider =
    StateNotifierProvider<LembarKerjaNotifier, LembarKerjaState>((ref) {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return LembarKerjaNotifier(repository, ref);
});
