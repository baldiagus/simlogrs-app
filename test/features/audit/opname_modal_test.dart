import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';
import 'package:simlog_mobile/features/audit/presentation/widgets/opname_detail_sheet.dart';
import 'package:simlog_mobile/features/audit/presentation/widgets/tabs/selisih_opname_tab.dart';

SesiOpnameSelisihModel session(int id, {bool empty = false}) =>
    SesiOpnameSelisihModel.fromJson({
      'id': id,
      'kode': 'SO-$id',
      'gudang': 'Gudang $id',
      'petugas': 'Petugas $id',
      'total_batch_selisih': 3,
      'details': empty ? [] : [
        {
          'id': id,
          'nama_barang': 'Barang sesi $id',
          'nomor_batch': 'B-$id',
          'jumlah_sistem': 10,
          'jumlah_fisik': 7,
          'selisih': -3,
          'satuan': 'Kotak',
        },
      ],
    });

Future<void> mount(WidgetTester tester, List<SesiOpnameSelisihModel> sessions) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      selisihOpnameProvider.overrideWith((ref) async => {
        'sesi_opname': sessions,
        'penyesuaian': <PenyesuaianStokAuditModel>[],
      }),
    ],
    child: const MaterialApp(home: Scaffold(body: SelisihOpnameTab())),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cards hide details and open only the selected session', (tester) async {
    await mount(tester, [session(1), session(2)]);
    expect(find.text('Barang sesi 1'), findsNothing);
    expect(find.text('Barang sesi 2'), findsNothing);
    await tester.tap(find.text('SO-2'));
    await tester.pumpAndSettle();
    expect(find.byType(OpnameDetailSheet), findsOneWidget);
    expect(find.text('Barang sesi 2'), findsOneWidget);
    expect(find.text('Barang sesi 1'), findsNothing);
    expect(find.text('10 Kotak'), findsOneWidget);
    expect(find.text('7 Kotak'), findsOneWidget);
    expect(find.text('Kekurangan 3 Kotak'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(OpnameDetailSheet), findsNothing);
    await tester.tap(find.text('SO-1'));
    await tester.pumpAndSettle();
    expect(find.text('Barang sesi 1'), findsOneWidget);
    expect(find.text('Barang sesi 2'), findsNothing);
  });

  testWidgets('rapid trigger taps open one sheet and empty details are honest', (tester) async {
    await mount(tester, [session(1, empty: true)]);
    await tester.tap(find.text('SO-1'));
    await tester.tap(find.text('SO-1'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(OpnameDetailSheet), findsOneWidget);
    expect(find.text('Rincian sesi belum tersedia'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(OpnameDetailSheet), findsNothing);
  });

  testWidgets('closing a session preserves the main list scroll position', (tester) async {
    await mount(tester, List.generate(20, (index) => session(index)));
    await tester.scrollUntilVisible(find.text('SO-12'), 250,
        scrollable: find.byType(Scrollable).first);
    // scrollUntilVisible ends with ensureVisible, which updates the scroll
    // offset before the next layout. Measure the settled viewport, not stale
    // render coordinates from the preceding drag frame.
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 180));
    await tester.pumpAndSettle();
    final scrollPosition = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    ).position;
    final offsetBefore = scrollPosition.pixels;
    final before = tester.getTopLeft(find.text('SO-12'));
    await tester.tap(find.text('SO-12'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('SO-12')), before);
    expect(scrollPosition.pixels, offsetBefore);
    expect(find.text('Barang sesi 12'), findsNothing);
  });
}
