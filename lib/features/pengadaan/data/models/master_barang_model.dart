class MasterBarangModel {
  final int id;
  final String kode;
  final String nama;
  final String? spesifikasi;
  final String tipe;
  final String tipeLabel;
  final String kategori;
  final String satuan;
  final String merek;
  final double hargaEstimasi;
  final int stok;

  const MasterBarangModel({
    required this.id,
    required this.kode,
    required this.nama,
    this.spesifikasi,
    this.tipe = 'HABIS_PAKAI',
    this.tipeLabel = 'Habis Pakai (ATK/ART)',
    required this.kategori,
    required this.satuan,
    required this.merek,
    required this.hargaEstimasi,
    this.stok = 0,
  });

  factory MasterBarangModel.fromJson(Map<String, dynamic> json) {
    return MasterBarangModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      spesifikasi: json['spesifikasi']?.toString(),
      tipe: json['tipe']?.toString() ?? 'HABIS_PAKAI',
      tipeLabel: json['tipe_label']?.toString() ??
          (json['tipe'] == 'ASET'
              ? 'Aktiva / Aset Inventaris'
              : (json['tipe'] == 'SPAREPART'
                  ? 'Suku Cadang IPSRS'
                  : 'Habis Pakai (ATK/ART)')),
      kategori: json['kategori']?.toString() ?? 'Umum',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      merek: json['merek']?.toString() ?? '-',
      hargaEstimasi: json['harga_estimasi'] is num
          ? (json['harga_estimasi'] as num).toDouble()
          : double.tryParse(json['harga_estimasi'].toString()) ?? 0.0,
      stok: (json['stok'] as num?)?.toInt() ?? (json['stok_gudang'] as num?)?.toInt() ?? 0,
    );
  }
}
