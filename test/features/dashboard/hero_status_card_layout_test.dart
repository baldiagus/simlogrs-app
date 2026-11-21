import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/theme/app_theme.dart';
import 'package:simlog_mobile/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:simlog_mobile/features/dashboard/presentation/widgets/hero_status_card.dart';

void main() {
  const metrics = [
    SubMetricModel(label: 'Temuan Aktif', nilai: '4'),
    SubMetricModel(label: 'Anomali PO', nilai: '3'),
    SubMetricModel(label: 'Selisih Stok', nilai: '2'),
  ];
  Future<void> showHero(WidgetTester tester, double width, double scale,
      {bool currency = false}) async {
    tester.view.physicalSize = Size(width, 762);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 762), textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: HeroStatusCard(
              summary: DashboardSummaryModel(
                hero: HeroMetricModel(
                  judul: 'Forensik & Kepatuhan',
                  total: currency ? 1234567890 : 4,
                  satuan: currency ? 'Rp' : 'Temuan',
                  labelTombol: 'Buka Audit SPI',
                  targetAksi: 'audit_spi',
                  subMetrik: currency
                      ? const [SubMetricModel(label: 'Pengeluaran Ruangan', nilai: 'Rp 1.234.567.890'), SubMetricModel(label: 'Suku Cadang IPSRS', nilai: 'Rp 987.654.321')]
                      : metrics,
                ),
                recentActivities: const [],
              ),
              onInspectPressed: () {},
            ),
          ),
        ),
      ),
    ));
  }

  for (final width in [343.0, 390.0]) {
    testWidgets('Short auditor metrics stay side by side at $width', (tester) async {
      await showHero(tester, width, 1);
      final first = tester.getTopLeft(find.text('4'));
      final second = tester.getTopLeft(find.text('3'));
      final third = tester.getTopLeft(find.text('2'));
      expect(first.dy, second.dy);
      expect(second.dy, third.dy);
      expect(first.dx, lessThan(second.dx));
      expect(second.dx, lessThan(third.dx));
      expect(tester.takeException(), isNull);
    });
  }
  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('Full currency metrics remain visible at scale $scale', (tester) async {
      await showHero(tester, 343, scale, currency: true);
      expect(find.text('Rp 1.234.567.890'), findsNWidgets(2));
      expect(find.text('Rp 987.654.321'), findsOneWidget);
      final card = tester.getRect(find.byType(HeroStatusCard));
      for (final value in ['Rp 1.234.567.890', 'Rp 987.654.321']) {
        for (final element in find.text(value).evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          expect(rect.left, greaterThanOrEqualTo(card.left));
          expect(rect.right, lessThanOrEqualTo(card.right));
        }
      }
      expect(tester.takeException(), isNull);
    });
  }
}
