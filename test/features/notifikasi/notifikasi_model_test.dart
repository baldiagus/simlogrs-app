import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/notifikasi/data/models/notifikasi_model.dart';

/// Pengujian parsing [NotifikasiModel] terhadap kontrak dan data tidak lengkap.
void main() {
  test('memetakan seluruh field sesuai kontrak', () {
    final m = NotifikasiModel.fromJson({
      'id': 12,
      'judul': 'Pengajuan PR Baru',
      'pesan': 'PR-2026-0005 menunggu persetujuan Anda.',
      'tipe': 'APPROVAL_PR',
      'referensi_id': '14',
      'tautan': '/kepala-unit/approval',
      'dibaca': false,
      'dibuat_pada': '2026-10-13T10:15:00+07:00',
    });
    expect(m.id, 12);
    expect(m.tipe, 'APPROVAL_PR');
    expect(m.referensiId, '14');
    expect(m.tautan, '/kepala-unit/approval');
    expect(m.dibaca, isFalse);
    expect(m.dibuatPada.toUtc(), DateTime.utc(2026, 10, 13, 3, 15));
  });

  test('tipe null atau kosong menjadi UMUM dan referensi/tautan null tetap null', () {
    final m = NotifikasiModel.fromJson({
      'id': 1,
      'judul': 'Lama',
      'pesan': 'Baris lama',
      'tipe': null,
      'referensi_id': null,
      'dibaca': true,
      'dibuat_pada': '2026-10-01T08:00:00Z',
    });
    expect(m.tipe, 'UMUM');
    expect(m.referensiId, isNull);
    expect(m.tautan, isNull);
    expect(m.dibaca, isTrue);
    expect(NotifikasiModel.fromJson({'id': 2, 'tipe': ''}).tipe, 'UMUM');
  });

  test('toleran terhadap tipe data longgar: id string, referensi angka, dibaca 1', () {
    final m = NotifikasiModel.fromJson({
      'id': '7',
      'referensi_id': 14,
      'dibaca': 1,
      'dibuat_pada': 'rusak',
    });
    expect(m.id, 7);
    expect(m.referensiId, '14');
    expect(m.dibaca, isTrue);
    expect(m.judul, '');
  });

  test('copyWith hanya mengubah status dibaca', () {
    final m = NotifikasiModel.fromJson({'id': 3, 'judul': 'J', 'tipe': 'TIKET_BARU'});
    final c = m.copyWith(dibaca: true);
    expect(c.dibaca, isTrue);
    expect(c.id, 3);
    expect(c.tipe, 'TIKET_BARU');
    expect(c.dibuatPada, m.dibuatPada);
  });
}
