import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:simlog_mobile/features/dashboard/presentation/widgets/hero_status_card.dart';

void main() {
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
}
