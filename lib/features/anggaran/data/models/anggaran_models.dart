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
      totalRealisasiDistribusi: (json['total_realisasi_distribusi'] as num?)?.toDouble() ?? 0.0,
      totalRealisasiSparepart: (json['total_realisasi_sparepart'] as num?)?.toDouble() ?? 0.0,
      totalRealisasiGlobal: (json['total_realisasi_global'] as num?)?.toDouble() ?? 0.0,
      totalSisaGlobal: (json['total_sisa_global'] as num?)?.toDouble() ?? 0.0,
      serapanGlobalPersen: (json['serapan_global_persen'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

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

class SparepartAnggaranModel {
  final int id;
  final String kode;
  final String posAnggaran;
  final double pagu;
  final double realisasi;
  final double sisa;
  final double serapan;
  final String status;

  const SparepartAnggaranModel({
    required this.id,
    required this.kode,
    required this.posAnggaran,
    required this.pagu,
    required this.realisasi,
    required this.sisa,
    required this.serapan,
    required this.status,
  });

  factory SparepartAnggaranModel.fromJson(Map<String, dynamic> json) {
    return SparepartAnggaranModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode']?.toString() ?? '',
      posAnggaran: json['pos_anggaran']?.toString() ?? '',
      pagu: (json['pagu'] as num?)?.toDouble() ?? 0.0,
      realisasi: (json['realisasi'] as num?)?.toDouble() ?? 0.0,
      sisa: (json['sisa'] as num?)?.toDouble() ?? 0.0,
      serapan: (json['serapan'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'Normal',
    );
  }
}

class TopAsetAnggaranModel {
  final int id;
  final String kodeAset;
  final String nama;
  final String lokasiRuangan;
  final int frekuensiServis;
  final double totalBiayaSparepart;

  const TopAsetAnggaranModel({
    required this.id,
    required this.kodeAset,
    required this.nama,
    required this.lokasiRuangan,
    required this.frekuensiServis,
    required this.totalBiayaSparepart,
  });

  factory TopAsetAnggaranModel.fromJson(Map<String, dynamic> json) {
    return TopAsetAnggaranModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kodeAset: json['kode_aset']?.toString() ?? '-',
      nama: json['nama']?.toString() ?? '-',
      lokasiRuangan: json['lokasi_ruangan']?.toString() ?? 'Sentral',
      frekuensiServis: (json['frekuensi_servis'] as num?)?.toInt() ?? 0,
      totalBiayaSparepart: (json['total_biaya_sparepart'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LogSparepartModel {
  final int id;
  final String spkKode;
  final String asetNama;
  final String sparepartNama;
  final String nomorBatch;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal;
  final String tanggal;

  const LogSparepartModel({
    required this.id,
    required this.spkKode,
    required this.asetNama,
    required this.sparepartNama,
    required this.nomorBatch,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    required this.tanggal,
  });

  factory LogSparepartModel.fromJson(Map<String, dynamic> json) {
    return LogSparepartModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      spkKode: json['spk_kode']?.toString() ?? '-',
      asetNama: json['aset_nama']?.toString() ?? '-',
      sparepartNama: json['sparepart_nama']?.toString() ?? '-',
      nomorBatch: json['nomor_batch']?.toString() ?? '-',
      jumlah: (json['jumlah'] as num?)?.toInt() ?? 0,
      hargaSatuan: (json['harga_satuan'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tanggal: json['tanggal']?.toString() ?? '-',
    );
  }
}

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
      ringkasan: AnggaranRingkasanModel.fromJson(json['ringkasan'] as Map<String, dynamic>? ?? {}),
      unitAnggarans: (json['unit_anggarans'] as List<dynamic>? ?? [])
          .map((e) => UnitAnggaranModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      sparepartAnggaran: json['sparepart_anggaran'] != null
          ? SparepartAnggaranModel.fromJson(json['sparepart_anggaran'] as Map<String, dynamic>)
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
