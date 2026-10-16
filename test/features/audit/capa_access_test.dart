import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/presentation/widgets/sheets/detail_temuan_sheet.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';

UserModel _user({
  List<String> roles = const [],
  List<String> permissions = const [],
  int? unitId,
  int? gudangId,
}) =>
    UserModel(
      id: 1,
      name: 'Uji',
      email: 'uji@simlogrs.local',
      unit: unitId == null ? null : UnitModel(id: unitId, nama: 'Unit'),
      gudang: gudangId == null ? null : GudangModel(id: gudangId, nama: 'Gudang'),
      roles: roles,
      permissions: permissions,
    );

TemuanCapaModel _temuan({int? unitId, int? gudangId}) => TemuanCapaModel.fromJson({
      'id': 7,
      'unit_id': unitId,
      'gudang_id': gudangId,
    });

void main() {
  group('isAuditor / hasCapaAccess', () {
    test('kepala unit dengan view CAPA: bukan auditor, tetap punya akses CAPA', () {
      final u = _user(roles: ['kepala_unit'], permissions: ['view_audit_manajemen::temuan::capa']);
      expect(u.isAuditor, isFalse);
      expect(u.hasAuditAccess, isFalse);
      expect(u.hasCapaAccess, isTrue);
    });

    test('auditor (role): isAuditor dan hasCapaAccess true', () {
      final u = _user(roles: ['auditor']);
      expect(u.isAuditor, isTrue);
      expect(u.hasCapaAccess, isTrue);
    });

    test('permission create temuan tanpa role auditor tetap dianggap auditor', () {
      final u = _user(permissions: ['create_audit_manajemen::temuan::capa']);
      expect(u.isAuditor, isTrue);
    });

    test('super admin: bukan isAuditor tetapi punya akses CAPA', () {
      final u = _user(roles: ['super_admin']);
      expect(u.isAuditor, isFalse);
      expect(u.hasCapaAccess, isTrue);
    });

    test('user tanpa permission CAPA tidak punya akses', () {
      expect(_user(roles: ['kepala_unit']).hasCapaAccess, isFalse);
    });
  });

  group('TemuanCapaModel unit_id/gudang_id', () {
    test('null-safe bila field tidak ada', () {
      final t = TemuanCapaModel.fromJson({'id': 1});
      expect(t.unitId, isNull);
      expect(t.gudangId, isNull);
    });

    test('memetakan unit_id dan gudang_id', () {
      final t = _temuan(unitId: 3, gudangId: 9);
      expect(t.unitId, 3);
      expect(t.gudangId, 9);
    });
  });

  group('canTindakLanjutTemuan / canEvaluasiTemuan', () {
    test('unit sama -> boleh; unit berbeda -> tidak', () {
      final u = _user(roles: ['kepala_unit'], unitId: 3);
      expect(canTindakLanjutTemuan(u, _temuan(unitId: 3)), isTrue);
      expect(canTindakLanjutTemuan(u, _temuan(unitId: 4)), isFalse);
    });

    test('gudang sama -> boleh', () {
      final u = _user(roles: ['kepala_gudang'], gudangId: 9);
      expect(canTindakLanjutTemuan(u, _temuan(gudangId: 9)), isTrue);
      expect(canTindakLanjutTemuan(u, _temuan(gudangId: 8)), isFalse);
    });

    test('temuan tanpa unit/gudang tidak cocok dengan user tanpa unit/gudang', () {
      expect(canTindakLanjutTemuan(_user(roles: ['kepala_unit']), _temuan()), isFalse);
    });

    test('super admin dan admin logistik selalu boleh', () {
      expect(canTindakLanjutTemuan(_user(roles: ['super_admin']), _temuan()), isTrue);
      expect(canTindakLanjutTemuan(_user(roles: ['admin_logistik']), _temuan(unitId: 1)), isTrue);
    });

    test('auditor tidak otomatis boleh tindak lanjut', () {
      expect(canTindakLanjutTemuan(_user(roles: ['auditor']), _temuan(unitId: 1)), isFalse);
    });

    test('canEvaluasi: hanya auditor dan super admin', () {
      expect(canEvaluasiTemuan(_user(roles: ['auditor'])), isTrue);
      expect(canEvaluasiTemuan(_user(roles: ['super_admin'])), isTrue);
      expect(
        canEvaluasiTemuan(_user(roles: ['kepala_unit'], permissions: ['view_audit_manajemen::temuan::capa'])),
        isFalse,
      );
      expect(canEvaluasiTemuan(null), isFalse);
    });
  });
}
