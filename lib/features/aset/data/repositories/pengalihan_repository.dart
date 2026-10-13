import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/pengalihan_model.dart';
import '../models/aset_tersedia_model.dart';

/// Repository API pengalihan aset/barang: daftar, pengajuan, otorisasi, serah terima, dan pembatalan.
class PengalihanRepository {
  final DioClient _client;

  /// Membuat repository dengan [DioClient] untuk akses HTTP.
  PengalihanRepository(this._client);

  /// Mengambil daftar pengalihan per [tab] dan [tipe] (ASET/BARANG) dari endpoint yang sesuai.
  Future<List<PengalihanItemModel>> getDaftarPengalihan({
    String tab = 'aktif',
    String tipe = 'ASET',
  }) async {
    try {
      final endpoint = tipe == 'BARANG' ? '/gudang/pengalihan-barang' : '/aset/pengalihan';
      final response = await _client.dio.get(
        endpoint,
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
      throw ApiException(message: e.message ?? 'Gagal memuat daftar pengalihan');
    }
  }

  /// Mengajukan pengalihan aset dan mengembalikan data hasilnya.
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

  /// Mengajukan pengalihan barang gudang dan mengembalikan data hasilnya.
  Future<Map<String, dynamic>> submitPengalihanBarang(Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.post(
        '/gudang/pengalihan-barang',
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
      throw ApiException(message: e.message ?? 'Gagal mengajukan pengalihan barang');
    }
  }

  /// Mengambil inventaris aset asal yang dapat dialihkan.
  Future<List<AsetTersediaModel>> getDaftarAsetAsal() async {
    try {
      final response = await _client.dio.get('/aset/pengalihan/inventaris-asal');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => AsetTersediaModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat inventaris aset asal');
    }
  }

  /// Mengambil jumlah stok tersedia barang di gudang; mengembalikan 0 bila gagal.
  Future<int> getStokTersedia({required int barangId, required int gudangId}) async {
    try {
      final response = await _client.dio.get(
        '/gudang/stok-tersedia',
        queryParameters: {'barang_id': barangId, 'gudang_id': gudangId},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return (data['data']['stok_tersedia'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Mengirim keputusan otorisasi pengalihan [id] (aset atau barang) beserta catatan opsional.
  Future<void> otorisasiPengalihan({
    required int id,
    required String aksi,
    String? catatan,
    String tipe = 'ASET',
  }) async {
    try {
      final endpoint = tipe == 'BARANG'
          ? '/gudang/pengalihan-barang/$id/otorisasi'
          : '/aset/pengalihan/$id/otorisasi';
      await _client.dio.post(
        endpoint,
        data: {
          'aksi': aksi,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        },
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memproses otorisasi pengalihan');
    }
  }

  /// Menyelesaikan serah terima fisik pengalihan [id] dengan kondisi yang diterima.
  Future<void> serahTerimaPengalihan({
    required int id,
    String kondisi = 'BAIK',
    String tipe = 'ASET',
  }) async {
    try {
      final endpoint = tipe == 'BARANG'
          ? '/gudang/pengalihan-barang/$id/serah-terima'
          : '/aset/pengalihan/$id/serah-terima';
      await _client.dio.post(
        endpoint,
        data: {'kondisi': kondisi},
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memproses serah terima fisik');
    }
  }

  /// Membatalkan pengalihan [id] dengan alasan opsional.
  Future<void> batalPengalihan({
    required int id,
    String? alasan,
    String tipe = 'ASET',
  }) async {
    try {
      final endpoint = tipe == 'BARANG'
          ? '/gudang/pengalihan-barang/$id/batal'
          : '/aset/pengalihan/$id/batal';
      await _client.dio.post(
        endpoint,
        data: {if (alasan != null && alasan.isNotEmpty) 'alasan': alasan},
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal membatalkan pengalihan');
    }
  }
}
