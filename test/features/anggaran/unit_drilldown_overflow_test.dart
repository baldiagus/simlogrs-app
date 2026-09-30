import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/anggaran/data/models/unit_drilldown_model.dart';
import 'package:simlog_mobile/features/anggaran/presentation/providers/anggaran_provider.dart';
import 'package:simlog_mobile/features/anggaran/presentation/widgets/unit_drilldown_sheet.dart';

void main() {
  testWidgets('UnitDrilldownSheet renders without overflow on narrow 320px viewport with long text', (tester) async {
    const mockDetail = UnitDrilldownModel(
      unitId: 1,
      unitKode: 'IGD',
      unitNama: 'Instalasi Gawat Darurat Sentral RSUD',
      tahun: '2026',
      bebanDistribusi: 15500000,
      bebanSparepart: 4200000,
      totalPengeluaran: 19700000,
      riwayatSppb: [
        SppbAnggaranItemModel(
          id: 1,
          kode: 'SPPB-20260930-0001-LONG-CODE',
          tanggalKirim: '2026-09-30',
          gudangNama: 'Gudang Farmasi & Logistik Sentral RSUD',
          status: 'DIKIRIM',
          totalItem: 15,
          totalNilai: 15500000,
        ),
      ],
      riwayatServis: [
        ServisAnggaranItemModel(
          id: 1,
          spkKode: 'SPK-2026-09-0012',
          asetNama: 'Mesin Anestesi Mindray Wato EX-65 Pro Lantai 2',
          sparepartNama: 'Sensor O2 Medis Paramagnetik Original Fabrik',
          jumlah: 2,
          subtotal: 4200000,
          tanggal: '2026-09-28',
        ),
      ],
    );

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unitDrilldownProvider((unitId: 1, tahun: '2026')).overrideWith(
            (ref) => Future.value(mockDetail),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: UnitDrilldownSheet(
              unitId: 1,
              tahun: '2026',
              unitNama: 'Instalasi Gawat Darurat Sentral RSUD',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('SPPB-20260930-0001-LONG-CODE'), findsOneWidget);
    expect(find.text('Sensor O2 Medis Paramagnetik Original Fabrik'), findsOneWidget);
  });
}
