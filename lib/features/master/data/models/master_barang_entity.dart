class MasterBarangItemModel {
  final int id;
  final String kode;
  final String nama;
  final String? spesifikasi;
  final String tipe; // HABIS_PAKAI, ASET, SPAREPART
  final String tipeLabel;
  final String kategori;
  final String satuan;
  final String simbolSatuan;
  final String merek;
  final String pemasok;
  final double hargaBeliTerakhir;
  final double hargaEstimasi;
  final int stokMinimum;
  final int stokMaksimum;
  final int titikPesan;
  final String status;
  final int stokGudang;
  final int stokRuangan;
  final int totalAset;

  const MasterBarangItemModel({
    required this.id,
    required this.kode,
    required this.nama,
    this.spesifikasi,
    required this.tipe,
    required this.tipeLabel,
    required this.kategori,
    required this.satuan,
    required this.simbolSatuan,
    required this.merek,
    required this.pemasok,
    required this.hargaBeliTerakhir,
    required this.hargaEstimasi,
    required this.stokMinimum,
    required this.stokMaksimum,
    required this.titikPesan,
    required this.status,
    required this.stokGudang,
    required this.stokRuangan,
    required this.totalAset,
  });

  int get totalStokFisik => tipe == 'ASET' ? (totalAset + stokGudang) : (stokGudang + stokRuangan);

  bool get isPerluPesan => titikPesan > 0 && totalStokFisik <= titikPesan;
  bool get isHabis => totalStokFisik <= 0;

  factory MasterBarangItemModel.fromJson(Map<String, dynamic> json) {
    return MasterBarangItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      spesifikasi: json['spesifikasi']?.toString(),
      tipe: json['tipe']?.toString() ?? 'HABIS_PAKAI',
      tipeLabel: json['tipe_label']?.toString() ?? 'Habis Pakai',
      kategori: json['kategori']?.toString() ?? 'Umum',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      simbolSatuan: json['simbol_satuan']?.toString() ?? 'Pcs',
      merek: json['merek']?.toString() ?? '-',
      pemasok: json['pemasok']?.toString() ?? '-',
      hargaBeliTerakhir: double.tryParse(json['harga_beli_terakhir']?.toString() ?? '0') ?? 0,
      hargaEstimasi: double.tryParse(json['harga_estimasi']?.toString() ?? '0') ?? 0,
      stokMinimum: int.tryParse(json['stok_minimum']?.toString() ?? '0') ?? 0,
      stokMaksimum: int.tryParse(json['stok_maksimum']?.toString() ?? '0') ?? 0,
      titikPesan: int.tryParse(json['titik_pesan']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'AKTIF',
      stokGudang: int.tryParse(json['stok_gudang']?.toString() ?? '0') ?? 0,
      stokRuangan: int.tryParse(json['stok_ruangan']?.toString() ?? '0') ?? 0,
      totalAset: int.tryParse(json['total_aset']?.toString() ?? '0') ?? 0,
    );
  }
}
