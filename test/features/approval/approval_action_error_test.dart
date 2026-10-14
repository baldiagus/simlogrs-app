import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/features/approval/data/repositories/approval_repository.dart';
import 'package:simlog_mobile/features/approval/presentation/providers/approval_provider.dart';

class FakeApprovalRepository extends Fake implements ApprovalRepository {
  @override
  Future<void> executeApprovalPr({
    required int id,
    required String aksi,
    String? catatan,
  }) async {
    throw ApiException(
      message: 'Anda hanya berhak mengesahkan atau menolak permintaan pengadaan dari unit ruangan Anda sendiri.',
      statusCode: 403,
    );
  }
}

void main() {
  test('ApprovalActionNotifier extracts clean ApiException message on 403 Forbidden', () async {
    final container = ProviderContainer(
      overrides: [
        approvalRepositoryProvider.overrideWithValue(FakeApprovalRepository()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(approvalActionProvider.notifier);
    final result = await notifier.approvePr(id: 12, aksi: 'setujui');

    expect(result, isFalse);
    final state = container.read(approvalActionProvider);
    expect(
      state.errorMessage,
      'Anda hanya berhak mengesahkan atau menolak permintaan pengadaan dari unit ruangan Anda sendiri.',
    );
  });

  test('approveAmprah mengirim aksi setujui/tolak beserta catatan ke repository', () async {
    final repo = RecordingApprovalRepository();
    final container = ProviderContainer(
      overrides: [approvalRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(approvalActionProvider.notifier);

    expect(await notifier.approveAmprah(id: 9, isSetujui: true), isTrue);
    expect(await notifier.approveAmprah(id: 9, isSetujui: false, catatan: 'Stok kosong'), isTrue);

    expect(repo.calls, ['9:true:null', '9:false:Stok kosong']);
  });
}

/// Repository palsu yang mencatat pemanggilan executeApprovalAmprah.
class RecordingApprovalRepository extends Fake implements ApprovalRepository {
  final List<String> calls = [];

  /// Mencatat id, keputusan, dan catatan tanpa memanggil jaringan.
  @override
  Future<void> executeApprovalAmprah({
    required int id,
    required bool isSetujui,
    String? catatan,
  }) async {
    calls.add('$id:$isSetujui:$catatan');
  }
}
