import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../approval/presentation/providers/approval_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../gudang/presentation/providers/gudang_provider.dart';
import '../../data/models/amprah_model.dart';
import '../../data/models/sppb_model.dart';
import '../../data/repositories/distribusi_repository.dart';

final distribusiRepositoryProvider = Provider<DistribusiRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return DistribusiRepository(client);
});

final katalogAmprahProvider =
    FutureProvider.autoDispose.family<List<BarangAmprahKatalogModel>, String>((ref, query) async {
  final repository = ref.watch(distribusiRepositoryProvider);
  return await repository.getKatalogBarang(cari: query);
});

class AmprahFilterParams {
  final String status;
  final String urgensi;

  const AmprahFilterParams({
    this.status = 'SEMUA',
    this.urgensi = 'SEMUA',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AmprahFilterParams &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          urgensi == other.urgensi;

  @override
  int get hashCode => status.hashCode ^ urgensi.hashCode;
}

final daftarAmprahProvider =
    FutureProvider.autoDispose.family<List<AmprahHeaderModel>, AmprahFilterParams>((ref, params) async {
  final repository = ref.watch(distribusiRepositoryProvider);
  return await repository.getDaftarAmprah(
    status: params.status,
    urgensi: params.urgensi,
  );
});

final detailAmprahProvider =
    FutureProvider.autoDispose.family<AmprahHeaderModel, int>((ref, id) async {
  final repository = ref.watch(distribusiRepositoryProvider);
  return await repository.getDetailAmprah(id);
});

final antreanPickingProvider =
    FutureProvider.autoDispose<List<PickingAntreanModel>>((ref) async {
  final user = ref.watch(authStateProvider).user;
  final canPick = (user?.can('create_gudang_stok::picking::distribusi') ?? false) ||
      (user?.can('update_gudang_stok::picking::distribusi') ?? false) ||
      (user?.can('view_any_gudang_stok::picking::distribusi') ?? false) ||
      (user?.hasRole('petugas_gudang') ?? false) ||
      (user?.hasRole('kepala_gudang') ?? false) ||
      (user?.hasRole('admin_logistik') ?? false) ||
      (user?.isSuperAdmin ?? false);

  if (!canPick) {
    return [];
  }

  final repository = ref.watch(distribusiRepositoryProvider);
  return await repository.getAntreanPicking();
});

final sppbInboundProvider =
    FutureProvider.autoDispose<List<SppbHeaderModel>>((ref) async {
  final repository = ref.watch(distribusiRepositoryProvider);
  return await repository.getSppbInbound();
});

class AmprahActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AmprahActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class AmprahActionNotifier extends StateNotifier<AmprahActionState> {
  final DistribusiRepository _repository;
  final Ref _ref;

  AmprahActionNotifier(this._repository, this._ref) : super(const AmprahActionState());

  Future<bool> submitAmprah({
    int? gudangId,
    required String urgensi,
    String? catatan,
    required List<AmprahCartDraftItem> items,
  }) async {
    if (items.isEmpty) {
      state = const AmprahActionState(
        errorMessage: 'Keranjang amprah masih kosong. Pilih minimal 1 barang.',
      );
      return false;
    }

    for (final item in items) {
      if (item.barang.stokTersedia <= 0) {
        state = AmprahActionState(
          errorMessage: 'Komoditas "${item.barang.nama}" di gudang saat ini kosong (0). Hapus barang ini sebelum mengirim.',
        );
        return false;
      }
      if (item.jumlah > item.barang.stokTersedia) {
        state = AmprahActionState(
          errorMessage: 'Jumlah diminta untuk "${item.barang.nama}" (${item.jumlah} ${item.barang.satuan}) melebihi stok gudang yang tersedia (${item.barang.stokTersedia} ${item.barang.satuan}).',
        );
        return false;
      }
    }

    state = const AmprahActionState(isLoading: true);
    try {
      final payload = items.map((e) => e.toSubmissionJson()).toList();
      final res = await _repository.submitAmprah(
        gudangId: gudangId,
        urgensi: urgensi,
        catatan: catatan,
        items: payload,
      );

      final kode = res['kode']?.toString() ?? 'REQ';
      state = AmprahActionState(
        isLoading: false,
        successMessage: 'Permintaan amprah $kode berhasil diajukan.',
      );

      _ref.invalidate(daftarAmprahProvider);
      _ref.invalidate(approvalPendingProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = AmprahActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  Future<bool> batalkanAmprah(int id) async {
    state = const AmprahActionState(isLoading: true);
    try {
      await _repository.batalAmprah(id);
      state = const AmprahActionState(
        isLoading: false,
        successMessage: 'Permintaan amprah berhasil dibatalkan.',
      );

      _ref.invalidate(daftarAmprahProvider);
      _ref.invalidate(approvalPendingProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = AmprahActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  Future<bool> eksekusiPicking(int permintaanId) async {
    state = const AmprahActionState(isLoading: true);
    try {
      final res = await _repository.eksekusiPicking(permintaanId);
      final sppbKode = res['sppb_kode']?.toString() ?? 'SPPB';
      state = AmprahActionState(
        isLoading: false,
        successMessage: 'Picking FEFO berhasil. Dokumen $sppbKode telah diterbitkan.',
      );

      _ref.invalidate(antreanPickingProvider);
      _ref.invalidate(sppbInboundProvider);
      _ref.invalidate(daftarRakProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = AmprahActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  Future<bool> konfirmasiTerimaSppb(int sppbId) async {
    state = const AmprahActionState(isLoading: true);
    try {
      final res = await _repository.konfirmasiTerimaSppb(sppbId);
      final rcvKode = res['kode_rcv']?.toString() ?? 'RCV';
      state = AmprahActionState(
        isLoading: false,
        successMessage: 'Barang berhasil diterima & masuk stok ruangan ($rcvKode).',
      );

      _ref.invalidate(sppbInboundProvider);
      _ref.invalidate(daftarAmprahProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = AmprahActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }
}

final amprahActionProvider =
    StateNotifierProvider<AmprahActionNotifier, AmprahActionState>((ref) {
  final repository = ref.watch(distribusiRepositoryProvider);
  return AmprahActionNotifier(repository, ref);
});
