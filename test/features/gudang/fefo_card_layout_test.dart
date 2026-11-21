import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/gudang/data/models/fefo_monitoring_model.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/persediaan_providers.dart';
import 'package:simlog_mobile/features/gudang/presentation/screens/fefo_monitoring_screen.dart';

void main() {
  for (final size in [const Size(360, 800), const Size(402, 817), const Size(1280, 800)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('FEFO long location remains available at $size scale $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const data = FefoMonitoringResponse(
          metrik: FefoMetrikModel(countExpired: 0, countKritis30: 0, countPeringatan90: 0, countRop: 86, totalBatchAktif: 1),
          items: [FefoBatchItemModel(id: 1, nomorBatch: 'BATCH-OM-2605C', barangId: 1,
            kodeBarang: 'BRG-001', namaBarang: 'Hand Sanitizer Gel 500ml Pump',
            kategori: 'Disinfektan & Antiseptik Medis', satuan: 'Btl',
            gudang: 'Gudang Sentral Logistik Non-Medis',
            lokasiRak: 'Rak B2 - Sabun Antiseptik dan Hand Sanitizer',
            tanggalKedaluwarsa: '2027-11-01', jumlah: 22, hargaSatuan: 32000,
            nilaiTotal: 704000, statusFefo: 'AMAN')]);
        await tester.pumpWidget(ProviderScope(overrides: [
          fefoMonitoringProvider.overrideWith((ref) async => data),
        ], child: MaterialApp(builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!), home: const FefoMonitoringScreen())));
        await tester.pumpAndSettle();
        expect(find.text('Rak B2 - Sabun Antiseptik dan Hand Sanitizer'), findsNothing);
        await tester.scrollUntilVisible(find.text('Detail'), 200,
          scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Detail'));
        await tester.pumpAndSettle();
        expect(find.text('Detail Stok FEFO'), findsOneWidget);
        expect(find.text('Stok tersedia'), findsOneWidget);
        expect(find.text('Nilai persediaan'), findsOneWidget);
        expect(find.text('Rak B2 - Sabun Antiseptik dan Hand Sanitizer'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Tutup detail FEFO'));
        await tester.pumpAndSettle();
        expect(find.text('Detail Stok FEFO'), findsNothing);
      });
    }
  }
}
