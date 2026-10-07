import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../distribusi/presentation/providers/distribusi_provider.dart';
import '../../../pengadaan/presentation/providers/pengadaan_provider.dart';
import '../../data/models/approval_item_model.dart';
import '../../data/repositories/approval_repository.dart';

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return ApprovalRepository(client);
});

final approvalPendingProvider =
    FutureProvider.autoDispose<ApprovalPendingResponse>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated || authState.user == null) {
    throw Exception('Pengguna belum terotentikasi');
  }
  final repository = ref.watch(approvalRepositoryProvider);
  return await repository.getPending();
});

class ApprovalActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ApprovalActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class ApprovalActionNotifier extends StateNotifier<ApprovalActionState> {
  final ApprovalRepository _repository;
  final Ref _ref;

  ApprovalActionNotifier(this._repository, this._ref)
      : super(const ApprovalActionState());

    Future<bool> eksekusi({
    required int id,
    required String tipe,
    required String aksi,
    String? catatan,
  }) async {
    if (tipe == 'PR') {
      return approvePr(id: id, aksi: aksi, catatan: catatan);
    } else {
      return approveAmprah(id: id, isSetujui: aksi == 'setujui', catatan: catatan);
    }
  }

  Future<bool> approvePr({
    required int id,
    required String aksi,
    String? catatan,
  }) async {
    state = const ApprovalActionState(isLoading: true);
    try {
      await _repository.executeApprovalPr(
        id: id,
        aksi: aksi,
        catatan: catatan,
      );
      String successMsg;
      if (aksi == 'serahkan' || aksi == 'teruskan') {
        successMsg = 'Permintaan Pengadaan berhasil diserahkan ke bagian pengadaan.';
      } else if (aksi == 'setujui') {
        successMsg = 'Permintaan Pengadaan berhasil disetujui.';
      } else {
        successMsg = 'Permintaan Pengadaan berhasil ditolak.';
      }
      state = ApprovalActionState(
        isLoading: false,
        successMessage: successMsg,
      );
      _ref.invalidate(approvalPendingProvider);
      _ref.invalidate(daftarPrProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString().replaceAll('ApiException: ', '');
      state = ApprovalActionState(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<bool> approveAmprah({
    required int id,
    required bool isSetujui,
    String? catatan,
  }) async {
    state = const ApprovalActionState(isLoading: true);
    try {
      await _repository.executeApprovalAmprah(
        id: id,
        isSetujui: isSetujui,
        catatan: catatan,
      );
      state = ApprovalActionState(
        isLoading: false,
        successMessage: isSetujui
            ? 'Amprah Ruangan berhasil disetujui.'
            : 'Amprah Ruangan berhasil ditolak.',
      );
      _ref.invalidate(approvalPendingProvider);
      _ref.invalidate(daftarAmprahProvider);
      final user = _ref.read(authStateProvider).user;
      final canPick = (user?.can('create_gudang_stok::picking::distribusi') ?? false) ||
          (user?.can('update_gudang_stok::picking::distribusi') ?? false) ||
          (user?.can('view_any_gudang_stok::picking::distribusi') ?? false) ||
          (user?.hasRole('petugas_gudang') ?? false) ||
          (user?.hasRole('kepala_gudang') ?? false) ||
          (user?.hasRole('admin_logistik') ?? false) ||
          (user?.isSuperAdmin ?? false);
      if (canPick) {
        _ref.invalidate(antreanPickingProvider);
      }
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString().replaceAll('ApiException: ', '');
      state = ApprovalActionState(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }
}

final approvalActionProvider =
    StateNotifierProvider<ApprovalActionNotifier, ApprovalActionState>((ref) {
  final repository = ref.watch(approvalRepositoryProvider);
  return ApprovalActionNotifier(repository, ref);
});
