import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/aset_detail_model.dart';
import '../models/aset_tersedia_model.dart';
import '../models/peminjaman_aset_model.dart';

/// Repository API aset: scan QR, katalog, peminjaman, otorisasi, serah terima, dan pengembalian.
class AsetRepository {
  final DioClient _client;

  /// Membuat repository dengan [DioClient] untuk akses HTTP.
  AsetRepository(this._client);

  /// Mencari detail aset berdasarkan kode/QR hasil scan; melempar [ApiException] bila tidak ditemukan.
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

  /// Mengambil detail aset berdasarkan [id]; melempar [ApiException] bila gagal.
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

  /// Mengambil katalog aset tersedia, dengan filter opsional pencarian, tipe penyedia, dan tujuan.
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

  /// Mengambil daftar peminjaman aset, difilter opsional berdasarkan status dan perspektif (peminjam/penyedia).
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

  /// Mengajukan peminjaman aset baru dan mengembalikan data peminjaman yang dibuat server.
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

  /// Membatalkan peminjaman [id]; melempar [ApiException] bila server menolak.
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

  /// Mengajukan perpanjangan masa peminjaman [id] ke tanggal baru beserta alasannya.
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

  /// Mengambil antrean approval peminjaman; mengembalikan daftar kosong bila user tidak berhak (403).
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

  /// Mengirim keputusan otorisasi (setujui/tolak/serah terima) untuk peminjaman [id].
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

  /// Mengonfirmasi serah terima fisik aset untuk peminjaman [peminjamanId].
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

  /// Mencatat pengembalian aset beserta hasil inspeksi kondisi; pesan error diambil dari respons server bila ada.
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
