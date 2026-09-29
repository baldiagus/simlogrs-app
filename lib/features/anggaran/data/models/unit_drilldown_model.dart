class SppbAnggaranItemModel {
  final int id;
  final String kode;
  final String tanggalKirim;
  final String gudangNama;
  final String status;
  final int totalItem;
  final double totalNilai;

  const SppbAnggaranItemModel({
    required this.id,
    required this.kode,
    required this.tanggalKirim,
    required this.gudangNama,
    required this.status,
    required this.totalItem,
    required this.totalNilai,
  });

  factory SppbAnggaranItemModel.fromJson(Map<String, dynamic> json) {
    return SppbAnggaranItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode']?.toString() ?? '-',
      tanggalKirim: json['tanggal_kirim']?.toString() ?? '-',
      gudangNama: json['gudang_nama']?.toString() ?? 'Gudang Sentral',
      status: json['status']?.toString() ?? '-',
      totalItem: (json['total_item'] as num?)?.toInt() ?? 0,
      totalNilai: (json['total_nilai'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ServisAnggaranItemModel {
  final int id;
  final String spkKode;
  final String asetNama;
  final String sparepartNama;
  final int jumlah;
  final double subtotal;
  final String tanggal;

  const ServisAnggaranItemModel({
    required this.id,
    required this.spkKode,
    required this.asetNama,
    required this.sparepartNama,
    required this.jumlah,
    required this.subtotal,
    required this.tanggal,
  });

  factory ServisAnggaranItemModel.fromJson(Map<String, dynamic> json) {
    return ServisAnggaranItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      spkKode: json['spk_kode']?.toString() ?? '-',
      asetNama: json['aset_nama']?.toString() ?? '-',
      sparepartNama: json['sparepart_nama']?.toString() ?? '-',
      jumlah: (json['jumlah'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tanggal: json['tanggal']?.toString() ?? '-',
    );
  }
}

class UnitDrilldownModel {
  final int unitId;
  final String unitKode;
  final String unitNama;
  final String tahun;
  final double bebanDistribusi;
  final double bebanSparepart;
  final double totalPengeluaran;
  final List<SppbAnggaranItemModel> riwayatSppb;
  final List<ServisAnggaranItemModel> riwayatServis;

  const UnitDrilldownModel({
    required this.unitId,
    required this.unitKode,
    required this.unitNama,
    required this.tahun,
    required this.bebanDistribusi,
    required this.bebanSparepart,
    required this.totalPengeluaran,
    required this.riwayatSppb,
    required this.riwayatServis,
  });

  factory UnitDrilldownModel.fromJson(Map<String, dynamic> json) {
    final unit = json['unit'] as Map<String, dynamic>? ?? {};
    return UnitDrilldownModel(
      unitId: (unit['id'] as num?)?.toInt() ?? 0,
      unitKode: unit['kode']?.toString() ?? '',
      unitNama: unit['nama']?.toString() ?? '',
      tahun: json['tahun']?.toString() ?? '2026',
      bebanDistribusi: (json['beban_distribusi'] as num?)?.toDouble() ?? 0.0,
      bebanSparepart: (json['beban_sparepart'] as num?)?.toDouble() ?? 0.0,
      totalPengeluaran: (json['total_pengeluaran'] as num?)?.toDouble() ?? 0.0,
      riwayatSppb: (json['riwayat_sppb'] as List<dynamic>? ?? [])
          .map((e) => SppbAnggaranItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      riwayatServis: (json['riwayat_servis'] as List<dynamic>? ?? [])
          .map((e) => ServisAnggaranItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
