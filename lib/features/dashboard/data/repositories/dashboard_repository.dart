import '../../../../core/network/dio_client.dart';
import '../models/dashboard_summary_model.dart';

class DashboardRepository {
  final DioClient _client;

  DashboardRepository(this._client);

  Future<DashboardSummaryModel> getSummary({bool canViewSpk = false}) async {
    int prCount = 0;
    int amprahCount = 0;
    int activeSpkCount = 0;
    final List<ActivityItemModel> activities = [];

    // 1. Fetch Pending Approvals
    try {
      final response = await _client.dio.get('/approval/pending');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final innerData = data['data'] as Map<String, dynamic>;

        if (innerData['pr'] is List) {
          final prList = innerData['pr'] as List;
          prCount = prList.length;
          for (final item in prList.take(5)) {
            if (item is Map<String, dynamic>) {
              activities.add(ActivityItemModel.fromPr(item));
            }
          }
        }

        if (innerData['amprah'] is List) {
          final amprahList = innerData['amprah'] as List;
          amprahCount = amprahList.length;
          for (final item in amprahList.take(5)) {
            if (item is Map<String, dynamic>) {
              activities.add(ActivityItemModel.fromAmprah(item));
            }
          }
        }
      }
    } catch (_) {
      // Abaikan jika user tidak memiliki permission melihat approval
    }

    // 2. Fetch Active SPK (Hanya jika user memiliki wewenang teknisi/admin)
    if (canViewSpk) {
      try {
        final spkResponse = await _client.dio.get('/maintenance/spk');
        final spkData = spkResponse.data;
        if (spkData is Map<String, dynamic> && spkData['data'] is List) {
          final spkList = spkData['data'] as List;
          activeSpkCount = spkList.where((item) {
            if (item is Map<String, dynamic>) {
              final s = item['status']?.toString();
              return s == 'DITUGASKAN' || s == 'DITERIMA';
            }
            return false;
          }).length;
        }
      } catch (_) {
        // Abaikan jika error jaringan
      }
    }

    // Sort activities by timestamp descending if available
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return DashboardSummaryModel(
      prCount: prCount,
      amprahCount: amprahCount,
      totalPendingApproval: prCount + amprahCount,
      activeSpkCount: activeSpkCount,
      recentActivities: activities,
    );
  }
}
