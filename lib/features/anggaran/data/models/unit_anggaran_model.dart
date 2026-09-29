class UnitAnggaranModel {
  final int id;
  final String kode;
  final String posAnggaran;
  final int? unitId;
  final String unitNama;
  final String unitKode;
  final double pagu;
  final double realisasi;
  final double sisa;
  final double serapan;
  final String status;
  final double bebanDistribusi;
  final double bebanSparepart;

  const UnitAnggaranModel({
    required this.id,
    required this.kode,
    required this.posAnggaran,
    this.unitId,
    required this.unitNama,
    required this.unitKode,
    required this.pagu,
    required this.realisasi,
    required this.sisa,
    required this.serapan,
    required this.status,
    required this.bebanDistribusi,
    required this.bebanSparepart,
  });

  factory UnitAnggaranModel.fromJson(Map<String, dynamic> json) {
    return UnitAnggaranModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode']?.toString() ?? '',
      posAnggaran: json['pos_anggaran']?.toString() ?? '',
      unitId: (json['unit_id'] as num?)?.toInt(),
      unitNama: json['unit_nama']?.toString() ?? '',
      unitKode: json['unit_kode']?.toString() ?? '',
      pagu: (json['pagu'] as num?)?.toDouble() ?? 0.0,
      realisasi: (json['realisasi'] as num?)?.toDouble() ?? 0.0,
      sisa: (json['sisa'] as num?)?.toDouble() ?? 0.0,
      serapan: (json['serapan'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'Normal',
      bebanDistribusi: (json['beban_distribusi'] as num?)?.toDouble() ?? 0.0,
      bebanSparepart: (json['beban_sparepart'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
