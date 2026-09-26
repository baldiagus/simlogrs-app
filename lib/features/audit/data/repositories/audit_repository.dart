import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/audit_models.dart';

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(dioClientProvider));
});

class AuditRepository {
  final DioClient _client;

  AuditRepository(this._client);

  /// 1. Ringkasan Eksekutif Audit SPI & CAPA
  Future<AuditSummaryModel> getSummary() async {
    try {
      final response = await _client.dio.get('/audit/summary');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return AuditSummaryModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format ringkasan audit tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat ringkasan audit');
    }
  }

  /// 2. Digital Forensic Audit Trail
  Future<List<AuditTrailItemModel>> getAuditTrail({
    String? aksi,
    String? entitas,
    String? search,
    int page = 1,
  }) async {
    try {
      final response = await _client.dio.get(
        '/audit/trail',
        queryParameters: {
          if (aksi != null && aksi.isNotEmpty) 'aksi': aksi,
          if (entitas != null && entitas.isNotEmpty) 'entitas': entitas,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'page': page,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic> &&
          data['data']['items'] is List) {
        return (data['data']['items'] as List)
            .map((e) => AuditTrailItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat audit trail');
    }
  }

  /// 3. Detail Forensik Log Audit (Perubahan Nilai Lama vs Baru)
  Future<AuditTrailItemModel> getAuditTrailDetail(int id) async {
    try {
      final response = await _client.dio.get('/audit/trail/$id');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return AuditTrailItemModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format detail audit log tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat detail log audit');
    }
  }

  /// 4. Audit Kepatuhan Pengadaan PO vs PR
  Future<List<KepatuhanPoModel>> getKepatuhanPengadaan({
    String? anomali,
    String? search,
    int page = 1,
  }) async {
    try {
      final response = await _client.dio.get(
        '/audit/kepatuhan-pengadaan',
        queryParameters: {
          if (anomali != null && anomali.isNotEmpty) 'anomali': anomali,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'page': page,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic> &&
          data['data']['items'] is List) {
        return (data['data']['items'] as List)
            .map((e) => KepatuhanPoModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat audit kepatuhan');
    }
  }

  /// 5. Terbitkan Temuan CAPA dari Anomali PO
  Future<void> buatTemuanKepatuhan(
    int poId, {
    required String tingkatRisiko,
    required String dueDateCapa,
    String? ringkasan,
    String? tipeAnomali,
  }) async {
    try {
      await _client.dio.post(
        '/audit/kepatuhan-pengadaan/$poId/capa',
        data: {
          'tingkat_risiko': tingkatRisiko,
          'due_date_capa': dueDateCapa,
          if (ringkasan != null && ringkasan.trim().isNotEmpty) 'ringkasan': ringkasan.trim(),
          if (tipeAnomali != null) 'tipe_anomali': tipeAnomali,
        },
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal menerbitkan temuan CAPA');
    }
  }

  /// 6. Pemeriksaan Selisih Opname Fisik vs Sistem
  Future<Map<String, dynamic>> getSelisihOpname() async {
    try {
      final response = await _client.dio.get('/audit/selisih-opname');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final payload = data['data'] as Map<String, dynamic>;
        final sesiList = (payload['sesi_opname'] as List<dynamic>?)
                ?.map((e) => SesiOpnameSelisihModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        final penyesuaianList = (payload['penyesuaian'] as List<dynamic>?)
                ?.map((e) => PenyesuaianStokAuditModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        return {
          'sesi_opname': sesiList,
          'penyesuaian': penyesuaianList,
        };
      }
      return {'sesi_opname': <SesiOpnameSelisihModel>[], 'penyesuaian': <PenyesuaianStokAuditModel>[]};
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat audit selisih opname');
    }
  }

  /// 7. Register Temuan Audit & CAPA
  Future<List<TemuanCapaModel>> getRegisterTemuan({
    String? status,
    String? risiko,
    String? search,
    int page = 1,
  }) async {
    try {
      final response = await _client.dio.get(
        '/audit/temuan-capa',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (risiko != null && risiko.isNotEmpty) 'risiko': risiko,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'page': page,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic> &&
          data['data']['items'] is List) {
        return (data['data']['items'] as List)
            .map((e) => TemuanCapaModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal memuat register temuan CAPA');
    }
  }

  /// 8. Penerbitan Temuan Audit Baru
  Future<void> simpanTemuan({
    required String objekAudit,
    required String ringkasan,
    required String tingkatRisiko,
    required String tanggalAudit,
    required String dueDateCapa,
    int? unitId,
    int? gudangId,
  }) async {
    try {
      await _client.dio.post(
        '/audit/temuan-capa',
        data: {
          'objek_audit': objekAudit,
          'ringkasan': ringkasan,
          'tingkat_risiko': tingkatRisiko,
          'tanggal_audit': tanggalAudit,
          'due_date_capa': dueDateCapa,
          if (unitId != null) 'unit_id': unitId,
          if (gudangId != null) 'gudang_id': gudangId,
        },
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal mendaftarkan temuan audit');
    }
  }

  /// 9. Tindak Lanjut Auditee
  Future<void> tindakLanjutTemuan(
    int id, {
    required String analisisPenyebab,
    required String tindakanPerbaikan,
    String? buktiPerbaikan,
  }) async {
    try {
      await _client.dio.post(
        '/audit/temuan-capa/$id/tindak-lanjut',
        data: {
          'analisis_penyebab': analisisPenyebab,
          'tindakan_perbaikan': tindakanPerbaikan,
          if (buktiPerbaikan != null) 'bukti_perbaikan': buktiPerbaikan,
        },
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal mengirimkan tindak lanjut');
    }
  }

  /// 10. Evaluasi Closing Auditor SPI
  Future<void> evaluasiTemuan(
    int id, {
    required String hasilEvaluasi,
    required String catatanEvaluasi,
  }) async {
    try {
      await _client.dio.post(
        '/audit/temuan-capa/$id/evaluasi',
        data: {
          'hasil_evaluasi': hasilEvaluasi,
          'catatan_evaluasi': catatanEvaluasi,
        },
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Gagal menyimpan evaluasi closing');
    }
  }
}
