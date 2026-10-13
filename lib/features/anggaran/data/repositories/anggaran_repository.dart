import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/anggaran_models.dart';

/// Provider singleton [AnggaranRepository] dengan [DioClient] bersama.
final anggaranRepositoryProvider = Provider<AnggaranRepository>((ref) {
  return AnggaranRepository(ref.watch(dioClientProvider));
});

/// Repository akses API anggaran: screening pagu/realisasi dan drilldown per unit.
class AnggaranRepository {
  final DioClient _client;

  AnggaranRepository(this._client);

  /// 1. Mengambil data screening pagu & realisasi pengeluaran logistik & sparepart
  Future<AnggaranScreeningModel> getScreeningAnggaran({String tahun = '2026'}) async {
    try {
      final response = await _client.dio.get(
        '/anggaran/realisasi',
        queryParameters: {'tahun': tahun},
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return AnggaranScreeningModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format data pagu & realisasi tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat data pagu & realisasi anggaran');
    }
  }

  /// 2. Mengambil rincian drilldown bukti fisik pengeluaran satu unit kerja
  Future<UnitDrilldownModel> getUnitDetail(int unitId, {String tahun = '2026'}) async {
    try {
      final response = await _client.dio.get(
        '/anggaran/unit/$unitId',
        queryParameters: {'tahun': tahun},
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return UnitDrilldownModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format rincian drilldown unit tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat rincian drilldown unit');
    }
  }
}
