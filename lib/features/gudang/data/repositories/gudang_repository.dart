import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/rak_model.dart';
import '../models/aset_rak_model.dart';

class GudangRepository {
  final DioClient _client;

  GudangRepository(this._client);

  Future<List<RakModel>> getDaftarRak({String? cari, int? gudangId}) async {
    try {
      final response = await _client.dio.get(
        '/gudang/rak',
        queryParameters: {
          if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
          if (gudangId != null) 'gudang_id': gudangId,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => RakModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat daftar rak gudang');
    }
  }

  Future<RakDetailModel> getDetailRak(int id) async {
    try {
      final response = await _client.dio.get('/gudang/rak/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return RakDetailModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format detail rak tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat detail rak gudang');
    }
  }
}
