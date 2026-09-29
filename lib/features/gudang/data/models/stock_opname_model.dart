class StokOpnameDetailItemModel {
  final int id;
  final int stokBatchId;
  final int barangId;
  final String kodeBarang;
  final String namaBarang;
  final String satuan;
  final String nomorBatch;
  final String lokasiRak;
  final int jumlahSistem;
  int? jumlahFisik;
  int selisih;
  String catatan;

  StokOpnameDetailItemModel({
    required this.id,
    required this.stokBatchId,
    required this.barangId,
    required this.kodeBarang,
    required this.namaBarang,
    required this.satuan,
    required this.nomorBatch,
    required this.lokasiRak,
    required this.jumlahSistem,
    this.jumlahFisik,
    required this.selisih,
    this.catatan = '',
  });

  bool get isSudahHitung => jumlahFisik != null;

  factory StokOpnameDetailItemModel.fromJson(Map<String, dynamic> json) {
    return StokOpnameDetailItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      stokBatchId: json['stok_batch_id'] is int ? json['stok_batch_id'] as int : int.parse(json['stok_batch_id'].toString()),
      barangId: json['barang_id'] is int ? json['barang_id'] as int : int.parse(json['barang_id'].toString()),
      kodeBarang: json['kode_barang']?.toString() ?? '-',
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      nomorBatch: json['nomor_batch']?.toString() ?? '-',
      lokasiRak: json['lokasi_rak']?.toString() ?? 'Tanpa Rak',
      jumlahSistem: int.tryParse(json['jumlah_sistem']?.toString() ?? '0') ?? 0,
      jumlahFisik: json['jumlah_fisik'] != null ? int.tryParse(json['jumlah_fisik'].toString()) : null,
      selisih: int.tryParse(json['selisih']?.toString() ?? '0') ?? 0,
      catatan: json['catatan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toCountJson() => {
    'detail_id': id,
    'jumlah_fisik': jumlahFisik ?? 0,
    'catatan': catatan,
  };
}

class StokOpnameSesiModel {
  final int id;
  final String kode;
  final int gudangId;
  final String gudangNama;
  final String tanggalOpname;
  final String status; // 'BERJALAN', 'PROSES_COUNT', 'MENUNGGU_APPROVAL', 'DISETUJUI', 'DIBATALKAN'
  final String catatan;
  final String petugasInisiasi;
  final int totalItem;
  final int totalTerhitung;
  final int totalSelisih;
  final List<StokOpnameDetailItemModel> details;

  const StokOpnameSesiModel({
    required this.id,
    required this.kode,
    required this.gudangId,
    required this.gudangNama,
    required this.tanggalOpname,
    required this.status,
    required this.catatan,
    required this.petugasInisiasi,
    required this.totalItem,
    required this.totalTerhitung,
    required this.totalSelisih,
    required this.details,
  });

  bool get isBerjalan => status == 'BERJALAN' || status == 'PROSES_COUNT';
  bool get isDisetujui => status == 'DISETUJUI';

  factory StokOpnameSesiModel.fromJson(Map<String, dynamic> json) {
    final list = (json['details'] as List<dynamic>?)
            ?.map((e) => StokOpnameDetailItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return StokOpnameSesiModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      gudangId: json['gudang_id'] is int ? json['gudang_id'] as int : int.parse(json['gudang_id'].toString()),
      gudangNama: json['gudang_nama']?.toString() ?? 'Gudang',
      tanggalOpname: json['tanggal_opname']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'BERJALAN',
      catatan: json['catatan']?.toString() ?? '-',
      petugasInisiasi: json['petugas_inisiasi']?.toString() ?? 'Petugas Gudang',
      totalItem: int.tryParse(json['total_item']?.toString() ?? '0') ?? 0,
      totalTerhitung: int.tryParse(json['total_terhitung']?.toString() ?? '0') ?? 0,
      totalSelisih: int.tryParse(json['total_selisih']?.toString() ?? '0') ?? 0,
      details: list,
    );
  }
}
