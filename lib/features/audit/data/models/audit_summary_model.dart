class AuditSummaryModel {
  final int totalTemuan;
  final int totalClosed;
  final int totalInProgress;
  final int totalInReview;
  final int mayorOpen;
  final int overdue;
  final double closingRate;

  final int poTanpaPr;
  final int poTerlambat;
  final int poSelisihRcv;
  final int totalPoAnomali;

  final int sesiOpnameSelisih;
  final int penyesuaianMenunggu;
  final int totalLogAudit;

  const AuditSummaryModel({
    required this.totalTemuan,
    required this.totalClosed,
    required this.totalInProgress,
    required this.totalInReview,
    required this.mayorOpen,
    required this.overdue,
    required this.closingRate,
    required this.poTanpaPr,
    required this.poTerlambat,
    required this.poSelisihRcv,
    required this.totalPoAnomali,
    required this.sesiOpnameSelisih,
    required this.penyesuaianMenunggu,
    required this.totalLogAudit,
  });

  factory AuditSummaryModel.fromJson(Map<String, dynamic> json) {
    final capa = (json['capa'] as Map<String, dynamic>?) ?? {};
    final kepatuhan = (json['kepatuhan_po'] as Map<String, dynamic>?) ?? {};
    final opname = (json['selisih_opname'] as Map<String, dynamic>?) ?? {};

    return AuditSummaryModel(
      totalTemuan: (capa['total_temuan'] as num?)?.toInt() ?? 0,
      totalClosed: (capa['total_closed'] as num?)?.toInt() ?? 0,
      totalInProgress: (capa['total_in_progress'] as num?)?.toInt() ?? 0,
      totalInReview: (capa['total_in_review'] as num?)?.toInt() ?? 0,
      mayorOpen: (capa['mayor_open'] as num?)?.toInt() ?? 0,
      overdue: (capa['overdue'] as num?)?.toInt() ?? 0,
      closingRate: (capa['closing_rate'] as num?)?.toDouble() ?? 100.0,
      poTanpaPr: (kepatuhan['tanpa_pr'] as num?)?.toInt() ?? 0,
      poTerlambat: (kepatuhan['terlambat'] as num?)?.toInt() ?? 0,
      poSelisihRcv: (kepatuhan['selisih_rcv'] as num?)?.toInt() ?? 0,
      totalPoAnomali: (kepatuhan['total_anomali'] as num?)?.toInt() ?? 0,
      sesiOpnameSelisih: (opname['sesi_berselisih'] as num?)?.toInt() ?? 0,
      penyesuaianMenunggu: (opname['penyesuaian_menunggu'] as num?)?.toInt() ?? 0,
      totalLogAudit: (json['total_log_audit'] as num?)?.toInt() ?? 0,
    );
  }
}
