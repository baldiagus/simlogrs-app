import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/gudang/data/models/rak_model.dart';
import 'package:simlog_mobile/features/gudang/data/models/barang_rak_model.dart';
import 'package:simlog_mobile/features/gudang/data/models/aset_rak_model.dart';
import 'package:simlog_mobile/features/gudang/presentation/widgets/rak_card_item.dart';
import 'package:simlog_mobile/features/gudang/presentation/widgets/barang_rak_list_tab.dart';
import 'package:simlog_mobile/features/gudang/presentation/widgets/aset_rak_list_tab.dart';

void main() {
  group('Gudang Models Unit Test', () {
    test('RakModel parses JSON correctly', () {
      final json = {
        'id': 1,
        'kode': 'RAK-ATK-01',
        'nama': 'Rak ATK Sentral',
        'baris': 'A',
        'kolom': '1',
        'level': '2',
        'status': 'AKTIF',
        'gudang_id': 10,
        'nama_gudang': 'Gudang Sentral',
        'total_barang': 15,
        'total_aset': 3,
      };

      final rak = RakModel.fromJson(json);

      expect(rak.id, 1);
      expect(rak.kode, 'RAK-ATK-01');
      expect(rak.nama, 'Rak ATK Sentral');
      expect(rak.gudangId, 10);
      expect(rak.namaGudang, 'Gudang Sentral');
      expect(rak.totalBarang, 15);
      expect(rak.totalAset, 3);
    });

    test('BarangRakModel handles expiration states and stock quantity correctly', () {
      final jsonAman = {
        'id': 101,
        'nama_barang': 'Kertas A4 80gr',
        'kode_barang': 'ATK-001',
        'kategori': 'ATK',
        'satuan': 'Rim',
        'merek': 'PaperOne',
        'nomor_batch': 'B2026-01',
        'tanggal_kedaluwarsa': '2028-12-31',
        'status_kedaluwarsa': 'AMAN',
        'kuantitas_stok': 25,
      };

      final barangAman = BarangRakModel.fromJson(jsonAman);
      expect(barangAman.isKadaluwarsa, false);
      expect(barangAman.isMendekatiKadaluwarsa, false);
      expect(barangAman.kuantitasStok, 25);

      final jsonExpired = {
        'id': 102,
        'nama_barang': 'Reagen Uji',
        'kode_barang': 'MED-099',
        'kategori': 'Reagen',
        'satuan': 'Botol',
        'merek': 'BioLab',
        'status_kedaluwarsa': 'KADALUWARSA',
        'kuantitas_stok': 5,
      };

      final barangExpired = BarangRakModel.fromJson(jsonExpired);
      expect(barangExpired.isKadaluwarsa, true);
    });

    test('AsetRakModel and RakDetailModel parse complete structure', () {
      final jsonDetail = {
        'id': 2,
        'kode': 'RAK-MED-02',
        'nama': 'Rak Alkes Sentral',
        'status': 'AKTIF',
        'nama_gudang': 'Gudang Sentral',
        'total_barang': 1,
        'total_aset': 1,
        'barang': [
          {
            'id': 201,
            'nama_barang': 'Spuit 5cc',
            'kode_barang': 'MED-001',
            'kategori': 'Alkes',
            'satuan': 'Box',
            'merek': 'OneMed',
            'status_kedaluwarsa': 'AMAN',
            'kuantitas_stok': 10,
          }
        ],
        'aset': [
          {
            'id': 301,
            'kode_aset': 'AST-2026-0001',
            'nama_aset': 'Infusion Pump',
            'merk': 'Terumo',
            'model': 'TE-171',
            'nomor_seri': 'SN-998822',
            'status_ketersediaan': 'TERSEDIA',
            'kondisi_fisik': 'BAIK',
          }
        ],
      };

      final detail = RakDetailModel.fromJson(jsonDetail);
      expect(detail.rak.kode, 'RAK-MED-02');
      expect(detail.barang.length, 1);
      expect(detail.aset.length, 1);
      expect(detail.aset.first.kodeAset, 'AST-2026-0001');
      expect(detail.aset.first.kondisiFisik, 'BAIK');
    });
  });

  group('Gudang Widgets Smoke Test', () {
    testWidgets('RakCardItem displays shelf code, name, and metrics', (tester) async {
      const rak = RakModel(
        id: 1,
        kode: 'RAK-ATK-01',
        nama: 'Rak ATK Sentral',
        status: 'AKTIF',
        namaGudang: 'Gudang Sentral',
        totalBarang: 12,
        totalAset: 4,
      );

      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RakCardItem(
              rak: rak,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('RAK-ATK-01'), findsOneWidget);
      expect(find.text('Rak ATK Sentral'), findsOneWidget);
      expect(find.text('12 Jenis Barang'), findsOneWidget);
      expect(find.text('4 Unit Aset'), findsOneWidget);

      await tester.tap(find.byType(RakCardItem));
      expect(tapped, true);
    });

    testWidgets('BarangRakListTab renders items and handles search filtering', (tester) async {
      final items = [
        const BarangRakModel(
          id: 1,
          namaBarang: 'Kertas A4',
          kodeBarang: 'ATK-001',
          kategori: 'ATK',
          satuan: 'Rim',
          merek: 'PaperOne',
          statusKedaluwarsa: 'AMAN',
          kuantitasStok: 50,
        ),
        const BarangRakModel(
          id: 2,
          namaBarang: 'Pulpen Gel',
          kodeBarang: 'ATK-002',
          kategori: 'ATK',
          satuan: 'Pcs',
          merek: 'Pilot',
          statusKedaluwarsa: 'AMAN',
          kuantitasStok: 100,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarangRakListTab(items: items),
          ),
        ),
      );

      expect(find.text('Kertas A4'), findsOneWidget);
      expect(find.text('Pulpen Gel'), findsOneWidget);

      // Search filter
      await tester.enterText(find.byType(TextField), 'Kertas');
      await tester.pump();

      expect(find.text('Kertas A4'), findsOneWidget);
      expect(find.text('Pulpen Gel'), findsNothing);
    });

    testWidgets('AsetRakListTab renders physical assets and handles search filtering', (tester) async {
      final items = [
        const AsetRakModel(
          id: 1,
          kodeAset: 'AST-001',
          namaAset: 'Kursi Roda',
          statusKetersediaan: 'TERSEDIA',
          kondisiFisik: 'BAIK',
        ),
        const AsetRakModel(
          id: 2,
          kodeAset: 'AST-002',
          namaAset: 'Tensimeter Digital',
          statusKetersediaan: 'TERSEDIA',
          kondisiFisik: 'BAIK',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsetRakListTab(items: items),
          ),
        ),
      );

      expect(find.text('Kursi Roda'), findsOneWidget);
      expect(find.text('Tensimeter Digital'), findsOneWidget);

      // Search filter
      await tester.enterText(find.byType(TextField), 'Kursi');
      await tester.pump();

      expect(find.text('Kursi Roda'), findsOneWidget);
      expect(find.text('Tensimeter Digital'), findsNothing);
    });
  });
}
