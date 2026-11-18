import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:simlog_mobile/features/dashboard/presentation/widgets/hero_status_card.dart';
import 'package:simlog_mobile/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Plus Jakarta Sans');
    for (final weight in [400, 500, 600, 700]) {
      loader.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'));
    }
    await loader.load();
  });
  var tapped = false;
  test('HeroMetricModel parses integer and float values without defaulting to 0', () {
    final jsonInt = {
      'judul': 'Pengeluaran Logistik & IPSRS',
      'total': 3300000,
      'satuan': 'Rp',
      'label_tombol': 'Pengeluaran RS',
      'target_aksi': 'pagu_realisasi',
      'sub_metrik': [],
    };
    final modelInt = HeroMetricModel.fromJson(jsonInt);
    expect(modelInt.total, equals(3300000));
    expect(modelInt.satuan, equals('Rp'));

    final jsonFloat = {
      'judul': 'Pengeluaran Logistik & IPSRS',
      'total': 3.3,
      'satuan': 'Jt Rp',
      'label_tombol': 'Pengeluaran RS',
      'target_aksi': 'pagu_realisasi',
      'sub_metrik': [],
    };
    final modelFloat = HeroMetricModel.fromJson(jsonFloat);
    expect(modelFloat.total, equals(3));
  });

  testWidgets('HeroStatusCard renders currency with Rp in front of nominal', (tester) async {
    const dummySummary = DashboardSummaryModel(
      hero: HeroMetricModel(
        judul: 'Pengeluaran Logistik & IPSRS',
        total: 3300000,
        satuan: 'Rp',
        labelTombol: 'Pengeluaran RS',
        targetAksi: 'pagu_realisasi',
        subMetrik: [
          SubMetricModel(label: 'Amprah Logistik', nilai: 'Rp 0', warna: 'teal'),
          SubMetricModel(label: 'Sparepart Servis', nilai: 'Rp 3.300.000', warna: 'purple'),
          SubMetricModel(label: 'Unit Terlayani', nilai: '9 Ruangan', warna: 'blue'),
        ],
      ),
      recentActivities: [],
    );

    bool inspectTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeroStatusCard(
            summary: dummySummary,
            onInspectPressed: () => inspectTapped = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title and button
    expect(find.text('Pengeluaran Logistik & IPSRS'), findsOneWidget);
    expect(find.text('Pengeluaran RS'), findsOneWidget);

    // Verify nominal formatted with Rp in front: Rp 3.300.000 (main hero and submetric)
    expect(find.text('Rp 3.300.000'), findsNWidgets(2));

    // Verify submetrics
    expect(find.text('Amprah Logistik'), findsOneWidget);
    expect(find.text('Sparepart Servis'), findsOneWidget);
    expect(find.text('9 Ruangan'), findsOneWidget);

    // Tap button
    await tester.tap(find.text('Pengeluaran RS'));
    await tester.pump();
    expect(inspectTapped, isTrue);
  });

  Future<void> showManagement(WidgetTester tester, {
    double width = 343,
    double scale = 1,
    String amprah = 'Rp 8.026.000',
    bool compact = true,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: HeroStatusCard(
            compactManagement: compact,
            summary: DashboardSummaryModel(
              hero: HeroMetricModel(
                judul: 'Pengeluaran Logistik & IPSRS',
                total: 15236000,
                satuan: 'Rp',
                labelTombol: 'Pengeluaran RS',
                targetAksi: 'pagu_realisasi',
                // Deliberately reordered: presentation must not use ordinals.
                subMetrik: [
                  const SubMetricModel(label: 'Unit Terlayani', nilai: '9 Ruangan'),
                  SubMetricModel(label: 'Amprah Logistik', nilai: amprah),
                  const SubMetricModel(label: 'Sparepart Servis', nilai: 'Rp 7.210.000'),
                ],
              ),
              recentActivities: const [],
            ),
            onInspectPressed: () => tapped = true,
          ),
        )),
      ),
    ));
  }

  for (final width in [343.0, 390.0]) {
    testWidgets('Management is compact with exact semantics at $width', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
      tapped = false;
      await showManagement(tester, width: width);
      expect(find.text('Rp 15.236.000'), findsOneWidget);
      expect(find.text('Rp 8,03 jt'), findsOneWidget);
      expect(find.text('Rp 7,21 jt'), findsOneWidget);
      final labels = ['Ruangan', 'Amprah', 'Servis'];
      final top = tester.getTopLeft(find.text(labels.first)).dy;
      for (final label in labels) {
        expect(tester.getTopLeft(find.text(label)).dy, top);
      }
      expect(tester.getTopLeft(find.text('Rincian')).dy,
          closeTo(tester.getTopLeft(find.text('Pengeluaran RS')).dy, 10));
      expect(find.bySemanticsLabel('Amprah Logistik: Rp 8.026.000'), findsOneWidget);
      expect(find.bySemanticsLabel('Unit Terlayani: 9 Ruangan'), findsOneWidget);
      await tester.tap(find.text('Rincian'));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final entry in {
    'Rp 0': 'Rp 0',
    'Rp 999': 'Rp 999',
    'Rp 1.000': 'Rp 1 rb',
    'Rp 999.995': 'Rp 1 jt',
    'Rp 999.995.000': 'Rp 1 mlr',
    'Rp 999.995.000.000': 'Rp 1 tr',
    'Rp 9.223.372.036.854.775.807': 'Rp 9223372,04 tr',
    'Rp 8.02.600': 'Rp 8.02.600',
    'Rp 8.026.000,50': 'Rp 8.026.000,50',
    'USD 8000': 'USD 8000',
    'unknown': 'unknown',
  }.entries) {
    testWidgets('Management monetary boundary ${entry.key}', (tester) async {
      await showManagement(tester, amprah: entry.key);
      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.5, 2.0]) {
    testWidgets('Management adapts to text scale $scale', (tester) async {
      await showManagement(tester, scale: scale);
      expect(find.text('Rp 15.236.000'), findsOneWidget);
      expect(find.text('Rp 8,03 jt'), findsOneWidget);
      expect(find.text('Rincian'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Other roles retain full labels and monetary values', (tester) async {
    await showManagement(tester, compact: false);
    expect(find.text('Amprah Logistik'), findsOneWidget);
    expect(find.text('Rp 8.026.000'), findsOneWidget);
    expect(find.text('9 Ruangan'), findsOneWidget);
    expect(find.text('Rincian'), findsNothing);
  });
}
