import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/master_barang_model.dart';
import '../models/pr_model.dart';

class PengadaanRepository {
  final DioClient _client;

  PengadaanRepository(this._client);

  Future<List<MasterBarangModel>> getKatalogBarang({String? cari}) async {
    try {
      final response = await _client.dio.get(
        '/master/barang',
        queryParameters: {
          if (cari != null && cari.isNotEmpty) 'cari': cari,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => MasterBarangModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat katalog barang');
    }
  }

  Future<List<PrHeaderModel>> getDaftarPr() async {
    try {
      final response = await _client.dio.get('/pengadaan/pr');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => PrHeaderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat daftar permintaan pengadaan');
    }
  }

  Future<Map<String, dynamic>> submitPr({
    int? unitId,
    required String urgensi,
    String? catatan,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _client.dio.post(
        '/pengadaan/pr',
        data: {
          if (unitId != null) 'unit_id': unitId,
          'urgensi': urgensi,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
          'items': items,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: 'Format respons pengajuan tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal mengajukan permintaan pengadaan');
    }
  }
}
