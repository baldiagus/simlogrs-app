import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/models/rak_model.dart';
import '../../data/repositories/gudang_repository.dart';

/// Provider repository gudang; membungkus akses API gudang memakai DioClient bersama.
final gudangRepositoryProvider = Provider<GudangRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return GudangRepository(client);
});

/// Opsi rak penerimaan terikat gudang dan sesi pengguna.
final rakPenerimaanProvider =
    FutureProvider.autoDispose.family<List<RakModel>, int>((ref, gudangId) async {
  final user = ref.watch(authStateProvider).user;
  if (gudangId <= 0 || user == null || !user.canReceiveInbound) {
    throw ApiException(message: 'Gudang penerima belum tersedia atau akses ditolak.');
  }
  final assignedId = user.gudang?.id;
  if ((assignedId != null && assignedId != gudangId) ||
      (assignedId == null &&
          !user.hasRole('super_admin') && !user.hasRole('admin_logistik'))) {
    throw ApiException(message: 'Gudang penerima tidak sesuai penugasan akun.');
  }
  final repository = ref.watch(gudangRepositoryProvider);
  final racks = await repository.getDaftarRak(gudangId: gudangId);
  return racks
      .where((rack) => rack.gudangId == gudangId && rack.status == 'AKTIF')
      .toList();
});
