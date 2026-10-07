import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/gudang/data/models/po_inbound_model.dart';
import 'package:simlog_mobile/features/gudang/data/repositories/gudang_repository.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/gudang_provider.dart';
import 'package:simlog_mobile/features/gudang/presentation/widgets/modal_tolak_penerimaan_sheet.dart';

class FakeRejectGudangRepository extends Fake implements GudangRepository {
  bool tolakCalled = false;

  @override
  Future<Map<String, dynamic>> tolakPenerimaanPo({
    required int poId,
    required String nomorSuratJalan,
    required String alasanPenolakan,
    required List<Map<String, dynamic>> items,
  }) async {
    tolakCalled = true;
    return {
      'status': 'DITOLAK',
      'nomor_dokumen': 'RCV-REJ-202610-099',
    };
  }
}

void main() {
  const dummyPo = PoInboundHeaderModel(
    id: 10,
    kodePo: 'PO-202610-001',
    pemasok: 'PT Kimia Farma',
    tanggalPo: '2026-10-06',
    status: 'DIKIRIM_VENDOR',
    totalItem: 1,
    items: [],
  );

  testWidgets('ModalTolakPenerimaanSheet validates reason and executes rejection', (tester) async {
    final fakeRepo = FakeRejectGudangRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gudangRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ModalTolakPenerimaanSheet(
              po: dummyPo,
              nomorSuratJalanAwal: 'SJ-12345',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tolak Pengiriman Fisik'), findsOneWidget);

    final submitBtn = find.text('Terbitkan Surat Penolakan');
    expect(submitBtn, findsOneWidget);

    // Try submit without reason
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Still on page, didn't call repo yet
    expect(fakeRepo.tolakCalled, isFalse);

    // Enter reason
    await tester.enterText(
      find.byKey(const Key('field_alasan_penolakan')),
      'Barang basah dan segel rusak',
    );
    await tester.pumpAndSettle();

    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(fakeRepo.tolakCalled, isTrue);
    await tester.pump(const Duration(seconds: 4));
  });
}
