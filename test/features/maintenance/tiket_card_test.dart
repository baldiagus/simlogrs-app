import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/maintenance/data/models/tiket_maintenance_model.dart';
import 'package:simlog_mobile/features/maintenance/presentation/widgets/tiket_card_item.dart';

void main() {
  testWidgets('TiketCardItem does not overflow even on narrow widths with long names', (tester) async {
    const item = TiketMaintenanceModel(
      id: 1,
      kode: 'MNT-2026-9999-LONG-CODE',
      prioritas: 'CITO',
      status: 'DITUGASKAN',
      deskripsiMasalah: 'Masalah pada sistem ventilator oksigen yang sangat mendesak.',
      unit: 'Instalasi Gawat Darurat Sentral Lantai 1',
      pelapor: 'dr. Pratama Wijaya, Sp.An',
      canCancel: true,
      dibuatPada: '24/09/2026 16:30',
      aset: {
        'nama': 'Mesin Anestesi Sangat Panjang dan Lengkap Sekali',
        'kode_aset': 'AST-2026-9999',
        'nomor_seri': 'SN-LONG-SERIAL-123456789',
      },
      penugasanAktif: PenugasanAktifInfo(
        kodeSpk: 'SPK-2026-0099',
        namaTeknisi: 'Budi Santoso Teknisi Senior Spesialis Alat Berat Medis',
      ),
    );

    // Test in a very narrow constraint (270px width)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 270,
              child: TiketCardItem(
                item: item,
                onCancelTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('MNT-2026-9999-LONG-CODE'), findsOneWidget);
    expect(find.text('CITO'), findsOneWidget);
    expect(find.text('Batalkan'), findsOneWidget);
  });
}
