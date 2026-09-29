class ApprovalDetailItem {
  final int? barangId;
  final String namaBarang;
  final String? kodeBarang;
  final String? satuan;
  final int jumlah;

  const ApprovalDetailItem({
    this.barangId,
    required this.namaBarang,
    this.kodeBarang,
    this.satuan,
    required this.jumlah,
  });

  factory ApprovalDetailItem.fromJson(Map<String, dynamic> json) {
    return ApprovalDetailItem(
      barangId: (json['barang_id'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt(),
      namaBarang: json['barang']?.toString() ?? json['nama_barang']?.toString() ?? 'Barang',
      kodeBarang: json['kode_barang']?.toString(),
      satuan: json['satuan']?.toString() ?? 'Pcs',
      jumlah: json['jumlah'] is int
          ? json['jumlah'] as int
          : int.tryParse(json['jumlah'].toString()) ?? 0,
    );
  }
}

class ApprovalItemModel {
  final int id;
  final String tipe; // 'PR' atau 'AMPRAH'
  final String kode;
  final String? unit;
  final String? pengaju;
  final String tanggal;
  final String urgensi;
  final String? status;
  final int jumlahItem;
  final List<ApprovalDetailItem> items;

  const ApprovalItemModel({
    required this.id,
    required this.tipe,
    required this.kode,
    this.unit,
    this.pengaju,
    required this.tanggal,
    required this.urgensi,
    this.status,
    required this.jumlahItem,
    required this.items,
  });

  bool get isCito => urgensi.toUpperCase() == 'CITO' || urgensi.toUpperCase() == 'MENDESAK';

  factory ApprovalItemModel.fromJson(Map<String, dynamic> json) {
    return ApprovalItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      tipe: json['tipe']?.toString() ?? 'PR',
      kode: json['kode']?.toString() ?? '',
      unit: json['unit']?.toString(),
      pengaju: json['pengaju']?.toString(),
      tanggal: json['tanggal']?.toString() ?? '',
      urgensi: json['urgensi']?.toString() ?? 'RUTIN',
      status: json['status']?.toString(),
      jumlahItem: json['jumlah_item'] is int
          ? json['jumlah_item'] as int
          : int.tryParse(json['jumlah_item'].toString()) ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ApprovalDetailItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ApprovalPendingResponse {
  final List<ApprovalItemModel> prList;
  final List<ApprovalItemModel> amprahList;
  final int totalPr;
  final int totalAmprah;

  const ApprovalPendingResponse({
    required this.prList,
    required this.amprahList,
    required this.totalPr,
    required this.totalAmprah,
  });


  factory ApprovalPendingResponse.fromJson(Map<String, dynamic> json) {
    final prRaw = json['permintaan_pengadaan'] as List<dynamic>? ??
        json['pr'] as List<dynamic>? ??
        [];
    final amprahRaw = json['permintaan_distribusi'] as List<dynamic>? ??
        json['amprah'] as List<dynamic>? ??
        [];

    final prList = prRaw
        .map((e) => ApprovalItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final amprahList = amprahRaw
        .map((e) => ApprovalItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ApprovalPendingResponse(
      prList: prList,
      amprahList: amprahList,
      totalPr: json['total_pr'] is int ? json['total_pr'] as int : prList.length,
      totalAmprah: json['total_amprah'] is int
          ? json['total_amprah'] as int
          : amprahList.length,
    );
  }
}
