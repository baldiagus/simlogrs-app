import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simlog_mobile/core/models/pagination_meta.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/spk_model.dart';
import '../models/tiket_maintenance_model.dart';
import '../models/teknisi_option_model.dart';

class MaintenanceRepository {
  final DioClient _client;

  /// Membuat MaintenanceRepository.
  MaintenanceRepository(this._client);

  /// Ambil daftar tiket unit dengan filter status, prioritas, dan pencarian.
  Future<List<TiketMaintenanceModel>> getDaftarTiketUnit({
    String? status,
    String? prioritas,
    String? cari,
  }) async {
    try {
      final response = await _client.dio.get(
        '/maintenance/tiket',
        queryParameters: {
          if (status != null && status.isNotEmpty && status != 'SEMUA') 'status': status,
          if (prioritas != null && prioritas.isNotEmpty && prioritas != 'SEMUA') 'prioritas': prioritas,
          if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => TiketMaintenanceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat daftar tiket kerusakan');
    }
  }

  /// Ambil daftar aset unit yang tersedia untuk dilaporkan.
  Future<List<AsetUnitModel>> getAsetUnitTersedia() async {
    try {
      final response = await _client.dio.get('/maintenance/aset-unit');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => AsetUnitModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat inventaris sarana ruangan');
    }
  }

  /// Ambil detail satu tiket unit berdasarkan ID.
  Future<TiketDetailModel> getDetailTiketUnit(int id) async {
    try {
      final response = await _client.dio.get('/maintenance/tiket/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return TiketDetailModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format rincian tiket tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat rincian tiket');
    }
  }

  /// Batalkan tiket unit berdasarkan ID lewat API.
  Future<void> batalTiketUnit(int id) async {
    try {
      final response = await _client.dio.post('/maintenance/tiket/$id/batal');
      final data = response.data;
      if (data is Map<String, dynamic> && data['sukses'] == false) {
        throw ApiException(message: data['pesan']?.toString() ?? 'Gagal membatalkan tiket');
      }
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal membatalkan tiket kerusakan');
    }
  }

  /// Ambil daftar teknisi yang dapat ditugaskan.
  Future<List<TeknisiOptionModel>> getDaftarTeknisi() async {
    try {
      final response = await _client.dio.get('/maintenance/teknisi');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => TeknisiOptionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat daftar teknisi');
    }
  }

  Future<Map<String, dynamic>> disposisiTiket({
    required int tiketId,
    required int teknisiId,
    String? tanggalPenugasan,
    String? targetSelesai,
    String? instruksiKhusus,
  }) async {
    try {
      final response = await _client.dio.post(
        '/maintenance/tiket/$tiketId/disposisi',
        data: {
          'teknisi_id': teknisiId,
          if (tanggalPenugasan != null) 'tanggal_penugasan': tanggalPenugasan,
          if (targetSelesai != null) 'target_selesai': targetSelesai,
          if (instruksiKhusus != null && instruksiKhusus.isNotEmpty) 'instruksi_khusus': instruksiKhusus,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal mendisposisikan tiket');
    }
  }

  /// Ambil daftar SPK berhalaman, opsional difilter status dan nomor halaman.
  Future<PagedResponse<SpkHeaderModel>> getSpkList({
    String? status,
    int page = 1,
  }) async {
    try {
      final response = await _client.dio.get(
        '/maintenance/spk',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          'page': page,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final inner = data['data'] as Map<String, dynamic>;
        final items = (inner['spk'] is List)
            ? (inner['spk'] as List)
                .map((e) => SpkHeaderModel.fromJson(e as Map<String, dynamic>))
                .toList()
            : <SpkHeaderModel>[];
        final meta = (inner['paginasi'] is Map<String, dynamic>)
            ? PaginationMeta.fromJson(inner['paginasi'] as Map<String, dynamic>)
            : PaginationMeta.empty;
        return PagedResponse<SpkHeaderModel>(items: items, meta: meta);
      }
      return PagedResponse.empty<SpkHeaderModel>();
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat daftar SPK teknisi');
    }
  }

  /// Ambil detail SPK berdasarkan ID.
  Future<SpkDetailModel> getSpkDetail(int id) async {
    try {
      final response = await _client.dio.get('/maintenance/spk/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return SpkDetailModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format rincian SPK tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat rincian SPK');
    }
  }

  Future<Map<String, dynamic>> submitLaporCepat({
    int? asetId,
    String? kodeAset,
    required String deskripsiMasalah,
    required String prioritas,
    XFile? foto,
  }) async {
    try {
      FormData? formData;
      if (foto != null) {
        final bytes = await foto.readAsBytes();
        formData = FormData.fromMap({
          if (asetId != null) 'aset_id': asetId,
          if (kodeAset != null && kodeAset.isNotEmpty) 'kode_aset': kodeAset.trim(),
          'deskripsi_masalah': deskripsiMasalah.trim(),
          'prioritas': prioritas,
          'foto': MultipartFile.fromBytes(bytes, filename: foto.name),
        });
      }

      final response = await _client.dio.post(
        '/maintenance/lapor-cepat',
        data: formData ??
            {
              if (asetId != null) 'aset_id': asetId,
              if (kodeAset != null && kodeAset.isNotEmpty) 'kode_aset': kodeAset.trim(),
              'deskripsi_masalah': deskripsiMasalah.trim(),
              'prioritas': prioritas,
            },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: 'Format respons lapor cepat tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal mengirim laporan kerusakan');
    }
  }

  Future<Map<String, dynamic>> submitLembarKerja({
    required int spkId,
    required String diagnosa,
    required String tindakan,
    required String hasil,
    String? jamMulai,
    String? jamSelesai,
    String? catatan,
    XFile? foto,
    List<Map<String, dynamic>>? spareparts,
  }) async {
    try {
      FormData? formData;
      if (foto != null) {
        final bytes = await foto.readAsBytes();
        final map = <String, dynamic>{
          'diagnosa': diagnosa.trim(),
          'tindakan': tindakan.trim(),
          'hasil': hasil,
          if (jamMulai != null) 'jam_mulai': jamMulai,
          if (jamSelesai != null) 'jam_selesai': jamSelesai,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan.trim(),
          'foto': MultipartFile.fromBytes(bytes, filename: foto.name),
        };
        if (spareparts != null && spareparts.isNotEmpty) {
          for (var i = 0; i < spareparts.length; i++) {
            map['spareparts[$i][barang_id]'] = spareparts[i]['barang_id'];
            map['spareparts[$i][jumlah]'] = spareparts[i]['jumlah'];
          }
        }
        formData = FormData.fromMap(map);
      }

      final response = await _client.dio.post(
        '/maintenance/spk/$spkId/log',
        data: formData ??
            {
              'diagnosa': diagnosa.trim(),
              'tindakan': tindakan.trim(),
              'hasil': hasil,
              if (jamMulai != null) 'jam_mulai': jamMulai,
              if (jamSelesai != null) 'jam_selesai': jamSelesai,
              if (catatan != null && catatan.isNotEmpty) 'catatan': catatan.trim(),
              if (spareparts != null && spareparts.isNotEmpty) 'spareparts': spareparts,
            },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: 'Format respons lembar kerja tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal menyimpan lembar kerja teknisi');
    }
  }
}
