import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/shared/widgets/app_search_bar.dart';

/// Memasang AppSearchBar di dalam MaterialApp untuk pengujian.
Future<void> _pump(
  WidgetTester tester, {
  required ValueChanged<String> onChanged,
  VoidCallback? onClear,
  Duration? debounce,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: debounce == null
            ? AppSearchBar(onChanged: onChanged, onClear: onClear)
            : AppSearchBar(onChanged: onChanged, onClear: onClear, debounce: debounce),
      ),
    ),
  );
}

void main() {
  group('AppSearchBar debounce', () {
    testWidgets('menunda onChanged 300ms lalu memanggil sekali dengan teks akhir', (tester) async {
      final calls = <String>[];
      await _pump(tester, onChanged: calls.add);

      await tester.enterText(find.byType(TextField), 'a');
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 299));
      expect(calls, isEmpty);

      await tester.pump(const Duration(milliseconds: 2));
      expect(calls, ['abc']);
    });

    testWidgets('tombol hapus memanggil onChanged kosong dan onClear segera, tanpa panggilan tertunda', (tester) async {
      final calls = <String>[];
      var cleared = 0;
      await _pump(tester, onChanged: calls.add, onClear: () => cleared++);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(calls, ['']);
      expect(cleared, 1);

      await tester.pump(const Duration(seconds: 1));
      expect(calls, ['']);
    });

    testWidgets('debounce Duration.zero memanggil langsung', (tester) async {
      final calls = <String>[];
      await _pump(tester, onChanged: calls.add, debounce: Duration.zero);

      await tester.enterText(find.byType(TextField), 'abc');
      expect(calls, ['abc']);
    });
  });
}
