import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/pengalihan_model.dart';

class PengalihanRepository {
  final DioClient _client;

  PengalihanRepository(this._client);

  Future<List<PengalihanItemModel>> getDaftarPengalihan({String tab = 'aktif'}) async {
    try {
      final response = await _client.dio.get(
        '/aset/pengalihan',
        queryParameters: {'tab': tab},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => PengalihanItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat daftar pengalihan aset');
    }
  }

  Future<Map<String, dynamic>> submitPengalihan(Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.post(
        '/aset/pengalihan',
        data: payload,
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return {'status': 'DIAJUKAN'};
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal mengajukan pengalihan aset');
    }
  }

  Future<void> otorisasiPengalihan({
    required int id,
    required String aksi,
    String? catatan,
  }) async {
    try {
      await _client.dio.post(
        '/aset/pengalihan/$id/otorisasi',
        data: {
          'aksi': aksi,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        },
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memproses otorisasi pengalihan aset');
    }
  }

  Future<void> serahTerimaPengalihan({
    required int id,
    String kondisi = 'BAIK',
  }) async {
    try {
      await _client.dio.post(
        '/aset/pengalihan/$id/serah-terima',
        data: {'kondisi': kondisi},
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memproses serah terima fisik aset');
    }
  }

  Future<void> batalPengalihan({
    required int id,
    String? alasan,
  }) async {
    try {
      await _client.dio.post(
        '/aset/pengalihan/$id/batal',
        data: {if (alasan != null && alasan.isNotEmpty) 'alasan': alasan},
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal membatalkan pengalihan aset');
    }
  }
}
