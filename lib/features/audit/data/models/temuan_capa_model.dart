/// Temuan audit SPI beserta tindak lanjut CAPA (corrective and preventive action).
class TemuanCapaModel {
  final int id;
  final String kode;
  final String tanggalAudit;
  final String objekAudit;
  final String ringkasan;
  final String tingkatRisiko;
  final String dueDateCapa;
  final String statusCapa;
  final bool isOverdue;
  final String auditor;
  final String evaluator;
  final String unit;
  final String? gudang;
  final String? analisisPenyebab;
  final String? tindakanPerbaikan;
  final String? catatanEvaluasi;
  final List<String> buktiPerbaikan;

  const TemuanCapaModel({
    required this.id,
    required this.kode,
    required this.tanggalAudit,
    required this.objekAudit,
    required this.ringkasan,
    required this.tingkatRisiko,
    required this.dueDateCapa,
    required this.statusCapa,
    required this.isOverdue,
    required this.auditor,
    required this.evaluator,
    required this.unit,
    this.gudang,
    this.analisisPenyebab,
    this.tindakanPerbaikan,
    this.catatanEvaluasi,
    required this.buktiPerbaikan,
  });

  /// Membangun temuan audit beserta status CAPA dari JSON dengan default untuk field kosong.
  factory TemuanCapaModel.fromJson(Map<String, dynamic> json) {
    return TemuanCapaModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode']?.toString() ?? '-',
      tanggalAudit: json['tanggal_audit']?.toString() ?? '-',
      objekAudit: json['objek_audit']?.toString() ?? '-',
      ringkasan: json['ringkasan']?.toString() ?? '-',
      tingkatRisiko: json['tingkat_risiko']?.toString() ?? 'Moderat',
      dueDateCapa: json['due_date_capa']?.toString() ?? '-',
      statusCapa: json['status_capa']?.toString() ?? 'In Progress',
      isOverdue: json['is_overdue'] == true,
      auditor: json['auditor']?.toString() ?? 'Auditor SPI',
      evaluator: json['evaluator']?.toString() ?? '-',
      unit: json['unit']?.toString() ?? 'Sentral',
      gudang: json['gudang']?.toString(),
      analisisPenyebab: json['analisis_penyebab']?.toString(),
      tindakanPerbaikan: json['tindakan_perbaikan']?.toString(),
      catatanEvaluasi: json['catatan_evaluasi']?.toString(),
      buktiPerbaikan:
          (json['bukti_perbaikan'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
