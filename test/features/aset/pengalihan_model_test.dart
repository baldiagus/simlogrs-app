import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/pengalihan_model.dart';

void main() {
  group('PengalihanItemModel Tests', () {
    test('parses asset transfer JSON correctly', () {
      final json = {
        'id': 10,
        'kode': 'TRF-202610-001',
        'tipe': 'ASET',
        'tipe_asal': 'RUANGAN',
        'asal_nama': 'IGD',
        'tipe_tujuan': 'RUANGAN',
        'tujuan_nama': 'ICU',
        'status': 'DIAJUKAN',
        'tanggal_pengalihan': '2026-10-06',
        'nama_item': 'Defibrillator Philips',
        'jumlah': 1,
        'alasan': 'Kebutuhan mendesak di ICU',
        'can_cancel': true,
        'can_approve': true,
        'can_receive': false,
        'unit_asal_id': 3,
        'unit_tujuan_id': 4,
      };

      final model = PengalihanItemModel.fromJson(json);

      expect(model.id, 10);
      expect(model.kode, 'TRF-202610-001');
      expect(model.tipe, 'ASET');
      expect(model.asalNama, 'IGD');
      expect(model.tujuanNama, 'ICU');
      expect(model.isDiajukan, isTrue);
      expect(model.isSelesai, isFalse);
      expect(model.namaItem, 'Defibrillator Philips');
      expect(model.jumlah, 1);
      expect(model.canCancel, isTrue);
      expect(model.canApprove, isTrue);
      expect(model.canReceive, isFalse);
      expect(model.unitAsalId, 3);
      expect(model.unitTujuanId, 4);
    });

    test('parses goods transfer JSON correctly with status SELESAI', () {
      final json = {
        'id': 20,
        'kode': 'TRF-BRG-202610-002',
        'tipe': 'BARANG',
        'tipe_asal': 'GUDANG',
        'asal_nama': 'Gudang Sentral',
        'tipe_tujuan': 'GUDANG',
        'tujuan_nama': 'Gudang Farmasi',
        'status': 'SELESAI',
        'tanggal_pengalihan': '2026-10-06',
        'nama_item': 'Spuit 5cc',
        'jumlah': 100,
      };

      final model = PengalihanItemModel.fromJson(json);

      expect(model.id, 20);
      expect(model.tipe, 'BARANG');
      expect(model.isSelesai, isTrue);
      expect(model.jumlah, 100);
    });
  });
}
