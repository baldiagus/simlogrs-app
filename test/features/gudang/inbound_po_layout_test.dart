import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/gudang/data/models/po_inbound_model.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/inbound_provider.dart';
import 'package:simlog_mobile/features/gudang/presentation/screens/inbound_po_list_screen.dart';

void main() {
  testWidgets('InboundPoListScreen renders without 22px overflow on narrow 320px viewport', (tester) async {
    final mockPos = [
      const PoInboundHeaderModel(
        id: 1,
        kodePo: 'PO-2026-09-0012-LONG',
        pemasok: 'PT. Medika Sejahtera Farma Indonesia Sentosa',
        tanggalPo: '24/09/2026',
        estimasiTanggalKirim: '28/09/2026',
        status: 'DITERBITKAN',
        totalItem: 15,
        items: [
          PoInboundItemModel(
            id: 1,
            barangId: 101,
            kodeBarang: 'KMD-001',
            namaBarang: 'Infusion Pump Terumo TE-112',
            satuan: 'Unit',
            jumlahDipesan: 10,
            jumlahSudahDiterima: 0,
            sisaKebutuhan: 10,
            hargaSatuan: 15000000,
          ),
        ],
      ),
      const PoInboundHeaderModel(
        id: 2,
        kodePo: 'PO-2026-09-0015',
        pemasok: 'CV. Sumber Alat Kesehatan',
        tanggalPo: '25/09/2026',
        estimasiTanggalKirim: null,
        status: 'DIKIRIM',
        totalItem: 3,
        items: [],
      ),
    ];

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          daftarPoInboundProvider.overrideWith((ref) => Future.value(mockPos)),
        ],
        child: const MaterialApp(
          home: InboundPoListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('PO-2026-09-0012-LONG'), findsOneWidget);
    expect(find.text('Menunggu Pengiriman'), findsOneWidget);
    expect(find.text('Siap Inbound'), findsOneWidget);
  });
}
