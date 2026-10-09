import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/aset_detail_model.dart';
import '../models/aset_tersedia_model.dart';
import '../models/peminjaman_aset_model.dart';

class AsetRepository {
  final DioClient _client;

  AsetRepository(this._client);

  Future<AsetDetailModel> scanQr(String kodeAset) async {
    try {
      final response = await _client.dio.post(
        '/aset/scan-qr',
        data: {
          'kode_aset': kodeAset.trim(),
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return AsetDetailModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format data aset tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Aset tidak ditemukan');
    }
  }

  Future<AsetDetailModel> getDetailAset(int id) async {
    try {
      final response = await _client.dio.get('/aset/detail/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return AsetDetailModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format data aset tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Aset tidak ditemukan');
    }
  }

  Future<List<AsetTersediaModel>> getKatalogTersedia({String? cari, String? penyediaTipe, String? tujuan}) async {
    try {
      final response = await _client.dio.get(
        '/aset/katalog-tersedia',
        queryParameters: {
          if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
          if (penyediaTipe != null) 'penyedia_tipe': penyediaTipe,
          if (tujuan != null) 'tujuan': tujuan,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => AsetTersediaModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat katalog aset tersedia');
    }
  }

  Future<List<PeminjamanAsetModel>> getDaftarPeminjaman({String? status, String? perspektif}) async {
    try {
      final response = await _client.dio.get(
        '/aset/peminjaman',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (perspektif != null && perspektif.isNotEmpty) 'perspektif': perspektif,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => PeminjamanAsetModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat daftar peminjaman');
    }
  }

  Future<Map<String, dynamic>> simpanPeminjaman({
    required int asetId,
    required String tanggalPinjam,
    required String tanggalKembaliRencana,
    required String keperluan,
    String? catatan,
  }) async {
    try {
      final response = await _client.dio.post(
        '/aset/peminjaman',
        data: {
          'aset_id': asetId,
          'tanggal_pinjam': tanggalPinjam,
          'tanggal_kembali_rencana': tanggalKembaliRencana,
          'keperluan': keperluan,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: 'Format respons peminjaman tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal mengajukan peminjaman aset');
    }
  }

  Future<void> batalPeminjaman(int id) async {
    try {
      final response = await _client.dio.post('/aset/peminjaman/$id/batal');
      final data = response.data;
      if (data is Map<String, dynamic> && data['sukses'] == false) {
        throw ApiException(message: data['pesan']?.toString() ?? 'Gagal membatalkan peminjaman');
      }
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal membatalkan peminjaman aset');
    }
  }

  Future<void> perpanjangPeminjaman({
    required int id,
    required String tanggalKembaliBaru,
    required String alasan,
  }) async {
    try {
      final response = await _client.dio.post(
        '/aset/peminjaman/$id/perpanjang',
        data: {
          'tanggal_kembali_baru': tanggalKembaliBaru,
          'alasan': alasan,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['sukses'] == false) {
        throw ApiException(message: data['pesan']?.toString() ?? 'Gagal memperpanjang peminjaman');
      }
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memperpanjang peminjaman aset');
    }
  }

  Future<List<ApprovalPeminjamanModel>> getDaftarApprovalPeminjaman() async {
    try {
      final response = await _client.dio.get('/aset/approval-peminjaman');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => ApprovalPeminjamanModel.fromJson(e as Map<String, dynamic>))
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
      throw ApiException(message: e.message ?? 'Gagal memuat antrean otorisasi peminjaman');
    }
  }

  Future<Map<String, dynamic>> otorisasiPeminjaman({
    required int id,
    required String aksi,
    String? catatan,
  }) async {
    try {
      final response = await _client.dio.post(
        '/aset/peminjaman/$id/otorisasi',
        data: {
          'aksi': aksi,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: 'Format respons otorisasi tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memproses otorisasi peminjaman');
    }
  }

  Future<Map<String, dynamic>> serahTerima(int peminjamanId) async {
    try {
      final response = await _client.dio.post(
        '/aset/serah-terima',
        data: {
          'peminjaman_id': peminjamanId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: 'Format respons serah terima tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memproses serah terima aset');
    }
  }

  Future<Map<String, dynamic>> kembalikan({
    required int peminjamanId,
    required List<Map<String, dynamic>> inspeksi,
    String? catatan,
  }) async {
    try {
      final response = await _client.dio.post(
        '/aset/kembalikan',
        data: {
          'peminjaman_id': peminjamanId,
          'inspeksi': inspeksi,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: 'Format respons pengembalian tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message'] ?? e.response?.data['pesan'] ?? e.message)
          : (e.message ?? 'Gagal memproses pengembalian aset');
      throw ApiException(message: msg?.toString() ?? 'Gagal memproses pengembalian aset');
    }
  }
}
