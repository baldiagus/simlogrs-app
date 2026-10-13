import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/approval_item_model.dart';

/// Akses API approval: ambil antrean pending dan eksekusi persetujuan PR/Amprah.
class ApprovalRepository {
  final DioClient _client;

  ApprovalRepository(this._client);

  /// Mengambil antrean PR dan Amprah yang menunggu persetujuan user.
  Future<ApprovalPendingResponse> getPending() async {
    try {
      final response = await _client.dio.get('/approval/pending');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return ApprovalPendingResponse.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: 'Format data approval tidak valid');
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memuat antrean approval');
    }
  }

  /// Mengirim keputusan (setujui/tolak) untuk satu PR beserta catatan opsional.
  Future<void> executeApprovalPr({
    required int id,
    required String aksi,
    String? catatan,
  }) async {
    try {
      final response = await _client.dio.post(
        '/approval/pr/$id',
        data: {
          'aksi': aksi,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['sukses'] == false) {
        throw ApiException(message: data['pesan']?.toString() ?? 'Gagal memproses PR');
      }
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memproses persetujuan PR');
    }
  }

  /// Mengirim keputusan setujui/tolak untuk satu Amprah beserta catatan opsional.
  Future<void> executeApprovalAmprah({
    required int id,
    required bool isSetujui,
    String? catatan,
  }) async {
    try {
      final response = await _client.dio.post(
        '/approval/amprah/$id',
        data: {
          'aksi': isSetujui ? 'setujui' : 'tolak',
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['sukses'] == false) {
        throw ApiException(message: data['pesan']?.toString() ?? 'Gagal memproses Amprah');
      }
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Gagal memproses persetujuan Amprah');
    }
  }
}
