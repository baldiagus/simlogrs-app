/// Satu item barang pada penyesuaian stok (jumlah, jenis LEBIH/KURANG, subtotal nilai).
class PenyesuaianStokItemAuditModel {
  final String namaBarang;
  final String satuan;
  final int jumlah;
  final String jenis;
  final double subtotal;

  const PenyesuaianStokItemAuditModel({
    required this.namaBarang,
    required this.satuan,
    required this.jumlah,
    required this.jenis,
    required this.subtotal,
  });

  /// Membangun item penyesuaian stok dari JSON; jenis default KURANG.
  factory PenyesuaianStokItemAuditModel.fromJson(Map<String, dynamic> json) {
    return PenyesuaianStokItemAuditModel(
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      jumlah: (json['jumlah'] as num?)?.toInt() ?? 0,
      jenis: json['jenis']?.toString() ?? 'KURANG',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Pengajuan penyesuaian stok yang ditinjau auditor (gudang, pengaju, penyetuju, total nilai).
class PenyesuaianStokAuditModel {
  final int id;
  final String kode;
  final String gudang;
  final String status;
  final String? alasan;
  final String pengaju;
  final String penyetuju;
  final String tanggalPengajuan;
  final int totalItem;
  final double totalNilai;
  final List<PenyesuaianStokItemAuditModel> items;

  const PenyesuaianStokAuditModel({
    required this.id,
    required this.kode,
    required this.gudang,
    required this.status,
    this.alasan,
    required this.pengaju,
    required this.penyetuju,
    required this.tanggalPengajuan,
    required this.totalItem,
    required this.totalNilai,
    required this.items,
  });

  /// Membangun pengajuan penyesuaian stok beserta itemnya dari JSON.
  factory PenyesuaianStokAuditModel.fromJson(Map<String, dynamic> json) {
    return PenyesuaianStokAuditModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode']?.toString() ?? '-',
      gudang: json['gudang']?.toString() ?? 'Gudang',
      status: json['status']?.toString() ?? 'MENUNGGU',
      alasan: json['alasan']?.toString(),
      pengaju: json['pengaju']?.toString() ?? 'Petugas',
      penyetuju: json['penyetuju']?.toString() ?? '-',
      tanggalPengajuan: json['tanggal_pengajuan']?.toString() ?? '-',
      totalItem: (json['total_item'] as num?)?.toInt() ?? 0,
      totalNilai: (json['total_nilai'] as num?)?.toDouble() ?? 0.0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PenyesuaianStokItemAuditModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
