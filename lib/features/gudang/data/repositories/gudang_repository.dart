import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/rak_model.dart';
import '../models/aset_rak_model.dart';
import '../models/po_inbound_model.dart';

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

  Future<List<PoInboundHeaderModel>> getPoInboundList() async {
    try {
      final response = await _client.dio.get('/gudang/po-inbound');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => PoInboundHeaderModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return [];
      }
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat daftar PO inbound');
    }
  }

  Future<Map<String, dynamic>> submitPenerimaanPo({
    required int poId,
    required String nomorSuratJalan,
    String? catatan,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _client.dio.post(
        '/gudang/penerimaan-po',
        data: {
          'pesanan_pembelian_id': poId,
          'nomor_surat_jalan': nomorSuratJalan,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
          'items': items,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: 'Format respons penerimaan barang tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal menyimpan penerimaan barang');
    }
  }
  Future<Map<String, dynamic>> tolakPenerimaanPo({
    required int poId,
    required String nomorSuratJalan,
    required String alasanPenolakan,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _client.dio.post(
        '/gudang/penerimaan-po/tolak',
        data: {
          'pesanan_pembelian_id': poId,
          'nomor_surat_jalan': nomorSuratJalan,
          'alasan_penolakan': alasanPenolakan,
          'items': items,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return {'status': 'DITOLAK'};
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal menolak penerimaan barang');
    }
  }
}
