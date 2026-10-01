import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/features/maintenance/data/models/spk_model.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/lembar_kerja_screen.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/master_barang_model.dart';
import 'package:simlog_mobile/shared/widgets/app_quantity_stepper.dart';

void main() {
  test('MasterBarangModel correctly parses stok from json', () {
    final json = {
      'id': 3,
      'kode': 'BRG-2026-003',
      'nama': 'Freon AC',
      'tipe': 'SPAREPART',
      'tipe_label': 'Suku Cadang IPSRS',
      'kategori': 'Suku Cadang & Sparepart IPSRS',
      'satuan': 'Botol Cairan',
      'merek': 'DuPont',
      'harga_estimasi': 180000,
      'stok': 4,
    };

    final model = MasterBarangModel.fromJson(json);
    expect(model.stok, equals(4));
    expect(model.tipe, equals('SPAREPART'));
  });

  testWidgets('LembarKerjaScreen renders sparepart section and info correctly', (tester) async {
    const dummySpk = SpkDetailModel(
      id: 1,
      kodeSpk: 'SPK-202610-001',
      status: 'DITUGASKAN',
      tanggalPenugasan: '2026-10-01',
      targetSelesai: '2026-10-03',
      teknisi: 'Agus Priyono',
      tiket: SpkTiketModel(
        kode: 'MNT-202610-001',
        prioritas: 'TINGGI',
        deskripsiMasalah: 'AC tidak dingin',
      ),
      aset: SpkAsetModel(
        kodeAset: 'AST-2026-001',
        nama: 'AC Split Daikin 2 PK',
        nomorSeri: 'DK-9921',
        lokasi: 'Rawat Inap Bedah',
      ),
      riwayatLog: [],
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LembarKerjaScreen(spk: dummySpk),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial screen rendered
    expect(find.text('Lembar Kerja: SPK-202610-001'), findsOneWidget);
    expect(find.text('Pemakaian Suku Cadang'), findsOneWidget);
    expect(find.text('Tidak ada suku cadang yang digunakan dalam perbaikan ini.'), findsOneWidget);
  });

  testWidgets('AppQuantityStepper enforces max limit and fires onMaxReached', (tester) async {
    int currentValue = 2;
    bool maxReachedTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AppQuantityStepper(
                value: currentValue,
                min: 1,
                max: 3,
                onMaxReached: () {
                  maxReachedTriggered = true;
                },
                onChanged: (val) {
                  setState(() {
                    currentValue = val;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    // Initial value is 2
    expect(find.text('2'), findsOneWidget);

    // Tap + to reach max (3)
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
    expect(currentValue, equals(3));
    expect(find.text('3'), findsOneWidget);

    // Tap + again when at max (3)
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();

    // Value must remain 3 and onMaxReached triggered
    expect(currentValue, equals(3));
    expect(maxReachedTriggered, isTrue);
  });
}
