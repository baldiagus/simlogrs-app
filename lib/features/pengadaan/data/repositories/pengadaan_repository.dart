import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/master_barang_model.dart';
import '../models/pr_model.dart';
import '../models/po_model.dart';

class PengadaanRepository {
  final DioClient _client;

  /// Membuat repository dengan [DioClient] untuk memanggil API pengadaan.
  PengadaanRepository(this._client);

  /// Mengambil katalog barang dari server, dapat difilter kata kunci [cari] dan jenis barang [tipe].
  Future<List<MasterBarangModel>> getKatalogBarang({String? cari, String? tipe}) async {
    try {
      final response = await _client.dio.get(
        '/master/barang',
        queryParameters: {
          if (cari != null && cari.isNotEmpty) 'cari': cari,
          if (tipe != null && tipe.isNotEmpty) 'tipe': tipe,
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

  /// Mengambil daftar permintaan pengadaan (PR) milik pengguna dari server.
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

  /// Mengirim PR baru ke server; bila [isKaru] true, PR langsung disetujui otomatis.
  Future<Map<String, dynamic>> submitPr({
    int? unitId,
    int? gudangId,
    required String urgensi,
    String? catatan,
    required List<Map<String, dynamic>> items,
    bool isKaru = false,
  }) async {
    try {
      final response = await _client.dio.post(
        '/pengadaan/pr',
        data: {
          if (unitId != null) 'unit_id': unitId,
          if (gudangId != null) 'gudang_id': gudangId,
          'urgensi': urgensi,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
          'items': items,
          if (isKaru) 'status': 'DISETUJUI',
          if (isKaru) 'auto_approve': true,
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
  /// Mengambil daftar pemasok/rekanan aktif
  Future<List<PemasokOptionModel>> getDaftarPemasok() async {
    try {
      final response = await _client.dio.get('/pengadaan/pemasok');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => PemasokOptionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat daftar pemasok');
    }
  }

  /// Mengambil daftar pesanan pembelian (PO)
  Future<List<PesananPembelianModel>> getDaftarPo({String? status, String? search}) async {
    try {
      final response = await _client.dio.get(
        '/pengadaan/po',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => PesananPembelianModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat daftar PO');
    }
  }


  /// Menerbitkan dokumen PO baru dari PR yang statusnya sudah diserahkan ke pengadaan
  Future<Map<String, dynamic>> terbitkanPo({
    required int prId,
    required int pemasokId,
    String? estimasiTanggalKirim,
    String syaratPembayaran = 'TEMPO_30_HARI',
    String? catatan,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _client.dio.post(
        '/pengadaan/po',
        data: {
          'permintaan_pengadaan_id': prId,
          'pemasok_id': pemasokId,
          if (estimasiTanggalKirim != null) 'estimasi_tanggal_kirim': estimasiTanggalKirim,
          'syarat_pembayaran': syaratPembayaran,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
          'items': items,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: 'Format respons penerbitan PO tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal menerbitkan PO');
    }
  }

  /// Memperbarui status PO yang sudah diterbitkan menjadi DIKIRIM_VENDOR
  Future<Map<String, dynamic>> updateStatusKirim(int id, {String? estimasiTanggalKirim}) async {
    try {
      final response = await _client.dio.post(
        '/pengadaan/po/$id/kirim',
        data: {
          if (estimasiTanggalKirim != null) 'estimasi_tanggal_kirim': estimasiTanggalKirim,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: 'Format respons update kirim PO tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memperbarui status pengiriman PO');
    }
  }
}
