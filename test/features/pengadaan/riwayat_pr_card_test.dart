import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/pr_model.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/widgets/riwayat_pr_card_item.dart';

void main() {
  test('PrHeaderModel parses nomor_po and status_po correctly from JSON', () {
    final json = {
      'id': 2,
      'kode': 'PR-2026-002',
      'unit': 'Instalasi Gawat Darurat',
      'pengaju': 'Ns. Budi Santoso, S.Kep',
      'tanggal_permintaan': '2026-09-30',
      'urgensi': 'REGULER',
      'status': 'SELESAI',
      'nomor_po': 'PO-2026-002',
      'status_po': 'DITERIMA_LENGKAP',
      'jumlah_item': 1,
      'items': [],
    };

    final pr = PrHeaderModel.fromJson(json);
    expect(pr.nomorPo, 'PO-2026-002');
    expect(pr.statusPo, 'DITERIMA_LENGKAP');
    expect(pr.isSelesai, isTrue);
  });

  testWidgets('RiwayatPrCardItem renders formatted date and PO pill on 320px viewport without overflow', (tester) async {
    const prWithPo = PrHeaderModel(
      id: 2,
      kode: 'PR-2026-002',
      unit: 'Instalasi Gawat Darurat Sentral RSUD',
      pengaju: 'Ns. Budi Santoso, S.Kep',
      tanggalPermintaan: '2026-09-30',
      urgensi: 'REGULER',
      status: 'SELESAI',
      nomorPo: 'PO-2026-002',
      statusPo: 'DITERIMA_LENGKAP',
      jumlahItem: 1,
      items: [],
    );

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RiwayatPrCardItem(
            pr: prWithPo,
            canApproveKaru: false,
            canManagePo: false,
            onDetailTap: () {},
            onSetujuiTap: () {},
            onTolakTap: () {},
            onTeruskanTap: () {},
            onTerbitkanPoTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Verifikasi tanggal baku terformat 30/09/2026
    expect(find.textContaining('30/09/2026'), findsOneWidget);
    // Verifikasi chip nomor PO
    expect(find.text('PO-2026-002'), findsOneWidget);
    // Verifikasi status badge SELESAI
    expect(find.text('SELESAI'), findsOneWidget);
  });
}
