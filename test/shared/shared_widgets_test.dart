import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/utils/app_formatters.dart';
import 'package:simlog_mobile/shared/widgets/app_error_view.dart';
import 'package:simlog_mobile/shared/widgets/app_filter_chip_bar.dart';
import 'package:simlog_mobile/shared/widgets/app_quantity_stepper.dart';
import 'package:simlog_mobile/shared/widgets/app_search_bar.dart';

void main() {
  group('AppFormatters Tests', () {
    test('formats rupiah correctly', () {
      expect(AppFormatters.rupiah(1500000), 'Rp 1.500.000');
      expect(AppFormatters.rupiah(0), 'Rp 0');
      expect(AppFormatters.rupiah(null), 'Rp 0');
    });

    test('formats tanggal display & db correctly', () {
      final dt = DateTime(2026, 9, 29);
      expect(AppFormatters.tanggal(dt), '29/09/2026');
      expect(AppFormatters.tanggalDb(dt), '2026-09-29');
      expect(AppFormatters.tanggalString('2026-09-29T10:00:00Z'), '29/09/2026');
    });
  });

  group('Shared Widgets Smoke Tests', () {
    testWidgets('AppSearchBar updates text and clears', (tester) async {
      String query = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchBar(
              hint: 'Cari barang...',
              onChanged: (val) => query = val,
            ),
          ),
        ),
      );

      expect(find.text('Cari barang...'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Paracetamol');
      await tester.pump();
      expect(query, 'Paracetamol');
    });

    testWidgets('AppFilterChipBar handles selection', (tester) async {
      String selected = 'A';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppFilterChipBar<String>(
                  selected: selected,
                  options: const [
                    AppFilterOption(label: 'Opsi A', value: 'A'),
                    AppFilterOption(label: 'Opsi B', value: 'B'),
                  ],
                  onSelected: (val) => setState(() => selected = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Opsi A'), findsOneWidget);
      expect(find.text('Opsi B'), findsOneWidget);
      await tester.tap(find.text('Opsi B'));
      await tester.pump();
      expect(selected, 'B');
    });

    testWidgets('AppQuantityStepper increments and decrements', (tester) async {
      int qty = 2;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppQuantityStepper(
                  value: qty,
                  min: 1,
                  max: 5,
                  onChanged: (val) => setState(() => qty = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pump();
      expect(qty, 3);
    });

    testWidgets('AppErrorView renders message and triggers retry', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              title: 'Koneksi Terputus',
              error: 'ApiException: Server timeout',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Koneksi Terputus'), findsOneWidget);
      expect(find.text('Server timeout'), findsOneWidget);
      await tester.tap(find.text('Coba Lagi'));
      expect(retried, isTrue);
    });
  });
}
