class ActivityItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String timestamp;
  final String status;
  final String type; // 'pr', 'amprah', 'spk'

  const ActivityItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.status,
    required this.type,
  });

  factory ActivityItemModel.fromPr(Map<String, dynamic> json) {
    return ActivityItemModel(
      id: json['id']?.toString() ?? '',
      title: json['nomor_pr']?.toString() ?? 'Permintaan Pengadaan',
      subtitle: json['nama_unit']?.toString() ?? 'Unit Pemohon',
      timestamp: json['tanggal_pengajuan']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DIAJUKAN',
      type: 'pr',
    );
  }

  factory ActivityItemModel.fromAmprah(Map<String, dynamic> json) {
    return ActivityItemModel(
      id: json['id']?.toString() ?? '',
      title: json['nomor_permintaan']?.toString() ?? 'Amprah Ruangan',
      subtitle: json['nama_unit']?.toString() ?? 'Unit Pemohon',
      timestamp: json['tanggal_permintaan']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DIAJUKAN',
      type: 'amprah',
    );
  }
}

class DashboardSummaryModel {
  final int prCount;
  final int amprahCount;
  final int totalPendingApproval;
  final int activeSpkCount;
  final List<ActivityItemModel> recentActivities;

  const DashboardSummaryModel({
    required this.prCount,
    required this.amprahCount,
    required this.totalPendingApproval,
    required this.activeSpkCount,
    required this.recentActivities,
  });

  factory DashboardSummaryModel.empty() {
    return const DashboardSummaryModel(
      prCount: 0,
      amprahCount: 0,
      totalPendingApproval: 0,
      activeSpkCount: 0,
      recentActivities: [],
    );
  }
}
