/// Detail selisih satu batch barang pada sesi opname (jumlah sistem vs fisik, nilai selisih).
class SelisihOpnameDetailModel {
  final int id;
  final String namaBarang;
  final String kodeBarang;
  final String satuan;
  final String nomorBatch;
  final int jumlahSistem;
  final int jumlahFisik;
  final int selisih;
  final String jenis;
  final double hargaSatuan;
  final double nilaiSelisih;
  final String catatan;

  const SelisihOpnameDetailModel({
    required this.id,
    required this.namaBarang,
    required this.kodeBarang,
    required this.satuan,
    required this.nomorBatch,
    required this.jumlahSistem,
    required this.jumlahFisik,
    required this.selisih,
    required this.jenis,
    required this.hargaSatuan,
    required this.nilaiSelisih,
    required this.catatan,
  });

  /// Membangun detail selisih per batch dari JSON; jenis diturunkan dari tanda selisih bila kosong.
  factory SelisihOpnameDetailModel.fromJson(Map<String, dynamic> json) {
    return SelisihOpnameDetailModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      kodeBarang: json['kode_barang']?.toString() ?? '-',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      nomorBatch: json['nomor_batch']?.toString() ?? '-',
      jumlahSistem: (json['jumlah_sistem'] as num?)?.toInt() ?? 0,
      jumlahFisik: (json['jumlah_fisik'] as num?)?.toInt() ?? 0,
      selisih: (json['selisih'] as num?)?.toInt() ?? 0,
      jenis: json['jenis']?.toString() ??
          ((((json['selisih'] as num?)?.toInt() ?? 0) > 0) ? 'LEBIH' : 'KURANG'),
      hargaSatuan: (json['harga_satuan'] as num?)?.toDouble() ?? 0.0,
      nilaiSelisih: (json['nilai_selisih'] as num?)?.toDouble() ?? 0.0,
      catatan: json['catatan']?.toString() ?? '-',
    );
  }
}

/// Sesi stok opname yang memiliki selisih antara stok sistem dan fisik.
class SesiOpnameSelisihModel {
  final int id;
  final String kode;
  final String gudang;
  final String petugas;
  final String tanggalOpname;
  final String status;
  final int totalBatchSelisih;
  final double totalNilaiSelisih;
  final List<SelisihOpnameDetailModel> details;

  const SesiOpnameSelisihModel({
    required this.id,
    required this.kode,
    required this.gudang,
    required this.petugas,
    required this.tanggalOpname,
    required this.status,
    required this.totalBatchSelisih,
    required this.totalNilaiSelisih,
    required this.details,
  });

  /// Membangun sesi opname berselisih beserta daftar detail batch dari JSON.
  factory SesiOpnameSelisihModel.fromJson(Map<String, dynamic> json) {
    return SesiOpnameSelisihModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode']?.toString() ?? '-',
      gudang: json['gudang']?.toString() ?? 'Gudang',
      petugas: json['petugas']?.toString() ?? 'Petugas',
      tanggalOpname: json['tanggal_opname']?.toString() ?? '-',
      status: json['status']?.toString() ?? '-',
      totalBatchSelisih: (json['total_batch_selisih'] as num?)?.toInt() ?? 0,
      totalNilaiSelisih: (json['total_nilai_selisih'] as num?)?.toDouble() ?? 0.0,
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => SelisihOpnameDetailModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
