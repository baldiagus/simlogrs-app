import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  String? _inMemoryToken;
  String? _inMemoryUser;
  /// Membuat service dengan storage aman bawaan (Android encrypted prefs, iOS keychain) atau storage injeksi untuk testing.
  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'cached_user';

  /// Menyimpan token ke memori dan storage aman agar sesi bertahan setelah aplikasi ditutup.
  Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Mengambil token; memakai cache memori lebih dulu untuk menghindari pembacaan storage berulang.
  Future<String?> getToken() async {
    if (_inMemoryToken != null && _inMemoryToken!.isNotEmpty) {
      return _inMemoryToken;
    }
    _inMemoryToken = await _storage.read(key: _tokenKey);
    return _inMemoryToken;
  }

  /// Menghapus token dari memori dan storage aman saat logout.
  Future<void> deleteToken() async {
    _inMemoryToken = null;
    await _storage.delete(key: _tokenKey);
  }

  /// Menyimpan JSON data user ke memori dan storage untuk akses offline cepat saat startup.
  Future<void> saveCachedUser(String userJson) async {
    _inMemoryUser = userJson;
    await _storage.write(key: _userKey, value: userJson);
  }

  /// Mengambil JSON user tersimpan; cache memori diutamakan sebelum membaca storage.
  Future<String?> getCachedUser() async {
    if (_inMemoryUser != null && _inMemoryUser!.isNotEmpty) {
      return _inMemoryUser;
    }
    _inMemoryUser = await _storage.read(key: _userKey);
    return _inMemoryUser;
  }

  /// Menghapus seluruh data tersimpan (token dan user) beserta cache memori saat sesi berakhir.
  Future<void> clearAll() async {
    _inMemoryToken = null;
    _inMemoryUser = null;
    await _storage.deleteAll();
  }
}
