import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';

const _terimaSppbPerm = 'update_layanan_unit::penerimaan::barang';
const _pickingDistribusiPerm = 'create_gudang_stok::picking::distribusi';
const _permintaanBarangPerm = 'create_layanan_unit::permintaan::barang';

const _dummyUnit = UnitModel(id: 1, nama: 'Ruang Melati', kode: 'MEL');
const _dummyGudang = GudangModel(id: 1, nama: 'Gudang Sentral', kode: 'GUD');

UserModel _user({
  required List<String> roles,
  List<String> permissions = const [],
  UnitModel? unit,
  GudangModel? gudang,
}) {
  return UserModel(
    id: 1,
    name: 'Tes RBAC',
    email: 'tes@simlogrs.local',
    roles: roles,
    permissions: permissions,
    unit: unit,
    gudang: gudang,
  );
}

void main() {
  group('UserModel Distribusi RBAC Matrix per Role', () {
    // (label, user, canKonfirmasiPenerimaanSppb, canPickingDistribusi, canAjukanAmprah)
    final cases = <(String, UserModel, bool, bool, bool)>[
      (
        'super_admin dengan unit',
        _user(roles: ['super_admin'], unit: _dummyUnit),
        true,
        true,
        true,
      ),
      (
        'super_admin tanpa unit dan tanpa gudang',
        _user(roles: ['super_admin']),
        true,
        true,
        false, // Rule: wajib memiliki unit atau gudang
      ),
      (
        'admin_logistik dengan gudang',
        _user(roles: ['admin_logistik'], gudang: _dummyGudang),
        true,
        true,
        true,
      ),
      (
        'admin_logistik tanpa unit dan tanpa gudang',
        _user(roles: ['admin_logistik']),
        true,
        true,
        false,
      ),
      (
        'petugas_unit dengan unit & permission terima/ajukan',
        _user(
          roles: ['petugas_unit'],
          permissions: [_terimaSppbPerm, _permintaanBarangPerm],
          unit: _dummyUnit,
        ),
        true,
        false,
        true,
      ),
      (
        'petugas_unit tanpa unit & gudang',
        _user(
          roles: ['petugas_unit'],
          permissions: [_terimaSppbPerm, _permintaanBarangPerm],
        ),
        true,
        false,
        false,
      ),
      (
        'kepala_unit dengan unit (harus false untuk terima, true untuk ajukan)',
        _user(
          roles: ['kepala_unit'],
          permissions: [_permintaanBarangPerm],
          unit: _dummyUnit,
        ),
        false, // Server rule: kepala_unit tidak berhak terima SPPB
        false,
        true,
      ),
      (
        'kepala_unit tanpa unit & gudang',
        _user(
          roles: ['kepala_unit'],
          permissions: [_permintaanBarangPerm],
        ),
        false,
        false,
        false,
      ),
      (
        'kepala_teknisi dengan unit',
        _user(
          roles: ['kepala_teknisi'],
          permissions: [_terimaSppbPerm, _permintaanBarangPerm],
          unit: _dummyUnit,
        ),
        true,
        false,
        true,
      ),
      (
        'petugas_gudang dengan gudang & picking permission',
        _user(
          roles: ['petugas_gudang'],
          permissions: [_pickingDistribusiPerm],
          gudang: _dummyGudang,
        ),
        false,
        true,
        false,
      ),
      (
        'kepala_gudang dengan gudang',
        _user(
          roles: ['kepala_gudang'],
          gudang: _dummyGudang,
        ),
        false,
        true,
        false,
      ),
      (
        'pengadaan dengan unit',
        _user(
          roles: ['pengadaan'],
          permissions: [_permintaanBarangPerm],
          unit: _dummyUnit,
        ),
        false,
        false,
        true,
      ),
      (
        'auditor dengan unit (tidak boleh ajukan amprah)',
        _user(
          roles: ['auditor'],
          unit: _dummyUnit,
        ),
        false,
        false,
        false,
      ),
      (
        'manajemen dengan unit (tidak boleh ajukan amprah)',
        _user(
          roles: ['manajemen'],
          unit: _dummyUnit,
        ),
        false,
        false,
        false,
      ),
      (
        'teknisi biasa dengan unit tanpa permission',
        _user(
          roles: ['teknisi'],
          unit: _dummyUnit,
        ),
        false,
        false,
        false,
      ),
      (
        'user acak dengan permission picking saja',
        _user(
          roles: ['teknisi'],
          permissions: [_pickingDistribusiPerm],
          gudang: _dummyGudang,
        ),
        false,
        true,
        false,
      ),
      (
        'user acak dengan permission terima saja',
        _user(
          roles: ['teknisi'],
          permissions: [_terimaSppbPerm],
          unit: _dummyUnit,
        ),
        true,
        false,
        false,
      ),
      (
        'user acak dengan permission ajukan saja',
        _user(
          roles: ['teknisi'],
          permissions: [_permintaanBarangPerm],
          unit: _dummyUnit,
        ),
        false,
        false,
        true,
      ),
    ];

    for (final (label, user, canTerima, canPick, canAjukan) in cases) {
      test('$label -> canKonfirmasiPenerimaanSppb=$canTerima', () {
        expect(user.canKonfirmasiPenerimaanSppb, canTerima);
      });
      test('$label -> canPickingDistribusi=$canPick', () {
        expect(user.canPickingDistribusi, canPick);
      });
      test('$label -> canAjukanAmprah=$canAjukan', () {
        expect(user.canAjukanAmprah, canAjukan);
      });
    }
  });

  group('UserModel Acceptance Criteria Spesifik', () {
    test('kepala_unit bernilai false untuk canKonfirmasiPenerimaanSppb (Terima)', () {
      final user = _user(
        roles: ['kepala_unit'],
        permissions: ['page_KepalaUnitDashboard'],
        unit: _dummyUnit,
      );
      expect(user.canKonfirmasiPenerimaanSppb, isFalse);
    });

    test('petugas_unit bernilai true untuk canKonfirmasiPenerimaanSppb (Terima)', () {
      final user = _user(
        roles: ['petugas_unit'],
        permissions: [_terimaSppbPerm],
        unit: _dummyUnit,
      );
      expect(user.canKonfirmasiPenerimaanSppb, isTrue);
    });

    test('user tanpa unit dan tanpa gudang bernilai false untuk canAjukanAmprah', () {
      final user = _user(
        roles: ['super_admin', 'petugas_unit'],
        permissions: [_permintaanBarangPerm],
        unit: null,
        gudang: null,
      );
      expect(user.canAjukanAmprah, isFalse);
    });
  });

  group('UserModel Meja 1 dan Meja 2 Approval Matrix per Role', () {
    // (label, user, canMeja1, canMeja2)
    final mejaCases = <(String, UserModel, bool, bool)>[
      (
        'kepala_teknisi dengan permission otorisasi karu & gudang -> false untuk Meja 1, false untuk Meja 2',
        _user(
          roles: ['kepala_teknisi'],
          permissions: [
            'update_layanan_unit::approval::karu',
            'update_gudang_stok::distribusi::approval',
          ],
        ),
        false,
        false,
      ),
      (
        'kepala_unit dengan permission karu -> true untuk Meja 1, false untuk Meja 2',
        _user(
          roles: ['kepala_unit'],
          permissions: ['update_layanan_unit::approval::karu'],
        ),
        true,
        false,
      ),
      (
        'kepala_gudang dengan permission gudang -> false untuk Meja 1, true untuk Meja 2',
        _user(
          roles: ['kepala_gudang'],
          permissions: ['update_gudang_stok::distribusi::approval'],
        ),
        false,
        true,
      ),
      (
        'super_admin dengan kedua permission -> true untuk Meja 1, true untuk Meja 2',
        _user(
          roles: ['super_admin'],
          permissions: [
            'update_layanan_unit::approval::karu',
            'update_gudang_stok::distribusi::approval',
          ],
        ),
        true,
        true,
      ),
      (
        'petugas_unit dengan kedua permission -> false untuk Meja 1, false untuk Meja 2',
        _user(
          roles: ['petugas_unit'],
          permissions: [
            'update_layanan_unit::approval::karu',
            'update_gudang_stok::distribusi::approval',
          ],
        ),
        false,
        false,
      ),
    ];

    for (final (label, user, canMeja1, canMeja2) in mejaCases) {
      test('$label -> canApproveAmprahMeja1=$canMeja1', () {
        expect(user.canApproveAmprahMeja1, canMeja1);
      });
      test('$label -> canApproveAmprahMeja2=$canMeja2', () {
        expect(user.canApproveAmprahMeja2, canMeja2);
      });
    }
  });
}
