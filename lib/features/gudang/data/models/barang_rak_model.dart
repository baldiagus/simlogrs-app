class BarangRakModel {
  final int id;
  final int? barangId;
  final String namaBarang;
  final String kodeBarang;
  final String tipe;
  final String tipeLabel;
  final String kategori;
  final String satuan;
  final String merek;
  final String? nomorBatch;
  final String? tanggalKedaluwarsa;
  final String statusKedaluwarsa; // 'AMAN', 'MENDEKATI_KADALUWARSA', 'KADALUWARSA'
  final int kuantitasStok;

  const BarangRakModel({
    required this.id,
    this.barangId,
    required this.namaBarang,
    required this.kodeBarang,
    this.tipe = 'HABIS_PAKAI',
    this.tipeLabel = 'Habis Pakai (ATK/ART)',
    required this.kategori,
    required this.satuan,
    required this.merek,
    this.nomorBatch,
    this.tanggalKedaluwarsa,
    required this.statusKedaluwarsa,
    required this.kuantitasStok,
  });
  bool get isAset => tipe.toUpperCase() == 'ASET';
  bool get isSparepart => tipe.toUpperCase() == 'SPAREPART';

  bool get isKadaluwarsa => statusKedaluwarsa.toUpperCase() == 'KADALUWARSA';
  bool get isMendekatiKadaluwarsa =>
      statusKedaluwarsa.toUpperCase() == 'MENDEKATI_KADALUWARSA';

  factory BarangRakModel.fromJson(Map<String, dynamic> json) {
    return BarangRakModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      barangId: json['barang_id'] is int
          ? json['barang_id'] as int
          : int.tryParse(json['barang_id']?.toString() ?? ''),
      namaBarang: json['nama_barang']?.toString() ?? json['nama']?.toString() ?? 'Barang',
      kodeBarang: json['kode_barang']?.toString() ?? json['kode']?.toString() ?? '-',
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
      nomorBatch: json['nomor_batch']?.toString(),
      tanggalKedaluwarsa: json['tanggal_kedaluwarsa']?.toString(),
      statusKedaluwarsa: json['status_kedaluwarsa']?.toString() ?? 'AMAN',
      kuantitasStok: json['kuantitas_stok'] is int
          ? json['kuantitas_stok'] as int
          : (json['jumlah'] is int
              ? json['jumlah'] as int
              : int.tryParse(json['kuantitas_stok']?.toString() ??
                      json['jumlah']?.toString() ??
                      '') ??
                  0),
    );
  }
}
