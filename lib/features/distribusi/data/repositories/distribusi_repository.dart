import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/amprah_model.dart';
import '../models/sppb_model.dart';

class DistribusiRepository {
  final DioClient _client;

  DistribusiRepository(this._client);

  Future<List<BarangAmprahKatalogModel>> getKatalogBarang({String? cari, int? gudangId}) async {
    try {
      final response = await _client.dio.get(
        '/distribusi/katalog-barang',
        queryParameters: {
          if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
          if (gudangId != null) 'gudang_id': gudangId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => BarangAmprahKatalogModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat katalog barang amprah');
    }
  }

  Future<List<AmprahHeaderModel>> getDaftarAmprah({String? status, String? urgensi}) async {
    try {
      final response = await _client.dio.get(
        '/distribusi/amprah',
        queryParameters: {
          if (status != null && status.isNotEmpty && status != 'SEMUA') 'status': status,
          if (urgensi != null && urgensi.isNotEmpty && urgensi != 'SEMUA') 'urgensi': urgensi,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => AmprahHeaderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat daftar amprah ruangan');
    }
  }

  Future<AmprahHeaderModel> getDetailAmprah(int id) async {
    try {
      final response = await _client.dio.get('/distribusi/amprah/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return AmprahHeaderModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format rincian amprah tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat rincian amprah');
    }
  }

  Future<Map<String, dynamic>> submitAmprah({
    int? gudangId,
    required String urgensi,
    String? catatan,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _client.dio.post(
        '/distribusi/amprah',
        data: {
          if (gudangId != null) 'gudang_id': gudangId,
          'urgensi': urgensi,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan.trim(),
          'items': items,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: 'Format respons pengajuan amprah tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal mengajukan amprah ruangan');
    }
  }

  Future<void> batalAmprah(int id) async {
    try {
      final response = await _client.dio.post('/distribusi/amprah/$id/batal');
      final data = response.data;
      if (data is Map<String, dynamic> && data['sukses'] == false) {
        throw ApiException(message: data['pesan']?.toString() ?? 'Gagal membatalkan amprah');
      }
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal membatalkan amprah');
    }
  }

  Future<List<PickingAntreanModel>> getAntreanPicking() async {
    try {
      final response = await _client.dio.get('/distribusi/antrean-picking');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => PickingAntreanModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return [];
      }
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat antrean picking');
    }
  }

  Future<Map<String, dynamic>> eksekusiPicking(int permintaanId) async {
    try {
      final response = await _client.dio.post(
        '/distribusi/picking',
        data: {
          'permintaan_id': permintaanId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: 'Format respons picking tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal eksekusi picking FEFO');
    }
  }

  Future<List<SppbHeaderModel>> getSppbInbound() async {
    try {
      final response = await _client.dio.get('/distribusi/sppb-inbound');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => SppbHeaderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat kiriman SPPB ruangan');
    }
  }

  Future<Map<String, dynamic>> konfirmasiTerimaSppb(int sppbId) async {
    try {
      final response = await _client.dio.post('/distribusi/sppb/$sppbId/terima');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: 'Format respons konfirmasi terima SPPB tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal konfirmasi penerimaan barang');
    }
  }
}
