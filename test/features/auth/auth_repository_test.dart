import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/auth/data/repositories/auth_repository.dart';

class FakeSecureStorageService extends Fake implements SecureStorageService {
  String? cachedUser;
  String? token = 'mock_token';

  @override
  Future<void> saveCachedUser(String userJson) async {
    cachedUser = userJson;
  }

  @override
  Future<String?> getCachedUser() async => cachedUser;

  @override
  Future<String?> getToken() async => token;
}

void main() {
  group('AuthRepository.gantiPasswordWajib', () {
    test('sends ganti-password payload and returns updated user on success', () async {
      final fakeStorage = FakeSecureStorageService();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
      
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/ganti-password' && options.method == 'POST') {
            final data = options.data as Map<String, dynamic>;
            expect(data['password_saat_ini'], 'PasswordLama123');
            expect(data['password_baru'], 'PasswordBaru2026!');
            expect(data['password_baru_confirmation'], 'PasswordBaru2026!');
            
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'sukses': true,
                'pesan': 'Kata sandi Anda berhasil diperbarui.',
                'data': {
                  'user': {
                    'id': 1,
                    'nama': 'Test User',
                    'email': 'user@simlogrs.local',
                    'roles': ['staf_gudang'],
                    'permissions': [],
                    'wajib_ganti_password': false,
                  },
                  'wajib_ganti_password': false,
                },
              },
            ));
          }
          return handler.next(options);
        },
      ));

      final client = DioClient(storageService: fakeStorage, customDio: dio);
      final repo = AuthRepository(client: client, storage: fakeStorage);

      final updatedUser = await repo.gantiPasswordWajib(
        passwordSaatIni: 'PasswordLama123',
        passwordBaru: 'PasswordBaru2026!',
        passwordBaruConfirmation: 'PasswordBaru2026!',
      );

      expect(updatedUser.wajibGantiPassword, isFalse);
      expect(fakeStorage.cachedUser, contains('"wajib_ganti_password":false'));
    });
  });
}
