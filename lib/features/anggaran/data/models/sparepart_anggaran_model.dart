/// Pagu, realisasi, sisa, dan serapan anggaran sparepart.
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

  /// Membuat [SparepartAnggaranModel] dari JSON API; field kosong diberi nilai default.
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

/// Aset dengan biaya sparepart terbesar, beserta frekuensi servisnya.
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

  /// Membuat [TopAsetAnggaranModel] dari JSON API; field kosong diberi nilai default.
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

/// Satu catatan pemakaian sparepart pada servis aset (batch, jumlah, harga, subtotal).
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

  /// Membuat [LogSparepartModel] dari JSON API; field kosong diberi nilai default.
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
