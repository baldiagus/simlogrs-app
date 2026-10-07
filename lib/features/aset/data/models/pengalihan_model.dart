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
  });

  bool get isDiajukan => status.toUpperCase() == 'DIAJUKAN';
  bool get isDisetujui => status.toUpperCase() == 'DISETUJUI';
  bool get isSelesai => status.toUpperCase() == 'SELESAI';
  bool get isDitolak => status.toUpperCase() == 'DITOLAK';
  bool get isDibatalkan => status.toUpperCase() == 'DIBATALKAN';

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
    );
  }
}
