import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/maintenance/data/models/rekam_medis_aset_model.dart';
import 'package:simlog_mobile/features/maintenance/presentation/providers/ipsrs_providers.dart';
import 'package:simlog_mobile/features/maintenance/presentation/screens/rekam_medis_detail_screen.dart';

void main() {
  testWidgets('RekamMedisDetailScreen renders without overflow on narrow 320px viewport', (tester) async {
    const mockDetail = RekamMedisDetailResponse(
      identitas: {
        'id': 1,
        'kode_aset': 'AST-MED-2026-0001',
        'nama_sarana': 'Ventilator Transport ICU Dewasa & Anak',
        'nomor_seri': 'SN-VENT-9921',
        'merek': 'Hamilton Medical',
        'status': 'TERSEDIA',
        'lokasi': 'Ruang Rawat Inap Melati 3 Bed B',
        'total_servis': 12,
      },
      riwayatServis: [
        RekamMedisServisEntryModel(
          id: 1,
          kodeTiket: 'TKT-2026-09-0012',
          tanggalLapor: '20/09/2026',
          pelapor: 'dr. Pratama Wijaya',
          deskripsiMasalah: 'Alarm error sensor flow berbunyi terus menerus saat dinyalakan',
          prioritas: 'TINGGI',
          statusTiket: 'SELESAI',
          kodeSpk: 'SPK-2026-09-0044',
          teknisi: 'Budi Santoso Teknisi IPSRS',
          tanggalPenugasan: '20/09/2026',
          statusSpk: 'SELESAI',
          diagnosa: 'Sensor kotor akibat residu kelembaban',
          tindakan: 'Pembersihan dan kalibrasi ulang sensor',
          hasilPengerjaan: 'Alat berfungsi normal',
          tanggalSelesai: '20/09/2026',
          sukuCadang: [],
        ),
      ],
      jadwalPreventif: [
        {
          'id': 10,
          'kode': 'PRV-2026-10-001',
          'jenis_maintenance': 'Kalibrasi Berkala 6 Bulanan',
          'interval': '6 Bulan Sekali',
          'tanggal_berikutnya': '2026-10-15',
          'teknisi': 'Budi Santoso Teknisi IPSRS',
          'status': 'AKTIF',
        },
      ],
    );

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rekamMedisDetailProvider(1).overrideWith((ref) => Future.value(mockDetail)),
        ],
        child: const MaterialApp(
          home: RekamMedisDetailScreen(asetId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('AST-MED-2026-0001'), findsOneWidget);
    expect(find.text('12x Servis Dicatat'), findsOneWidget);

    // Switch to Tab 1 (Preventif) and verify no overflow
    await tester.tap(find.text('Preventif (1)'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('PRV-2026-10-001'), findsOneWidget);
    expect(find.text('Kalibrasi Berkala 6 Bulanan'), findsOneWidget);
  });
}
