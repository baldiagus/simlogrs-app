import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/pagination_meta.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/notifikasi_model.dart';

/// Menyediakan [NotifikasiRepository] dengan klien Dio bersama.
final notifikasiRepositoryProvider = Provider<NotifikasiRepository>((ref) {
  return NotifikasiRepository(ref.watch(dioClientProvider));
});

/// Hasil satu halaman inbox: daftar berhalaman beserta jumlah notifikasi belum dibaca total.
class NotifikasiPage {
  /// Halaman notifikasi (item + metadata paginasi).
  final PagedResponse<NotifikasiModel> halaman;

  /// Jumlah seluruh notifikasi belum dibaca milik pengguna.
  final int belumDibaca;

  /// Membuat instance [NotifikasiPage].
  const NotifikasiPage({required this.halaman, required this.belumDibaca});
}

/// Akses API inbox notifikasi (`/notifikasi`).
class NotifikasiRepository {
  final DioClient _client;

  /// Membuat [NotifikasiRepository] di atas [DioClient].
  NotifikasiRepository(this._client);

  /// Mengambil satu halaman notifikasi; [hanyaBelumDibaca] memfilter yang belum dibaca.
  Future<NotifikasiPage> getDaftar({int page = 1, bool hanyaBelumDibaca = false}) async {
    try {
      final response = await _client.dio.get(
        '/notifikasi',
        queryParameters: {
          'page': page,
          'hanya_belum_dibaca': hanyaBelumDibaca ? 1 : 0,
        },
      );
      final body = response.data;
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is! Map<String, dynamic> || data['items'] is! List) {
        return NotifikasiPage(halaman: PagedResponse.empty(), belumDibaca: 0);
      }
      final items = (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(NotifikasiModel.fromJson)
          .toList();
      final metaJson = data['paginasi'];
      final meta = metaJson is Map<String, dynamic>
          ? PaginationMeta.fromJson(metaJson)
          : PaginationMeta.empty;
      return NotifikasiPage(
        halaman: PagedResponse(items: items, meta: meta),
        belumDibaca: _keInt(data['belum_dibaca']),
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat notifikasi');
    }
  }

  /// Menandai satu notifikasi sebagai dibaca; mengembalikan sisa jumlah belum dibaca dari server.
  Future<int> tandaiDibaca(int id) async {
    try {
      final response = await _client.dio.post('/notifikasi/$id/dibaca');
      return _bacaBelumDibaca(response.data);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal menandai notifikasi dibaca');
    }
  }

  /// Menandai seluruh notifikasi pengguna sebagai dibaca.
  Future<void> bacaSemua() async {
    try {
      await _client.dio.post('/notifikasi/baca-semua');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal menandai semua notifikasi dibaca');
    }
  }

  /// Membaca `data.belum_dibaca` dari envelope respons; 0 bila tidak ada.
  static int _bacaBelumDibaca(Object? body) {
    final data = body is Map<String, dynamic> ? body['data'] : null;
    return data is Map<String, dynamic> ? _keInt(data['belum_dibaca']) : 0;
  }

  /// Mengubah nilai dinamis menjadi int, default 0.
  static int _keInt(Object? v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
