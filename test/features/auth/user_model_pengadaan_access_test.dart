import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';

const _updatePr = 'update_pengadaan::permintaan::pengadaan';
const _createPr = 'create_pengadaan::permintaan::pengadaan';

UserModel _user(List<String> roles, [List<String> permissions = const []]) =>
    UserModel(id: 1, name: 'Tes', email: 'tes@simlogrs.local', roles: roles, permissions: permissions);

void main() {
  // (label, user, canApprovePrMeja1, canManagePo, canCreatePr)
  final cases = <(String, UserModel, bool, bool, bool)>[
    ('pengadaan', _user(['pengadaan']), false, true, false),
    ('pengadaan + permission update/create', _user(['pengadaan'], [_updatePr, _createPr]), false, true, false),
    ('admin_logistik', _user(['admin_logistik']), true, true, false),
    ('super_admin', _user(['super_admin']), true, true, true),
    ('kepala_unit', _user(['kepala_unit']), true, false, true),
    ('kepala_gudang', _user(['kepala_gudang']), true, false, false),
    ('manajemen + permission update', _user(['manajemen'], [_updatePr]), false, false, false),
    ('auditor + permission update', _user(['auditor'], [_updatePr]), false, false, false),
    ('petugas_unit', _user(['petugas_unit']), false, false, true),
    ('permission create saja', _user(['teknisi'], [_createPr]), false, false, true),
    ('permission update saja', _user(['teknisi'], [_updatePr]), true, false, false),
    ('tanpa peran', _user([]), false, false, false),
  ];

  group('UserModel akses pengadaan', () {
    for (final (label, user, approve, managePo, createPr) in cases) {
      test('$label: canApprovePrMeja1=$approve', () => expect(user.canApprovePrMeja1, approve));
      test('$label: canManagePo=$managePo', () => expect(user.canManagePo, managePo));
      test('$label: canCreatePr=$createPr', () => expect(user.canCreatePr, createPr));
    }
  });
}
