/// Data satu pengalihan aset/barang: asal, tujuan, status, jumlah, pihak terkait, dan hak aksi user.
class PengalihanItemModel {
  final int id;
  final String kode;
  final String tipe; // 'ASET' atau 'BARANG'
  final String tipeAsal; // 'RUANGAN' atau 'GUDANG'
  final String asalNama;
  final String tipeTujuan; // 'RUANGAN' atau 'GUDANG'
  final String tujuanNama;
  final int? unitAsalId;
  final int? gudangAsalId;
  final int? unitTujuanId;
  final int? gudangTujuanId;
  final String status;
  final String tanggalPengalihan;
  final String namaItem;
  final int jumlah;
  final String? alasan;
  final String? catatan;
  final String? pengaju;
  final String? penyetuju;
  final String? penerima;
  final bool canCancel;
  final bool canApprove;
  final bool canReceive;
  final List<PengalihanDetailItem> items;
  /// Membuat model pengalihan; flag [canCancel], [canApprove], [canReceive] menentukan aksi yang tersedia bagi user.
  const PengalihanItemModel({
    required this.id,
    required this.kode,
    required this.tipe,
    required this.tipeAsal,
    required this.asalNama,
    required this.tipeTujuan,
    required this.tujuanNama,
    this.unitAsalId,
    this.gudangAsalId,
    this.unitTujuanId,
    this.gudangTujuanId,
    required this.status,
    required this.tanggalPengalihan,
    required this.namaItem,
    required this.jumlah,
    this.alasan,
    this.catatan,
    this.pengaju,
    this.penyetuju,
    this.penerima,
    this.canCancel = false,
    this.canApprove = false,
    this.canReceive = false,
    this.items = const [],
  });

  /// True bila status pengalihan DIAJUKAN (menunggu otorisasi).
  bool get isDiajukan => status.toUpperCase() == 'DIAJUKAN';
  /// True bila status pengalihan DISETUJUI (menunggu serah terima).
  bool get isDisetujui => status.toUpperCase() == 'DISETUJUI';
  /// True bila status pengalihan SELESAI.
  bool get isSelesai => status.toUpperCase() == 'SELESAI';
  /// True bila status pengalihan DITOLAK.
  bool get isDitolak => status.toUpperCase() == 'DITOLAK';
  /// True bila status pengalihan DIBATALKAN.
  bool get isDibatalkan => status.toUpperCase() == 'DIBATALKAN';

  /// Membuat [PengalihanItemModel] dari JSON API; nama asal/tujuan/item diambil dari beberapa kemungkinan key dengan fallback.
  factory PengalihanItemModel.fromJson(Map<String, dynamic> json) {
    return PengalihanItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      tipe: json['tipe']?.toString() ?? 'ASET',
      tipeAsal: json['tipe_asal']?.toString() ?? 'RUANGAN',
      asalNama: json['asal_nama']?.toString() ?? json['unit_asal']?['nama']?.toString() ?? json['gudang_asal']?['nama']?.toString() ?? '-',
      tipeTujuan: json['tipe_tujuan']?.toString() ?? 'RUANGAN',
      tujuanNama: json['tujuan_nama']?.toString() ?? json['unit_tujuan']?['nama']?.toString() ?? json['gudang_tujuan']?['nama']?.toString() ?? '-',
      unitAsalId: (json['unit_asal_id'] as num?)?.toInt(),
      gudangAsalId: (json['gudang_asal_id'] as num?)?.toInt(),
      unitTujuanId: (json['unit_tujuan_id'] as num?)?.toInt(),
      gudangTujuanId: (json['gudang_tujuan_id'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'DIAJUKAN',
      tanggalPengalihan: json['tanggal_pengalihan']?.toString() ?? '',
      namaItem: json['nama_item']?.toString() ?? json['aset']?['nama']?.toString() ?? json['barang']?['nama']?.toString() ?? '-',
      jumlah: json['jumlah'] is int
          ? json['jumlah'] as int
          : (int.tryParse(json['jumlah']?.toString() ?? '') ?? 1),
      alasan: json['alasan']?.toString(),
      catatan: json['catatan']?.toString(),
      pengaju: json['pengaju']?.toString(),
      penyetuju: json['penyetuju']?.toString(),
      penerima: json['penerima']?.toString(),
      canCancel: json['can_cancel'] == true,
      canApprove: json['can_approve'] == true,
      canReceive: json['can_receive'] == true,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => PengalihanDetailItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
    );
  }
}

/// Rincian satu aset atau barang di dalam sebuah pengalihan.
class PengalihanDetailItem {
  final int id;
  final String kodeAset;
  final String? nomorSeri;
  final String? namaBarang;
  final int? jumlah;

  /// Membuat detail item pengalihan; nomor seri, nama barang, dan jumlah opsional.
  const PengalihanDetailItem({
    required this.id,
    required this.kodeAset,
    this.nomorSeri,
    this.namaBarang,
    this.jumlah,
  });

  /// Membuat [PengalihanDetailItem] dari JSON API dengan fallback antar key id/kode.
  factory PengalihanDetailItem.fromJson(Map<String, dynamic> json) {
    return PengalihanDetailItem(
      id: (json['aset_id'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      kodeAset: json['kode_aset']?.toString() ?? json['kode']?.toString() ?? '-',
      nomorSeri: json['nomor_seri']?.toString(),
      namaBarang: json['nama_barang']?.toString(),
      jumlah: (json['jumlah'] as num?)?.toInt(),
    );
  }
}
