import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/aset_detail_model.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/aset_detail_screen.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/histori_pengalihan_aset_screen.dart';
import 'package:simlog_mobile/features/aset/presentation/widgets/aset_histori_pengalihan_card.dart';

void main() {
  const dummyTransfer = RiwayatPengalihanAsetItemModel(
    id: 10,
    pengalihanId: 55,
    kodePengalihan: 'TRF-202610-004',
    asalNama: 'Gudang Sentral Logistik Non-Medis',
    tujuanNama: 'Instalasi Gawat Darurat',
    tanggalPengalihan: '2026-10-06',
    tanggalSerahTerima: '2026-10-06 15:22',
    status: 'SELESAI',
    alasan: 'Alokasi alat operasional baru',
    kondisiSebelum: 'BAIK',
    kondisiSaatDiterima: 'BAIK',
    pengaju: 'Ns. Budi Santoso, S.Kep',
    penerima: 'Ns. Budi Santoso, S.Kep',
    catatan: 'Diterima lengkap dengan kabel power dan manual',
  );

  const dummyDetail = AsetDetailModel(
    id: 1,
    kodeAset: 'AST-2026-001',
    nomorSeri: 'SN-VENT-01',
    namaKomoditas: 'Ventilator Transport ICU',
    kategori: 'Alat Medis Kritis',
    merek: 'Hamilton',
    spesifikasi: 'Turbine driven portable ventilator',
    status: 'TERSEDIA',
    kondisi: 'BAIK',
    lokasiTercatat: 'Instalasi Gawat Darurat',
    penanggungJawab: 'dr. Pratama, Sp.EM',
    nilaiPerolehan: 350000000,
    tanggalPerolehan: '2025-01-15',
    totalRiwayatServis: 2,
    totalRiwayatPeminjaman: 1,
    totalRiwayatPengalihan: 1,
    riwayatPengalihan: [dummyTransfer],
  );

  testWidgets('AsetHistoriPengalihanCard renders transfer route and handles tap', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsetHistoriPengalihanCard(
            riwayat: const [dummyTransfer],
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Histori Pengalihan & Mutasi'), findsOneWidget);
    expect(find.text('1x Dimutasi'), findsOneWidget);
    expect(find.text('TRF-202610-004'), findsOneWidget);
    expect(find.text('Gudang Sentral Logistik Non-Medis'), findsOneWidget);
    expect(find.text('Instalasi Gawat Darurat'), findsOneWidget);
    expect(find.textContaining('15:22'), findsOneWidget);

    await tester.tap(find.byType(AsetHistoriPengalihanCard));
    expect(tapped, isTrue);
  });

  testWidgets('HistoriPengalihanAsetScreen renders timeline route and details on narrow 320px viewport without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HistoriPengalihanAsetScreen(
            asetId: 1,
            kodeAset: 'AST-2026-001',
            namaKomoditas: 'Ventilator Transport ICU',
            nomorSeri: 'SN-VENT-01',
            initialRiwayat: [dummyTransfer],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Histori Mutasi: AST-2026-001'), findsOneWidget);
    expect(find.text('1x Mutasi'), findsOneWidget);
    expect(find.text('TRF-202610-004'), findsOneWidget);
    expect(find.text('Gudang Sentral Logistik Non-Medis'), findsOneWidget);
    expect(find.text('Instalasi Gawat Darurat'), findsOneWidget);
    expect(find.textContaining('Ns. Budi Santoso, S.Kep'), findsWidgets);
    expect(find.textContaining('Alokasi alat operasional baru'), findsOneWidget);
  });

  testWidgets('AsetDetailScreen navigates to HistoriPengalihanAsetScreen when card is tapped', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AsetDetailScreen(initialAset: dummyDetail),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final cardFinder = find.byType(AsetHistoriPengalihanCard);
    expect(cardFinder, findsOneWidget);

    await tester.scrollUntilVisible(cardFinder, 200);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    expect(find.byType(HistoriPengalihanAsetScreen), findsOneWidget);
    expect(find.text('Jejak Kronologis Perpindahan Fisik'), findsOneWidget);
  });
}
