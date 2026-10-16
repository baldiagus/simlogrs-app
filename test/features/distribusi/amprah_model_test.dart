import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/distribusi/data/models/amprah_model.dart';

void main() {
  group('AmprahModel - DIKIRIM_SEBAGIAN & Backorder support', () {
    test('AmprahHeaderModel recognises DIKIRIM_SEBAGIAN status', () {
      final json = {
        'id': 101,
        'kode': 'REQ-202610-001',
        'unit': 'IGD',
        'gudang': 'Gudang Farmasi',
        'pengaju': 'Perawat IGD',
        'tanggal_permintaan': '2026-10-06',
        'urgensi': 'CITO',
        'status': 'DIKIRIM_SEBAGIAN',
        'can_cancel': false,
        'jumlah_item': 1,
        'items': [],
      };

      final header = AmprahHeaderModel.fromJson(json);

      expect(header.isDikirimSebagian, isTrue);
      expect(header.isDisetujuiGudang, isFalse);
      expect(header.isSelesai, isFalse);
    });

    test('AmprahDetailItemModel parses jumlah_dikirim and calculates sisa_backorder correctly', () {
      final json = {
        'id': 1,
        'barang_id': 50,
        'nama_barang': 'Kasa Steril 10x10',
        'kode_barang': 'MED-KSA-01',
        'satuan': 'Box',
        'jumlah_diminta': 20,
        'jumlah_disetujui': 20,
        'jumlah_dikirim': 12,
      };

      final item = AmprahDetailItemModel.fromJson(json);

      expect(item.jumlahDiminta, 20);
      expect(item.jumlahDisetujui, 20);
      expect(item.jumlahDikirim, 12);
      expect(item.sisaBackorder, 8);
    });

    test('AmprahDetailItemModel handles missing jumlah_dikirim gracefully (defaults 0)', () {
      final json = {
        'id': 2,
        'barang_id': 51,
        'nama_barang': 'Alkohol 70%',
        'kode_barang': 'MED-ALK-01',
        'satuan': 'Botol',
        'jumlah_diminta': 5,
        'jumlah_disetujui': 5,
      };

      final item = AmprahDetailItemModel.fromJson(json);

      expect(item.jumlahDikirim, 0);
      expect(item.sisaBackorder, 5);
    });

    test('AmprahDetailItemModel parses stok_tersedia tolerantly with default 0', () {
      final itemInt = AmprahDetailItemModel.fromJson({
        'id': 1,
        'barang_id': 10,
        'nama_barang': 'Spuit',
        'kode_barang': 'SPT',
        'satuan': 'Pcs',
        'jumlah_diminta': 5,
        'jumlah_disetujui': 5,
        'stok_tersedia': 15,
      });
      expect(itemInt.stokTersedia, 15);

      final itemString = AmprahDetailItemModel.fromJson({
        'id': 2,
        'barang_id': 11,
        'nama_barang': 'Jarum',
        'kode_barang': 'JRM',
        'satuan': 'Pcs',
        'jumlah_diminta': 5,
        'jumlah_disetujui': 5,
        'stok_tersedia': '25',
      });
      expect(itemString.stokTersedia, 25);

      final itemMissing = AmprahDetailItemModel.fromJson({
        'id': 3,
        'barang_id': 12,
        'nama_barang': 'Kasa',
        'kode_barang': 'KSA',
        'satuan': 'Pcs',
        'jumlah_diminta': 5,
        'jumlah_disetujui': 5,
      });
      expect(itemMissing.stokTersedia, 0);
    });

    test('AmprahHeaderModel parses can_tutup_sisa correctly', () {
      final headerTrue = AmprahHeaderModel.fromJson({
        'id': 1,
        'kode': 'REQ-001',
        'unit': 'IGD',
        'gudang': 'Gudang',
        'pengaju': 'Staf',
        'tanggal_permintaan': '2026-10-16',
        'urgensi': 'REGULER',
        'status': 'DIKIRIM_SEBAGIAN',
        'can_cancel': false,
        'can_tutup_sisa': true,
        'jumlah_item': 1,
        'items': [],
      });
      expect(headerTrue.canTutupSisa, isTrue);

      final headerDefault = AmprahHeaderModel.fromJson({
        'id': 2,
        'kode': 'REQ-002',
        'unit': 'IGD',
        'gudang': 'Gudang',
        'pengaju': 'Staf',
        'tanggal_permintaan': '2026-10-16',
        'urgensi': 'REGULER',
        'status': 'DIAJUKAN',
        'can_cancel': true,
        'jumlah_item': 1,
        'items': [],
      });
      expect(headerDefault.canTutupSisa, isFalse);
    });
  });
}
