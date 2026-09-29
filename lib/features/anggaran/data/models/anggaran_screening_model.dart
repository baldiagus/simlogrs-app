import 'anggaran_ringkasan_model.dart';
import 'sparepart_anggaran_model.dart';
import 'unit_anggaran_model.dart';

class AnggaranScreeningModel {
  final String tahun;
  final AnggaranRingkasanModel ringkasan;
  final List<UnitAnggaranModel> unitAnggarans;
  final SparepartAnggaranModel? sparepartAnggaran;
  final List<TopAsetAnggaranModel> topAset;
  final List<LogSparepartModel> riwayatSparepart;

  const AnggaranScreeningModel({
    required this.tahun,
    required this.ringkasan,
    required this.unitAnggarans,
    this.sparepartAnggaran,
    required this.topAset,
    required this.riwayatSparepart,
  });

  factory AnggaranScreeningModel.fromJson(Map<String, dynamic> json) {
    return AnggaranScreeningModel(
      tahun: json['tahun']?.toString() ?? '2026',
      ringkasan: AnggaranRingkasanModel.fromJson(
          json['ringkasan'] as Map<String, dynamic>? ?? {}),
      unitAnggarans: (json['unit_anggarans'] as List<dynamic>? ?? [])
          .map((e) => UnitAnggaranModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      sparepartAnggaran: json['sparepart_anggaran'] != null
          ? SparepartAnggaranModel.fromJson(
              json['sparepart_anggaran'] as Map<String, dynamic>)
          : null,
      topAset: (json['top_aset'] as List<dynamic>? ?? [])
          .map((e) => TopAsetAnggaranModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      riwayatSparepart: (json['riwayat_sparepart'] as List<dynamic>? ?? [])
          .map((e) => LogSparepartModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
