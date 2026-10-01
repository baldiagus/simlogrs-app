import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/tiket_maintenance_model.dart';
import '../../data/models/teknisi_option_model.dart';
import '../../data/repositories/maintenance_repository.dart';
import 'maintenance_provider.dart';

class TiketFilterParams {
  final String status;
  final String prioritas;
  final String cari;

  const TiketFilterParams({
    this.status = 'SEMUA',
    this.prioritas = 'SEMUA',
    this.cari = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TiketFilterParams &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          prioritas == other.prioritas &&
          cari == other.cari;

  @override
  int get hashCode => status.hashCode ^ prioritas.hashCode ^ cari.hashCode;
}

final daftarTiketUnitProvider =
    FutureProvider.autoDispose.family<List<TiketMaintenanceModel>, TiketFilterParams>((ref, params) async {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return await repository.getDaftarTiketUnit(
    status: params.status,
    prioritas: params.prioritas,
    cari: params.cari,
  );
});

final asetUnitTersediaProvider =
    FutureProvider.autoDispose<List<AsetUnitModel>>((ref) async {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return await repository.getAsetUnitTersedia();
});

final detailTiketUnitProvider =
    FutureProvider.autoDispose.family<TiketDetailModel, int>((ref, id) async {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return await repository.getDetailTiketUnit(id);
});

final teknisiListProvider =
    FutureProvider.autoDispose<List<TeknisiOptionModel>>((ref) async {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return await repository.getDaftarTeknisi();
});

class TiketActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const TiketActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class TiketActionNotifier extends StateNotifier<TiketActionState> {
  final MaintenanceRepository _repository;
  final Ref _ref;

  TiketActionNotifier(this._repository, this._ref) : super(const TiketActionState());

  Future<bool> batalkanTiket(int id) async {
    state = const TiketActionState(isLoading: true);
    try {
      await _repository.batalTiketUnit(id);
      state = const TiketActionState(
        isLoading: false,
        successMessage: 'Laporan kerusakan berhasil dibatalkan.',
      );

      _ref.invalidate(daftarTiketUnitProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = TiketActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  Future<bool> disposisiTiket({
    required int tiketId,
    required int teknisiId,
    String? tanggalPenugasan,
    String? targetSelesai,
    String? instruksiKhusus,
  }) async {
    state = const TiketActionState(isLoading: true);
    try {
      final res = await _repository.disposisiTiket(
        tiketId: tiketId,
        teknisiId: teknisiId,
        tanggalPenugasan: tanggalPenugasan,
        targetSelesai: targetSelesai,
        instruksiKhusus: instruksiKhusus,
      );

      final kodeSpk = res['kode_spk']?.toString() ?? 'SPK';
      final namaTeknisi = res['teknisi']?.toString() ?? 'Teknisi';
      state = TiketActionState(
        isLoading: false,
        successMessage: 'SPK $kodeSpk berhasil diterbitkan dan ditugaskan ke $namaTeknisi.',
      );

      _ref.invalidate(daftarTiketUnitProvider);
      _ref.invalidate(detailTiketUnitProvider(tiketId));
      _ref.invalidate(spkListProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = TiketActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }
}

final tiketActionProvider =
    StateNotifierProvider<TiketActionNotifier, TiketActionState>((ref) {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return TiketActionNotifier(repository, ref);
});
