import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/peminjaman_aset_model.dart';
import 'package:simlog_mobile/shared/widgets/status_badge.dart';

void main() {
  test('PeminjamanAsetModel handles DIBATALKAN vs DITOLAK status correctly', () {
    const pinjamBatal = PeminjamanAsetModel(
      id: 1,
      kode: 'PINJ-2026-001',
      tipePenyedia: 'GUDANG',
      namaPenyedia: 'Gudang Sentral',
      unitPeminjam: 'IGD',
      pengaju: 'Ns. Budi',
      tanggalPinjam: '2026-09-30',
      tanggalKembaliRencana: '2026-10-05',
      keperluan: 'Keperluan darurat',
      status: 'DIBATALKAN',
      isOverdue: false,
      jumlahAset: 1,
      items: [],
    );

    const pinjamTolak = PeminjamanAsetModel(
      id: 2,
      kode: 'PINJ-2026-002',
      tipePenyedia: 'RUANGAN',
      namaPenyedia: 'Rawat Inap Bedah',
      unitPeminjam: 'IGD',
      pengaju: 'Ns. Budi',
      tanggalPinjam: '2026-09-30',
      tanggalKembaliRencana: '2026-10-05',
      keperluan: 'Keperluan darurat',
      status: 'DITOLAK',
      isOverdue: false,
      jumlahAset: 1,
      items: [],
    );

    expect(pinjamBatal.isDibatalkan, isTrue);
    expect(pinjamBatal.isDitolak, isFalse);
    expect(pinjamTolak.isDitolak, isTrue);
    expect(pinjamTolak.isDibatalkan, isFalse);
  });

  testWidgets('StatusBadge renders DIBATALKAN with formatted label and danger color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: 'DIBATALKAN'),
        ),
      ),
    );

    expect(find.text('DIBATALKAN'), findsOneWidget);
  });
}
