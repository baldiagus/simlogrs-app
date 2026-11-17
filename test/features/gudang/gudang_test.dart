import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/gudang/data/models/rak_model.dart';
import 'package:simlog_mobile/features/gudang/data/models/barang_rak_model.dart';

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
  });
}
