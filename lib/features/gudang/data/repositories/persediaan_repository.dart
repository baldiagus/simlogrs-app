import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/buku_mutasi_model.dart';
import '../models/fefo_monitoring_model.dart';
import '../models/penyesuaian_stok_model.dart';
import '../models/stock_opname_model.dart';

final persediaanRepositoryProvider = Provider<PersediaanRepository>((ref) {
  return PersediaanRepository(ref.watch(dioClientProvider));
});

class PersediaanRepository {
  final DioClient _client;

  PersediaanRepository(this._client);

  /// 1. Monitoring Stok FEFO
  Future<FefoMonitoringResponse> getMonitoringFefo({
    String? kategori,
    int? gudangId,
    String? cari,
  }) async {
    try {
      final response = await _client.dio.get(
        '/gudang/fefo/monitoring',
        queryParameters: {
          if (kategori != null && kategori.isNotEmpty) 'kategori': kategori,
          if (gudangId != null) 'gudang_id': gudangId,
          if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return FefoMonitoringResponse.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format data FEFO tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat monitoring FEFO');
    }
  }

  /// 2. Buku Mutasi Kartu Stok
  Future<List<BukuMutasiItemModel>> getBukuMutasi({
    String? jenis,
    int? gudangId,
    int? barangId,
    String? tanggalMulai,
    String? tanggalSelesai,
    String? cari,
  }) async {
    try {
      final response = await _client.dio.get(
        '/gudang/mutasi/buku',
        queryParameters: {
          if (jenis != null && jenis.isNotEmpty) 'jenis': jenis,
          if (gudangId != null) 'gudang_id': gudangId,
          if (barangId != null) 'barang_id': barangId,
          if (tanggalMulai != null && tanggalMulai.isNotEmpty) 'tanggal_mulai': tanggalMulai,
          if (tanggalSelesai != null && tanggalSelesai.isNotEmpty) 'tanggal_selesai': tanggalSelesai,
          if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => BukuMutasiItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat buku mutasi stok');
    }
  }

  /// 3. Daftar Sesi Stock Opname
  Future<List<StokOpnameSesiModel>> getDaftarOpname({String? status, int? gudangId}) async {
    try {
      final response = await _client.dio.get(
        '/gudang/opname/sesi',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (gudangId != null) 'gudang_id': gudangId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => StokOpnameSesiModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat daftar sesi opname');
    }
  }

  /// 4. Inisiasi Sesi Opname Baru
  Future<void> inisiasiOpname({
    required int gudangId,
    required String tanggalOpname,
    String? catatan,
  }) async {
    try {
      await _client.dio.post(
        '/gudang/opname/inisiasi',
        data: {
          'gudang_id': gudangId,
          'tanggal_opname': tanggalOpname,
          if (catatan != null) 'catatan': catatan,
        },
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal menginisiasi stock opname');
    }
  }

  /// 5. Simpan Hasil Hitung Fisik (Blind Count)
  Future<void> simpanHitungFisik({
    required int opnameId,
    required List<Map<String, dynamic>> items,
    bool finalisasi = false,
  }) async {
    try {
      await _client.dio.post(
        '/gudang/opname/$opnameId/count',
        data: {
          'items': items,
          'finalisasi': finalisasi,
        },
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal menyimpan hitung fisik');
    }
  }

  /// 6. Daftar Dokumen Otorisasi Penyesuaian Stok
  Future<List<PenyesuaianStokHeaderModel>> getDaftarPenyesuaian({String? status, int? gudangId}) async {
    try {
      final response = await _client.dio.get(
        '/gudang/penyesuaian',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (gudangId != null) 'gudang_id': gudangId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => PenyesuaianStokHeaderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat otorisasi penyesuaian');
    }
  }

  /// 7. Sahkan Penyesuaian Stok (Approve)
  Future<void> approvePenyesuaian(int id) async {
    try {
      await _client.dio.post('/gudang/penyesuaian/$id/approve');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal mengesahkan penyesuaian');
    }
  }

  /// 8. Tolak Penyesuaian Stok (Reject)
  Future<void> rejectPenyesuaian(int id, {String? alasan}) async {
    try {
      await _client.dio.post(
        '/gudang/penyesuaian/$id/reject',
        data: {
          if (alasan != null && alasan.isNotEmpty) 'alasan': alasan,
        },
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal menolak penyesuaian');
    }
  }
}
