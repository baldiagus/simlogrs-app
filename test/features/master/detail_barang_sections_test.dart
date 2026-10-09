import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/master/data/models/detail_barang_model.dart';
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

  testWidgets('DetailBarangStokRuanganSection renders long unit name on narrow 320px viewport without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const listRuangan = [
      DaftarRuanganItem(unit: 'Instalasi Pemeliharaan Sarana Rumah Sakit (IPSRS)', jumlah: 15),
      DaftarRuanganItem(unit: 'Instalasi Gawat Darurat (IGD)', jumlah: 8),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DetailBarangRuanganList(
              daftarRuangan: listRuangan,
              simbolSatuan: 'Pcs',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sebaran Saldo di Ruangan Unit'), findsOneWidget);
    expect(find.text('15 Pcs'), findsOneWidget);
  });
}
