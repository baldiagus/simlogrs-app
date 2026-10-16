import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';

const _opnamePerm = 'create_gudang_stok::stok::opname';

UserModel _user(List<String> roles, [List<String> permissions = const []]) =>
    UserModel(
      id: 1,
      name: 'Tes RBAC Stock Opname',
      email: 'tes@simlogrs.local',
      roles: roles,
      permissions: permissions,
    );

void main() {
  group('UserModel.canInisiasiStockOpname per role & permission', () {
    final cases = <(String, UserModel, bool)>[
      ('super_admin', _user(['super_admin']), true),
      ('admin_logistik', _user(['admin_logistik']), true),
      ('kepala_gudang', _user(['kepala_gudang']), true),
      ('petugas_gudang', _user(['petugas_gudang']), true),
      (
        'petugas_unit dengan permission create_gudang_stok::stok::opname',
        _user(['petugas_unit'], [_opnamePerm]),
        true,
      ),
      (
        'teknisi dengan permission create_gudang_stok::stok::opname',
        _user(['teknisi'], [_opnamePerm]),
        true,
      ),
      (
        'user tanpa role dengan permission create_gudang_stok::stok::opname',
        _user([], [_opnamePerm]),
        true,
      ),
      ('petugas_unit tanpa permission', _user(['petugas_unit']), false),
      ('kepala_unit tanpa permission', _user(['kepala_unit']), false),
      ('auditor tanpa permission', _user(['auditor']), false),
      ('manajemen tanpa permission', _user(['manajemen']), false),
      ('teknisi tanpa permission', _user(['teknisi']), false),
      ('tanpa role dan tanpa permission', _user([]), false),
    ];

    for (final (label, user, expected) in cases) {
      test('$label: canInisiasiStockOpname=$expected', () {
        expect(user.canInisiasiStockOpname, expected);
      });
    }
  });
}
