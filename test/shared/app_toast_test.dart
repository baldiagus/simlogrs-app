import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/shared/widgets/app_toast.dart';

void main() {
  testWidgets('AppToast renders at top and automatically disappears after 3 seconds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                AppToast.success(ctx, 'Penerimaan berhasil disimpan');
              },
              child: const Text('Show Toast'),
            ),
          ),
        ),
      ),
    );

    // Initial state: no toast
    expect(find.text('Penerimaan berhasil disimpan'), findsNothing);

    // Tap button to show toast
    await tester.tap(find.text('Show Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // Animation in

    // Toast is visible at the top
    expect(find.text('Penerimaan berhasil disimpan'), findsOneWidget);

    // Advance 2 seconds (not yet disappeared)
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Penerimaan berhasil disimpan'), findsOneWidget);

    // Advance remaining 1.5 seconds (total > 3s)
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Toast has disappeared
    expect(find.text('Penerimaan berhasil disimpan'), findsNothing);
  });

  testWidgets('AppToast disappears immediately on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                AppToast.error(ctx, 'Gagal memproses data');
              },
              child: const Text('Show Error Toast'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Error Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Gagal memproses data'), findsOneWidget);

    // Tap toast to dismiss early
    await tester.tap(find.text('Gagal memproses data'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal memproses data'), findsNothing);
  });
}
