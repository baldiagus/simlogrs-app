import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/master/data/models/master_barang_entity.dart';
import 'package:simlog_mobile/features/master/presentation/widgets/detail_barang_sections.dart';

void main() {
  testWidgets('DetailBarangParamCard displays unlimited buffer stock as Tanpa Batas and unmasked price', (tester) async {
    const barang = MasterBarangItemModel(
      id: 3,
      kode: 'BRG-2026-003',
      nama: 'Freon AC',
      tipe: 'SPAREPART',
      tipeLabel: 'Suku Cadang IPSRS',
      kategori: 'Suku Cadang & Sparepart IPSRS',
      satuan: 'Pieces',
      simbolSatuan: 'Pcs',
      merek: '-',
      pemasok: '-',
      hargaBeliTerakhir: 20000,
      hargaEstimasi: 0,
      stokMinimum: 0,
      stokMaksimum: 0,
      titikPesan: 0,
      status: 'AKTIF',
      stokGudang: 0,
      stokRuangan: 0,
      totalAset: 0,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DetailBarangParamCard(b: barang),
          ),
        ),
      ),
    );

    expect(find.text('Parameter Logistik & Pengadaan'), findsOneWidget);
    expect(find.text('Belum ditentukan'), findsOneWidget);
    expect(find.text('Rp 20.000'), findsOneWidget);
    expect(find.text('- (Tanpa Batas)'), findsNWidgets(2)); // ROP and Min/Max
  });
}
