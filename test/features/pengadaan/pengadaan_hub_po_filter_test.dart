import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/po_model.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/providers/pengadaan_provider.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/widgets/approval_po_card.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/widgets/pengadaan_hub_po_tab.dart';
import 'package:simlog_mobile/shared/widgets/app_filter_chip_bar.dart';

PesananPembelianModel _createDummyPo({required String status}) {
  return PesananPembelianModel(
    id: 1,
    kode: 'PO-202610-001',
    pemasokId: 1,
    namaPemasok: 'PT Vendor Jaya',
    kodePemasok: 'VND-01',
    tanggalPo: '2026-10-17',
    estimasiTanggalKirim: '2026-10-20',
    totalBiaya: 1500000.0,
    syaratPembayaran: 'TEMPO_30_HARI',
    status: status,
    pembuat: 'Staf Pengadaan',
    totalItem: 1,
    items: const [],
  );
}

void main() {
  group('poStatusFilterProvider', () {
    test('defaults to SEMUA', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(poStatusFilterProvider), 'SEMUA');
    });
  });

  group('PengadaanHubPoTab', () {
    testWidgets('renders AppFilterChipBar with status filter options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PengadaanHubPoTab(
              poListAsync: const AsyncValue.data([]),
              query: '',
              filter: 'SEMUA',
              onQueryChanged: (_) {},
              onFilterSelected: (_) {},
              canManagePo: true,
              onUpdateKirim: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppFilterChipBar<String>), findsOneWidget);
      expect(find.text('Semua Status'), findsOneWidget);
      expect(find.text('Perlu Dikirim'), findsOneWidget);
      expect(find.text('Dikirim Vendor'), findsOneWidget);
      expect(find.text('Diterima Sebagian'), findsOneWidget);
      expect(find.text('Diterima Lengkap'), findsOneWidget);
      expect(find.text('Dibatalkan'), findsOneWidget);
    });

    testWidgets('selecting a chip invokes onFilterSelected', (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PengadaanHubPoTab(
              poListAsync: const AsyncValue.data([]),
              query: '',
              filter: 'SEMUA',
              onQueryChanged: (_) {},
              onFilterSelected: (val) => selected = val,
              canManagePo: true,
              onUpdateKirim: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Perlu Dikirim'));
      await tester.pumpAndSettle();
      expect(selected, 'DITERBITKAN');

      await tester.tap(find.text('Dikirim Vendor'));
      await tester.pumpAndSettle();
      expect(selected, 'DIKIRIM_VENDOR');

      await tester.ensureVisible(find.text('Diterima Lengkap'));
      await tester.tap(find.text('Diterima Lengkap'));
      await tester.pumpAndSettle();
      expect(selected, 'DITERIMA_LENGKAP');
    });

    testWidgets('shows empty state message when list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PengadaanHubPoTab(
              poListAsync: const AsyncValue.data([]),
              query: '',
              filter: 'SEMUA',
              onQueryChanged: (_) {},
              onFilterSelected: (_) {},
              canManagePo: true,
              onUpdateKirim: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Belum ada Purchase Order yang sesuai dengan kriteria filter atau pencarian.'),
        findsOneWidget,
      );
    });
  });

  group('ApprovalPoCard Action Visibility', () {
    testWidgets('shows Tandai Dikirim Vendor when po.isDiterbitkan && canManagePo', (tester) async {
      final po = _createDummyPo(status: 'DITERBITKAN');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApprovalPoCard(
              po: po,
              canManagePo: true,
              isReadOnly: false,
              onUpdateKirim: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tandai Dikirim Vendor'), findsOneWidget);
    });

    testWidgets('hides Tandai Dikirim Vendor when po is DITERBITKAN but canManagePo is false', (tester) async {
      final po = _createDummyPo(status: 'DITERBITKAN');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApprovalPoCard(
              po: po,
              canManagePo: false,
              isReadOnly: true,
              onUpdateKirim: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tandai Dikirim Vendor'), findsNothing);
    });

    testWidgets('hides Tandai Dikirim Vendor when status is DIKIRIM_VENDOR', (tester) async {
      final po = _createDummyPo(status: 'DIKIRIM_VENDOR');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApprovalPoCard(
              po: po,
              canManagePo: true,
              isReadOnly: false,
              onUpdateKirim: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tandai Dikirim Vendor'), findsNothing);
    });

    testWidgets('hides Tandai Dikirim Vendor when status is DITERIMA_LENGKAP', (tester) async {
      final po = _createDummyPo(status: 'DITERIMA_LENGKAP');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApprovalPoCard(
              po: po,
              canManagePo: true,
              isReadOnly: false,
              onUpdateKirim: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tandai Dikirim Vendor'), findsNothing);
    });
  });
}
