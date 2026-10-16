import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/amprah_model.dart';
import '../models/sppb_model.dart';

class DistribusiRepository {
  final DioClient _client;

  /// Membuat repository dengan [DioClient] yang dipakai untuk semua panggilan API distribusi.
  DistribusiRepository(this._client);

  /// Mengambil katalog barang yang bisa diamprah, difilter kata kunci [cari] dan gudang asal [gudangId].
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

  /// Mengambil daftar amprah ruangan, opsional difilter status/urgensi ("SEMUA" berarti tanpa filter).
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

  /// Mengambil rincian satu amprah beserta item-itemnya berdasarkan [id].
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

  /// Mengirim pengajuan amprah baru ke server dan mengembalikan data amprah yang terbentuk.
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

  /// Membatalkan amprah [id] yang masih boleh dibatalkan; melempar [ApiException] bila ditolak server.
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

  /// Mengirim keputusan setujui/tolak amprah [id] ke endpoint approval; catatan dikirim bila tidak kosong. Melempar [ApiException] bila ditolak server.
  Future<void> approveAmprah({
    required int id,
    required bool isSetujui,
    String? catatan,
    List<Map<String, int>>? items,
  }) async {
    try {
      final response = await _client.dio.post(
        '/approval/amprah/$id',
        data: {
          'aksi': isSetujui ? 'setujui' : 'tolak',
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
          if (items != null && items.isNotEmpty) 'items': items,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['sukses'] == false) {
        throw ApiException(message: data['pesan']?.toString() ?? 'Gagal memproses Amprah');
      }
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memproses persetujuan Amprah');
    }
  }

  /// Menutup sisa barang terhutang pada amprah [id] berstatus DIKIRIM_SEBAGIAN sehingga menjadi SELESAI.
  Future<void> tutupSisaAmprah(int id) async {
    try {
      final response = await _client.dio.post('/distribusi/amprah/$id/tutup-sisa');
      final data = response.data;
      if (data is Map<String, dynamic> && data['sukses'] == false) {
        throw ApiException(message: data['pesan']?.toString() ?? 'Gagal menutup sisa amprah');
      }
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal menutup sisa amprah');
    }
  }

  /// Mengambil antrean permintaan yang siap di-picking gudang; mengembalikan daftar kosong bila akses 403 (bukan petugas gudang).
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

  /// Menjalankan picking otomatis (FEFO) untuk permintaan [permintaanId] dan mengembalikan SPPB yang dihasilkan.
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

  /// Mengambil daftar SPPB kiriman gudang yang masuk ke unit ruangan.
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

  /// Mengonfirmasi bahwa barang pada SPPB [sppbId] sudah diterima unit sehingga stok ruangan bertambah.
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
