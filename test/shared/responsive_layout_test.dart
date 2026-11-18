import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/shared/widgets/app_bottom_sheet_wrapper.dart';
import 'package:simlog_mobile/shared/widgets/app_quantity_stepper.dart';
import 'package:simlog_mobile/shared/widgets/custom_button.dart';
import 'package:simlog_mobile/shared/widgets/floating_bottom_nav_bar.dart';

Future<void> _pumpCompact(
  WidgetTester tester,
  Widget child, {
  double scale = 2,
  double height = 762,
  double keyboardInset = 0,
}) async {
  tester.view.physicalSize = Size(343, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        textTheme: const TextTheme(
          labelLarge: TextStyle(fontSize: 14),
          labelSmall: TextStyle(fontSize: 12),
          titleSmall: TextStyle(fontSize: 14),
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
        ),
        child: child!,
      ),
      home: Scaffold(body: child),
    ),
  );
}

void _expectCompleteLabel(WidgetTester tester, String label) {
  final finder = find.text(label);
  expect(finder, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  expect(paragraph.didExceedMaxLines, isFalse);
  expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
  // Selection boxes include invisible trailing spaces at soft line breaks.
  // Those spaces can extend beyond the centered line's layout width; measure
  // every non-whitespace run so the bounds assertion checks painted glyphs.
  final runs = RegExp(r'\S+').allMatches(label).toList();
  expect(runs, isNotEmpty);
  for (final run in runs) {
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: run.start, extentOffset: run.end),
    );
    expect(boxes, isNotEmpty);
    for (final box in boxes) {
      expect(box.left, greaterThanOrEqualTo(-0.1));
      expect(box.right, lessThanOrEqualTo(paragraph.size.width + 0.1));
      expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + 0.1));
    }
  }
}

void main() {
  for (final outlined in [false, true]) {
    testWidgets('icon action wraps fully at 343px/200%, outlined=$outlined',
        (tester) async {
      const label = 'Simpan dan Terbitkan Permintaan Pengadaan';
      var presses = 0;
      await _pumpCompact(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            text: label,
            icon: const Icon(Icons.check),
            isOutlined: outlined,
            onPressed: () => presses++,
          ),
        ),
      );
      _expectCompleteLabel(tester, label);
      expect(tester.getSize(find.byType(CustomButton)).height, greaterThan(50));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(label));
      expect(presses, 1);
    });
  }

  testWidgets('navigation labels remain complete and tappable at 343px/200%',
      (tester) async {
    var selected = -1;
    await _pumpCompact(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: FloatingBottomNavBar(
          currentIndex: 0,
          items: const [
            BottomNavItem(icon: Icons.home, label: 'Beranda'),
            BottomNavItem(icon: Icons.shopping_bag, label: 'Pengadaan'),
            BottomNavItem(icon: Icons.checklist, label: 'Semua SPK'),
            BottomNavItem(icon: Icons.person, label: 'Profil'),
          ],
          onTap: (index) => selected = index,
          onScanPressed: () {},
        ),
      ),
    );
    for (final label in ['Beranda', 'Pengadaan', 'Semua SPK', 'Profil']) {
      _expectCompleteLabel(tester, label);
      final bounds = tester.getRect(find.text(label));
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(343));
      expect(bounds.bottom, lessThanOrEqualTo(762));
    }
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Pengadaan'));
    expect(selected, 1);
  });

  testWidgets('sheet scrolls legacy Flexible content above keyboard',
      (tester) async {
    var saved = false;
    await _pumpCompact(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: AppBottomSheetWrapper(
          title: 'Judul formulir panjang yang harus tetap dapat dibaca',
          maxHeightFactor: 0.9,
          child: Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 12; i++) Text('Informasi formulir $i'),
                  CustomButton(
                    text: 'Simpan Formulir',
                    onPressed: () => saved = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      height: 600,
      keyboardInset: 240,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Simpan Formulir'));
    await tester.pumpAndSettle();
    final actionBounds = tester.getRect(find.text('Simpan Formulir'));
    expect(actionBounds.bottom, lessThanOrEqualTo(360));
    await tester.tap(find.text('Simpan Formulir'));
    expect(saved, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fixed sheet keeps heading visible while reaching last item',
      (tester) async {
    await _pumpCompact(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: AppBottomSheetWrapper(
          fixedHeader: true,
          title: 'Rincian Selisih Opname',
          subtitle: 'OPN-202610-001',
          maxHeightFactor: .9,
          child: Column(
            children: [
              for (var i = 0; i < 30; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Batch barang $i'),
                ),
            ],
          ),
        ),
      ),
    );
    final headingY = tester.getTopLeft(find.text('Rincian Selisih Opname')).dy;
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -4000));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Rincian Selisih Opname')).dy, headingY);
    expect(find.text('Batch barang 29').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quantity accommodates long values and narrow constraints',
      (tester) async {
    await _pumpCompact(
      tester,
      Center(
        child: SizedBox(
          width: 140,
          child: AppQuantityStepper(value: 123456789, onChanged: (_) {}),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '123456789');
    expect(tester.getSize(find.byType(AppQuantityStepper)).width, 140);
    expect(tester.getTopLeft(find.byTooltip('Tambah jumlah')).dy,
        greaterThan(tester.getTopLeft(find.byType(TextField)).dy));
    expect(tester.takeException(), isNull);
  });
}
