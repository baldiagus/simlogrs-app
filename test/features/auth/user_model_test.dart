import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel - wajib_ganti_password parsing', () {
    test('parses wajib_ganti_password true when present in json', () {
      final json = {
        'id': 10,
        'nama': 'Staf Reset',
        'email': 'staf@simlogrs.local',
        'roles': ['staf_gudang'],
        'permissions': ['view_gudang'],
        'wajib_ganti_password': true,
      };

      final user = UserModel.fromJson(json);

      expect(user.wajibGantiPassword, isTrue);
    });

    test('defaults wajib_ganti_password to false when absent or false', () {
      final jsonWithoutFlag = {
        'id': 11,
        'nama': 'Staf Normal',
        'email': 'normal@simlogrs.local',
        'roles': ['staf_gudang'],
        'permissions': [],
      };

      final user = UserModel.fromJson(jsonWithoutFlag);

      expect(user.wajibGantiPassword, isFalse);
    });
  });
}
