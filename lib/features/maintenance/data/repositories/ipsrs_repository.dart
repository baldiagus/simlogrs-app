import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/jadwal_preventif_model.dart';
import '../models/rekam_medis_aset_model.dart';

final ipsrsRepositoryProvider = Provider<IpsrsRepository>((ref) {
  return IpsrsRepository(ref.watch(dioClientProvider));
});

class IpsrsRepository {
  final DioClient _client;

  IpsrsRepository(this._client);

  /// 1. Daftar Jadwal Pemeliharaan Preventif
  Future<List<JadwalPreventifItemModel>> getJadwalPreventif({
    String? status,
    int? teknisiId,
    String? cari,
  }) async {
    try {
      final response = await _client.dio.get(
        '/maintenance/preventif/jadwal',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (teknisiId != null) 'teknisi_id': teknisiId,
          if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => JadwalPreventifItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat jadwal preventif');
    }
  }

  /// 2. Eksekusi Terbitkan SPK Preventif
  Future<Map<String, dynamic>> eksekusiPreventif(int id) async {
    try {
      final response = await _client.dio.post('/maintenance/preventif/$id/eksekusi');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal menerbitkan SPK preventif');
    }
  }
  /// Tambah Jadwal Pemeliharaan Preventif Baru
  Future<Map<String, dynamic>> simpanJadwalPreventif({
    required int asetId,
    required String jenisMaintenance,
    required int intervalNilai,
    required String intervalTipe,
    required String tanggalBerikutnya,
    int? teknisiId,
    String? catatan,
  }) async {
    try {
      final response = await _client.dio.post(
        '/maintenance/preventif/jadwal',
        data: {
          'aset_id': asetId,
          'jenis_maintenance': jenisMaintenance,
          'interval_nilai': intervalNilai,
          'interval_tipe': intervalTipe,
          'tanggal_berikutnya': tanggalBerikutnya,
          if (teknisiId != null) 'teknisi_id': teknisiId,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal menyimpan jadwal preventif');
    }
  }


  /// 3. Katalog Aset untuk Rekam Medis
  Future<List<RekamMedisAsetKatalogModel>> getKatalogRekamMedis({
    String? kondisi,
    String? cari,
  }) async {
    try {
      final response = await _client.dio.get(
        '/maintenance/rekam-medis/katalog',
        queryParameters: {
          if (kondisi != null && kondisi.isNotEmpty) 'kondisi': kondisi,
          if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => RekamMedisAsetKatalogModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat katalog rekam medis aset');
    }
  }

  /// 4. Detail Rekam Medis Satu Aset Fisik
  Future<RekamMedisDetailResponse> getRekamMedisAset(int asetId) async {
    try {
      final response = await _client.dio.get('/maintenance/rekam-medis/$asetId');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return RekamMedisDetailResponse.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format data rekam medis tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat rekam medis aset');
    }
  }
}
