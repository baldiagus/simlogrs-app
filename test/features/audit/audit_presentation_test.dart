import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/audit/presentation/utils/audit_presentation.dart';

void main() {
  test('shared labels use known meanings without guessing unknown codes', () {
    expect(AuditPresentation.action('UBAH'), 'Diubah');
    expect(AuditPresentation.entity('PermintaanPeminjaman'), 'Peminjaman aset');
    expect(AuditPresentation.role('super_admin'), 'Super Admin');
    expect(AuditPresentation.entity('UnexpectedEntity'), 'Objek lainnya');
    expect(AuditPresentation.role('unexpected_role'), 'Peran lainnya');
    expect(AuditPresentation.action('UNEXPECTED'), 'Aktivitas lainnya');
    expect(AuditPresentation.value('SELESAI', entity: 'PermintaanPeminjaman', field: 'status'), 'Selesai');
    expect(AuditPresentation.value('SELESAI', entity: 'UnexpectedEntity', field: 'status'), 'Nilai lain (lihat informasi teknis)');
  });

  test('compares nested maps structurally and lists by position', () {
    final changes = AuditPresentation.changes(
      {'details': [{'jumlah': 0, 'nama': 'Tetap'}], 'metadata': {'a': 1, 'b': 2}},
      {'metadata': {'b': 2, 'a': 1}, 'details': [{'nama': 'Tetap', 'jumlah': 2}, {'jumlah': 3}]},
    );
    expect(changes.map((change) => change.path.join('.')), ['details.0.jumlah', 'details.1.jumlah']);
    expect(changes.first.before.value, 0);
    expect(changes.first.after.value, 2);
    expect(changes.last.before.present, isFalse);
    expect(changes.last.after.value, 3);
  });

  test('missing, null, empty strings, empty containers, zero and false stay distinct', () {
    final changes = AuditPresentation.changes(
      {'status': null, 'jumlah': 0, 'aktif': false, 'catatan': '', 'details': []},
      {'jumlah': false, 'aktif': 0, 'catatan': null, 'details': {}},
    );
    expect(changes.length, 5);
    final status = changes.first;
    expect(status.before.present, isTrue);
    expect(status.before.value, isNull);
    expect(status.after.present, isFalse);
    expect(AuditPresentation.value(null), 'Tidak diisi (null)');
    expect(AuditPresentation.value(''), 'Teks kosong');
    expect(AuditPresentation.value(0), '0');
    expect(AuditPresentation.value(false), 'Tidak (false)');
    expect(AuditPresentation.value(const []), 'Daftar kosong');
    expect(AuditPresentation.value(const {}), 'Objek kosong');
    expect(AuditPresentation.changes(null, null), isEmpty);
    expect(AuditPresentation.changes({}, {}), isEmpty);
  });

  test('unknown values are retained rather than translated into business meanings', () {
    final changes = AuditPresentation.changes({'secret_code': 'OLD'}, {'secret_code': 'NEW'});
    expect(changes.single.path, ['secret_code']);
    expect(changes.single.before.value, 'OLD');
    expect(changes.single.after.value, 'NEW');
    expect(AuditPresentation.field('secret_code'), 'Bidang tambahan');
    expect(AuditPresentation.value('FUTURE_STATUS', field: 'status', entity: 'PermintaanPeminjaman'), 'Nilai lain (lihat informasi teknis)');
    expect(AuditPresentation.value('FUTURE_STATUS', technical: true), 'FUTURE_STATUS');
  });
}
