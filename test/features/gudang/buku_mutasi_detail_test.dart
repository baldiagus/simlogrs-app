import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/gudang/data/models/buku_mutasi_model.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/persediaan_providers.dart';
import 'package:simlog_mobile/features/gudang/presentation/screens/buku_mutasi_screen.dart';

void main() {
  for (final size in [const Size(360, 800), const Size(402, 817), const Size(1280, 800)]) {
    testWidgets('mutation detail preserves hidden information at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const item = BukuMutasiItemModel(
        id: 1, tanggal: '2026-11-14 10:20', jenis: 'KELUAR', barangId: 1,
        kodeBarang: 'BRG-001', namaBarang: 'Sungkup Oksigen Non-Rebreathing Mask Dewasa untuk Pelayanan Gawat Darurat',
        satuan: 'Pcs', nomorBatch: 'BATCH-2609', gudang: 'Gudang Sentral Logistik Non-Medis',
        lokasiRak: 'Rak B6 - Selang Oksigen dan Nasal Kanul', jumlah: 1,
        saldoSebelum: 20, saldoSesudah: 19, referensiJenis: 'SPPB', referensiId: 42,
        keterangan: 'Pengeluaran FEFO untuk Instalasi Gawat Darurat', petugas: 'Hendra Kusuma, S.T.',
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [bukuMutasiListProvider.overrideWith((ref) async => [item])],
        child: MaterialApp(home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: const TextScaler.linear(1.3)),
          child: const BukuMutasiScreen(),
        )),
      ));
      await tester.pumpAndSettle();
      expect(find.text(item.keterangan), findsNothing);
      await tester.tap(find.text('Detail ›'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Mutasi Stok'), findsOneWidget);
      expect(find.text(item.lokasiRak), findsOneWidget);
      await tester.scrollUntilVisible(find.text(item.petugas), 250,
          scrollable: find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).last);
      expect(find.text(item.petugas), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Tutup detail mutasi'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Mutasi Stok'), findsNothing);
    });
  }
}
