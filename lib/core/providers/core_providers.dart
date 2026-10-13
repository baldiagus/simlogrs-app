import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

/// Provider singleton layanan penyimpanan aman (token dan cache user).
final storageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider klien HTTP Dio yang memakai storage untuk menyisipkan token otentikasi.
final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return DioClient(storageService: storage);
});

/// Provider repository otentikasi yang menggabungkan klien HTTP dan storage.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthRepository(client: client, storage: storage);
});
