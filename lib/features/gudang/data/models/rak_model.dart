class RakModel {
  final int id;
  final String kode;
  final String nama;
  final String? baris;
  final String? kolom;
  final String? level;
  final String status;
  final int? gudangId;
  final String namaGudang;
  final int totalBarang;
  final int totalAset;

  const RakModel({
    required this.id,
    required this.kode,
    required this.nama,
    this.baris,
    this.kolom,
    this.level,
    required this.status,
    this.gudangId,
    required this.namaGudang,
    required this.totalBarang,
    required this.totalAset,
  });

  factory RakModel.fromJson(Map<String, dynamic> json) {
    return RakModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      baris: json['baris']?.toString(),
      kolom: json['kolom']?.toString(),
      level: json['level']?.toString(),
      status: json['status']?.toString() ?? 'AKTIF',
      gudangId: json['gudang_id'] is int
          ? json['gudang_id'] as int
          : int.tryParse(json['gudang_id']?.toString() ?? ''),
      namaGudang: json['nama_gudang']?.toString() ?? '-',
      totalBarang: json['total_barang'] is int
          ? json['total_barang'] as int
          : int.tryParse(json['total_barang']?.toString() ?? '') ?? 0,
      totalAset: json['total_aset'] is int
          ? json['total_aset'] as int
          : int.tryParse(json['total_aset']?.toString() ?? '') ?? 0,
    );
  }
}
