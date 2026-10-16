import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';

const _perpanjangAsetPerm = 'update_layanan_unit::peminjaman::aset';

UserModel _user(List<String> roles, [List<String> permissions = const []]) =>
    UserModel(
      id: 1,
      name: 'Tes RBAC Peminjaman',
      email: 'tes@simlogrs.local',
      roles: roles,
      permissions: permissions,
    );

void main() {
  group('UserModel.canPerpanjangPeminjaman per role & permission', () {
    final cases = <(String, UserModel, bool)>[
      ('super_admin', _user(['super_admin']), true),
      ('admin_logistik', _user(['admin_logistik']), true),
      ('kepala_unit', _user(['kepala_unit']), true),
      ('petugas_unit tanpa permission', _user(['petugas_unit']), false),
      (
        'petugas_unit dengan permission update_layanan_unit::peminjaman::aset',
        _user(['petugas_unit'], [_perpanjangAsetPerm]),
        true,
      ),
      ('kepala_gudang tanpa permission', _user(['kepala_gudang']), false),
      ('petugas_gudang tanpa permission', _user(['petugas_gudang']), false),
      ('teknisi tanpa permission', _user(['teknisi']), false),
      ('kepala_teknisi tanpa permission', _user(['kepala_teknisi']), true),
      ('auditor tanpa permission', _user(['auditor']), false),
      ('manajemen tanpa permission', _user(['manajemen']), false),
      ('tanpa role dan tanpa permission', _user([]), false),
      (
        'user tanpa role tapi punya permission',
        _user([], [_perpanjangAsetPerm]),
        true,
      ),
    ];

    for (final (label, user, expected) in cases) {
      test('$label: canPerpanjangPeminjaman=$expected', () {
        expect(user.canPerpanjangPeminjaman, expected);
      });
    }
  });
}
