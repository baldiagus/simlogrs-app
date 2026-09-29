class AnggaranRingkasanModel {
  final double totalPagu;
  final double totalRealisasiDistribusi;
  final double totalRealisasiSparepart;
  final double totalRealisasiGlobal;
  final double totalSisaGlobal;
  final double serapanGlobalPersen;

  const AnggaranRingkasanModel({
    required this.totalPagu,
    required this.totalRealisasiDistribusi,
    required this.totalRealisasiSparepart,
    required this.totalRealisasiGlobal,
    required this.totalSisaGlobal,
    required this.serapanGlobalPersen,
  });

  factory AnggaranRingkasanModel.fromJson(Map<String, dynamic> json) {
    return AnggaranRingkasanModel(
      totalPagu: (json['total_pagu'] as num?)?.toDouble() ?? 0.0,
      totalRealisasiDistribusi:
          (json['total_realisasi_distribusi'] as num?)?.toDouble() ?? 0.0,
      totalRealisasiSparepart:
          (json['total_realisasi_sparepart'] as num?)?.toDouble() ?? 0.0,
      totalRealisasiGlobal:
          (json['total_realisasi_global'] as num?)?.toDouble() ?? 0.0,
      totalSisaGlobal: (json['total_sisa_global'] as num?)?.toDouble() ?? 0.0,
      serapanGlobalPersen:
          (json['serapan_global_persen'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
