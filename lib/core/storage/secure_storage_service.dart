import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  String? _inMemoryToken;
  String? _inMemoryUser;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'cached_user';

  Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    if (_inMemoryToken != null && _inMemoryToken!.isNotEmpty) {
      return _inMemoryToken;
    }
    _inMemoryToken = await _storage.read(key: _tokenKey);
    return _inMemoryToken;
  }

  Future<void> deleteToken() async {
    _inMemoryToken = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveCachedUser(String userJson) async {
    _inMemoryUser = userJson;
    await _storage.write(key: _userKey, value: userJson);
  }

  Future<String?> getCachedUser() async {
    if (_inMemoryUser != null && _inMemoryUser!.isNotEmpty) {
      return _inMemoryUser;
    }
    _inMemoryUser = await _storage.read(key: _userKey);
    return _inMemoryUser;
  }

  Future<void> clearAll() async {
    _inMemoryToken = null;
    _inMemoryUser = null;
    await _storage.deleteAll();
  }
}
