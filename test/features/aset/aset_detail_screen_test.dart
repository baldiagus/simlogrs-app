import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/aset_detail_model.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/aset_detail_screen.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/histori_sirkulasi_aset_screen.dart';

void main() {
  testWidgets('AsetDetailScreen renders without overflow on narrow 320px viewport', (tester) async {
    const detail = AsetDetailModel(
      id: 1,
      kodeAset: 'AST-MED-2026-0001',
      nomorSeri: 'SN-VENT-9921',
      namaKomoditas: 'Ventilator Transport ICU Dewasa & Anak',
      kategori: 'Alat Kesehatan Medik',
      merek: 'Hamilton Medical',
      spesifikasi: 'Model T1, Battery Backup 4 Hours',
      status: 'DIPINJAM',
      kondisi: 'BAIK',
      lokasiTercatat: 'Ruang ICU Bedah Lt. 2',
      penanggungJawab: 'Ns. Ratna Sari, S.Kep',
      nilaiPerolehan: 450000000,
      tanggalPerolehan: '15/01/2024',
      totalRiwayatServis: 5,
      servisTerakhir: ServisTerakhirInfo(
        kode: 'SRV-2026-0312-PANJANG',
        status: 'SELESAI',
        prioritas: 'TINGGI',
        deskripsi: 'Kalibrasi sensor flow dan penggantian filter O2 berkala.',
        tanggalPengajuan: '20/09/2026',
      ),
      peminjamanAktif: PeminjamanAktifInfo(
        peminjamanId: 10,
        kodePinjam: 'PJM-2026-0044',
        unitPeminjam: 'Instalasi Gawat Darurat',
        tanggalKembaliRencana: '2026-10-01',
        isOverdue: false,
      ),
      riwayatPeminjaman: [
        RiwayatPeminjamanAsetItemModel(
          id: 1,
          kodePeminjaman: 'PINJ-2026-002',
          unitPeminjam: 'Instalasi Gawat Darurat',
          peminjam: 'dr. Pratama, Sp.EM',
          tanggalPinjam: '2026-09-24',
          tanggalKembaliRencana: '2026-10-01',
          tanggalKembaliAktual: '2026-09-24',
          status: 'SELESAI',
          keperluan: 'Peminjaman Darurat Pasien Syok Kardiogenik',
          kondisiSaatPinjam: 'BAIK',
          kondisiSaatKembali: 'BAIK',
          catatanPengembalian: 'Alat berfungsi normal dan telah disanitasi',
          pemeriksaKembali: 'dr. Pratama, Sp.EM',
        ),
      ],
    );

    // Set screen size to 320x640 (narrow constraint causing the original ~286px content width)
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AsetDetailScreen(initialAset: detail),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Histori Pemeliharaan (IPSRS)'), findsOneWidget);
    expect(find.text('5x Servis'), findsOneWidget);
    expect(find.text('Histori Sirkulasi (Peminjaman)'), findsOneWidget);
    expect(find.text('Kembalikan Fisik'), findsOneWidget);

    // Scroll down to the riwayat peminjaman card and tap
    final cardFinder = find.text('Histori Sirkulasi (Peminjaman)');
    await tester.scrollUntilVisible(cardFinder, 200);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    expect(find.byType(HistoriSirkulasiAsetScreen), findsOneWidget);
    expect(find.text('Buku Catatan Sirkulasi Unit'), findsOneWidget);
  });
}
