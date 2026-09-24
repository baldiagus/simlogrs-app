import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/approval_item_model.dart';
import '../../data/repositories/approval_repository.dart';

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return ApprovalRepository(client);
});

final approvalPendingProvider =
    FutureProvider.autoDispose<ApprovalPendingResponse>((ref) async {
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
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = ApprovalActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
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
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = ApprovalActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
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
