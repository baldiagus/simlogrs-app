import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/distribusi/data/models/amprah_model.dart';
import 'package:simlog_mobile/features/distribusi/presentation/providers/distribusi_provider.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/detail_amprah_screen.dart';

void main() {
  testWidgets('DetailAmprahScreen displays partial delivery banner and backorder item metrics', (tester) async {
    const dummyAmprah = AmprahHeaderModel(
      id: 99,
      kode: 'REQ-202610-PARTIAL',
      unit: 'Rawat Inap 3',
      gudang: 'Gudang Logistik',
      pengaju: 'Karu Melati',
      tanggalPermintaan: '2026-10-06',
      urgensi: 'REGULER',
      status: 'DIKIRIM_SEBAGIAN',
      canCancel: false,
      jumlahItem: 1,
      items: [
        AmprahDetailItemModel(
          id: 10,
          barangId: 20,
          namaBarang: 'Infus Set Dewasa',
          kodeBarang: 'MED-INF-01',
          satuan: 'Pcs',
          jumlahDiminta: 10,
          jumlahDisetujui: 10,
          jumlahDikirim: 4,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailAmprahProvider(99).overrideWith((ref) => Future.value(dummyAmprah)),
        ],
        child: const MaterialApp(
          home: DetailAmprahScreen(amprahId: 99, kodeAmprah: 'REQ-202610-PARTIAL'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify partial shipment notice exists
    expect(find.textContaining('dikirim sebagian', findRichText: true), findsWidgets);
    // Verify Terkirim and Sisa Hutang metrics
    expect(find.textContaining('Terkirim: 4'), findsOneWidget);
    expect(find.textContaining('Sisa: 6'), findsOneWidget);
  });
}
