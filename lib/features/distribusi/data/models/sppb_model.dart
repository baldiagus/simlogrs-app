class SppbDetailItemModel {
  final int barangId;
  final String namaBarang;
  final String kodeBarang;
  final String satuan;
  final int jumlahDikirim;
  final String nomorBatch;

  const SppbDetailItemModel({
    required this.barangId,
    required this.namaBarang,
    required this.kodeBarang,
    required this.satuan,
    required this.jumlahDikirim,
    required this.nomorBatch,
  });

  factory SppbDetailItemModel.fromJson(Map<String, dynamic> json) {
    return SppbDetailItemModel(
      barangId: json['barang_id'] is int
          ? json['barang_id'] as int
          : int.parse(json['barang_id'].toString()),
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      kodeBarang: json['kode_barang']?.toString() ?? '-',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      jumlahDikirim: json['jumlah_dikirim'] is int
          ? json['jumlah_dikirim'] as int
          : int.tryParse(json['jumlah_dikirim']?.toString() ?? '') ?? 0,
      nomorBatch: json['nomor_batch']?.toString() ?? '-',
    );
  }
}

class SppbHeaderModel {
  final int id;
  final String kode;
  final String gudang;
  final String unit;
  final String pengirim;
  final String? tanggalKirim;
  final String status;
  final String? catatan;
  final int totalItem;
  final List<SppbDetailItemModel> items;

  const SppbHeaderModel({
    required this.id,
    required this.kode,
    required this.gudang,
    required this.unit,
    required this.pengirim,
    this.tanggalKirim,
    required this.status,
    this.catatan,
    required this.totalItem,
    required this.items,
  });

  bool get isDikirim => status.toUpperCase() == 'DIKIRIM';
  bool get isSelesai => status.toUpperCase() == 'SELESAI';

  factory SppbHeaderModel.fromJson(Map<String, dynamic> json) {
    return SppbHeaderModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      gudang: json['gudang']?.toString() ?? 'Gudang Sentral',
      unit: json['unit']?.toString() ?? '-',
      pengirim: json['pengirim']?.toString() ?? 'Petugas Gudang',
      tanggalKirim: json['tanggal_kirim']?.toString(),
      status: json['status']?.toString() ?? 'DIKIRIM',
      catatan: json['catatan']?.toString(),
      totalItem: json['total_item'] is int
          ? json['total_item'] as int
          : int.tryParse(json['total_item']?.toString() ?? '') ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => SppbDetailItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PickingAntreanModel {
  final int id;
  final String kode;
  final String unit;
  final String pengaju;
  final String? tanggalPermintaan;
  final String urgensi;
  final String status;
  final int totalItem;
  final List<Map<String, dynamic>> items;

  const PickingAntreanModel({
    required this.id,
    required this.kode,
    required this.unit,
    required this.pengaju,
    this.tanggalPermintaan,
    required this.urgensi,
    required this.status,
    required this.totalItem,
    required this.items,
  });

  bool get isCito => urgensi.toUpperCase() == 'CITO';

  factory PickingAntreanModel.fromJson(Map<String, dynamic> json) {
    return PickingAntreanModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'Unit Ruangan',
      pengaju: json['pengaju']?.toString() ?? 'Staf',
      tanggalPermintaan: json['tanggal_permintaan']?.toString(),
      urgensi: json['urgensi']?.toString() ?? 'REGULER',
      status: json['status']?.toString() ?? 'DISETUJUI_GUDANG',
      totalItem: json['total_item'] is int
          ? json['total_item'] as int
          : int.tryParse(json['total_item']?.toString() ?? '') ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}
