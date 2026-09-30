import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../gudang/presentation/providers/gudang_provider.dart';
import 'ipsrs_providers.dart';
import 'tiket_maintenance_provider.dart';
import '../../data/models/spk_model.dart';
import '../../data/repositories/maintenance_repository.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return MaintenanceRepository(client);
});

final spkListProvider =
    FutureProvider.autoDispose.family<List<SpkHeaderModel>, String>((ref, status) async {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return await repository.getSpkList(status: status == 'SEMUA' ? null : status);
});

final spkDetailProvider =
    FutureProvider.autoDispose.family<SpkDetailModel, int>((ref, id) async {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return await repository.getSpkDetail(id);
});

class LaporCepatState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const LaporCepatState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class LaporCepatNotifier extends StateNotifier<LaporCepatState> {
  final MaintenanceRepository _repository;
  final Ref _ref;

  LaporCepatNotifier(this._repository, this._ref) : super(const LaporCepatState());

  Future<bool> submit({
    int? asetId,
    String? kodeAset,
    required String deskripsiMasalah,
    required String prioritas,
    XFile? foto,
  }) async {
    state = const LaporCepatState(isLoading: true);
    try {
      final res = await _repository.submitLaporCepat(
        asetId: asetId,
        kodeAset: kodeAset,
        deskripsiMasalah: deskripsiMasalah,
        prioritas: prioritas,
        foto: foto,
      );

      final kode = res['kode']?.toString() ?? 'MNT';
      state = LaporCepatState(
        isLoading: false,
        successMessage: 'Laporan kerusakan $kode berhasil diterbitkan ke IPSRS.',
      );
      _ref.invalidate(daftarTiketUnitProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = LaporCepatState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }
}

final laporCepatProvider =
    StateNotifierProvider<LaporCepatNotifier, LaporCepatState>((ref) {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return LaporCepatNotifier(repository, ref);
});

class LembarKerjaState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const LembarKerjaState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class LembarKerjaNotifier extends StateNotifier<LembarKerjaState> {
  final MaintenanceRepository _repository;
  final Ref _ref;

  LembarKerjaNotifier(this._repository, this._ref) : super(const LembarKerjaState());

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

final lembarKerjaProvider =
    StateNotifierProvider<LembarKerjaNotifier, LembarKerjaState>((ref) {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return LembarKerjaNotifier(repository, ref);
});
