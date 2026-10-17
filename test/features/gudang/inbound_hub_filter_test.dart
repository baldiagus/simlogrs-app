import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/gudang/data/models/po_inbound_model.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/inbound_provider.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/widgets/pengadaan_hub_inbound_tab.dart';
import 'package:simlog_mobile/shared/widgets/app_filter_chip_bar.dart';

PoInboundHeaderModel _createDummyPoInbound({required String status}) {
  return PoInboundHeaderModel(
    id: 1,
    kodePo: 'PO-202610-001',
    pemasok: 'PT Vendor Jaya',
    tanggalPo: '2026-10-17',
    estimasiTanggalKirim: '2026-10-20',
    status: status,
    totalItem: 1,
    items: const [],
  );
}

void main() {
  group('inboundStatusFilterProvider', () {
    test("inboundStatusFilterProvider defaults to 'SEMUA'", () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(inboundStatusFilterProvider), 'SEMUA');
    });
  });

  group('PengadaanHubInboundTab filter chips', () {
    testWidgets(
      'renders AppFilterChipBar with chips: Semua Status, Siap Diterima, Diterima Sebagian, Diterima Lengkap, Menunggu Dikirim, Dibatalkan',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: PengadaanHubInboundTab(
                  inboundAsync: const AsyncValue.data([]),
                  query: '',
                  filter: 'SEMUA',
                  onQueryChanged: (_) {},
                  onFilterSelected: (_) {},
                  canReceiveInbound: true,
                  onTerima: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppFilterChipBar<String>), findsOneWidget);
        expect(find.text('Semua Status'), findsOneWidget);
        expect(find.text('Siap Diterima'), findsOneWidget);
        expect(find.text('Diterima Sebagian'), findsOneWidget);
        expect(find.text('Diterima Lengkap'), findsOneWidget);
        expect(find.text('Menunggu Dikirim'), findsOneWidget);
        expect(find.text('Dibatalkan'), findsOneWidget);
      },
    );

    testWidgets('selecting chip calls onFilterSelected', (tester) async {
      String? selected;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PengadaanHubInboundTab(
                inboundAsync: const AsyncValue.data([]),
                query: '',
                filter: 'SEMUA',
                onQueryChanged: (_) {},
                onFilterSelected: (val) => selected = val,
                canReceiveInbound: true,
                onTerima: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Siap Diterima'));
      await tester.pumpAndSettle();
      expect(selected, 'DIKIRIM_VENDOR');

      await tester.tap(find.text('Diterima Sebagian'));
      await tester.pumpAndSettle();
      expect(selected, 'DITERIMA_SEBAGIAN');

      await tester.ensureVisible(find.text('Diterima Lengkap'));
      await tester.tap(find.text('Diterima Lengkap'));
      await tester.pumpAndSettle();
      expect(selected, 'DITERIMA_LENGKAP');
    });
  });

  group('PengadaanHubInboundCard action visibility', () {
    testWidgets(
      "shows 'Periksa & Terima Barang' when item.canReceive is true",
      (tester) async {
        final item = _createDummyPoInbound(status: 'DIKIRIM_VENDOR');
        expect(item.canReceive, isTrue);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PengadaanHubInboundCard(
                item: item,
                canReceiveInbound: true,
                onTerima: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Periksa & Terima Barang'), findsOneWidget);
      },
    );

    testWidgets(
      "hides 'Periksa & Terima Barang' when status is DITERIMA_LENGKAP",
      (tester) async {
        final item = _createDummyPoInbound(status: 'DITERIMA_LENGKAP');
        expect(item.canReceive, isFalse);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PengadaanHubInboundCard(
                item: item,
                canReceiveInbound: true,
                onTerima: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Periksa & Terima Barang'), findsNothing);
      },
    );

    testWidgets(
      "hides 'Periksa & Terima Barang' when status is DITERBITKAN",
      (tester) async {
        final item = _createDummyPoInbound(status: 'DITERBITKAN');
        expect(item.canReceive, isFalse);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PengadaanHubInboundCard(
                item: item,
                canReceiveInbound: true,
                onTerima: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Periksa & Terima Barang'), findsNothing);
      },
    );
  });
}
