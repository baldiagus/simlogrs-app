import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/features/approval/data/models/approval_item_model.dart';
import 'package:simlog_mobile/features/approval/data/repositories/approval_repository.dart';
import 'package:simlog_mobile/features/approval/presentation/providers/approval_provider.dart';
import 'package:simlog_mobile/features/approval/presentation/widgets/approval_action_modal.dart';

class RejectingApprovalRepository extends Fake implements ApprovalRepository {
  @override
  Future<void> executeApprovalPr({
    required int id,
    required String aksi,
    String? catatan,
  }) async {
    throw ApiException(
      message: 'Anda hanya berhak mengesahkan permintaan unit ruangan sendiri.',
      statusCode: 403,
    );
  }
}

void main() {
  testWidgets('ApprovalActionModal displays error toast when 403 is received', (tester) async {
    const item = ApprovalItemModel(
      id: 1,
      kode: 'PR-202610-001',
      unit: 'IGD',
      pengaju: 'Dr. John',
      tanggal: '2026-10-06',
      urgensi: 'REGULER',
      tipe: 'PR',
      status: 'DIAJUKAN',
      jumlahItem: 0,
      items: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          approvalRepositoryProvider.overrideWithValue(RejectingApprovalRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ApprovalActionModal(item: item, aksi: 'setujui'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final btn = find.text('Ya, Setujui');
    expect(btn, findsOneWidget);

    await tester.tap(btn);
    await tester.pumpAndSettle();

    // Verify error toast message appears
    expect(
      find.textContaining('Anda hanya berhak mengesahkan permintaan unit ruangan sendiri.'),
      findsOneWidget,
    );

    // Advance timer to let toast dismiss cleanly
    await tester.pump(const Duration(seconds: 4));
  });
}
