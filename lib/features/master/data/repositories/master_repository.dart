import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/master_barang_item_model.dart';
import '../models/register_aset_item_model.dart';

final masterRepositoryProvider = Provider<MasterRepository>((ref) {
  return MasterRepository(ref.watch(dioClientProvider));
});

class MasterRepository {
  final DioClient _client;

  MasterRepository(this._client);

  /// Mengambil daftar seluruh master komoditas barang
  Future<List<MasterBarangItemModel>> getBarangLengkap({
    String? tipe,
    int? kategoriId,
    String? status,
    String? cari,
  }) async {
    try {
      final response = await _client.dio.get(
        '/master/barang-lengkap',
        queryParameters: {
          if (tipe != null && tipe.isNotEmpty) 'tipe': tipe,
          if (kategoriId != null) 'kategori_id': kategoriId,
          if (status != null && status.isNotEmpty) 'status': status,
          if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => MasterBarangItemModel.fromJson(e as Map<String, dynamic>))
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

  /// Mengambil rincian profil lengkap satu komoditas barang
  Future<DetailBarangModel> getDetailBarang(int id) async {
    try {
      final response = await _client.dio.get('/master/barang/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return DetailBarangModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format detail komoditas tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat detail komoditas barang');
    }
  }

  /// Mengambil daftar register seluruh aset fisik rumah sakit
  Future<List<RegisterAsetItemModel>> getAsetLengkap({
    String? lokasiTipe,
    String? status,
    String? kondisi,
    String? cari,
  }) async {
    try {
      final response = await _client.dio.get(
        '/master/aset-lengkap',
        queryParameters: {
          if (lokasiTipe != null && lokasiTipe.isNotEmpty) 'lokasi_tipe': lokasiTipe,
          if (status != null && status.isNotEmpty) 'status': status,
          if (kondisi != null && kondisi.isNotEmpty) 'kondisi': kondisi,
          if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => RegisterAsetItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat register aset');
    }
  }

  /// Mengambil daftar kategori barang untuk filter
  Future<List<Map<String, dynamic>>> getKategoriList() async {
    try {
      final response = await _client.dio.get('/master/kategori');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List).map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      return [];
    }
  }
}
