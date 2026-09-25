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

  int get totalStokFisik => tipe == 'ASET' ? totalAset : (stokGudang + stokRuangan);

  bool get isPerluPesan => titikPesan > 0 && totalStokFisik <= titikPesan;
  bool get isDiBawahMin => stokMinimum > 0 && totalStokFisik < stokMinimum;
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

class DaftarAsetFisikItem {
  final int id;
  final String kodeAset;
  final String nomorSeri;
  final String kondisi;
  final String status;
  final String lokasi;

  const DaftarAsetFisikItem({
    required this.id,
    required this.kodeAset,
    required this.nomorSeri,
    required this.kondisi,
    required this.status,
    required this.lokasi,
  });

  factory DaftarAsetFisikItem.fromJson(Map<String, dynamic> json) {
    return DaftarAsetFisikItem(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kodeAset: json['kode_aset']?.toString() ?? '',
      nomorSeri: json['nomor_seri']?.toString() ?? '-',
      kondisi: json['kondisi']?.toString() ?? 'BAIK',
      status: json['status']?.toString() ?? 'TERSEDIA',
      lokasi: json['lokasi']?.toString() ?? '-',
    );
  }
}

class DaftarBatchItem {
  final int id;
  final String nomorBatch;
  final String gudang;
  final String rak;
  final String? tanggalKedaluwarsa;
  final int jumlah;
  final double hargaSatuan;

  const DaftarBatchItem({
    required this.id,
    required this.nomorBatch,
    required this.gudang,
    required this.rak,
    this.tanggalKedaluwarsa,
    required this.jumlah,
    required this.hargaSatuan,
  });

  factory DaftarBatchItem.fromJson(Map<String, dynamic> json) {
    return DaftarBatchItem(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      nomorBatch: json['nomor_batch']?.toString() ?? '-',
      gudang: json['gudang']?.toString() ?? 'Gudang',
      rak: json['rak']?.toString() ?? '-',
      tanggalKedaluwarsa: json['tanggal_kedaluwarsa']?.toString(),
      jumlah: int.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
      hargaSatuan: double.tryParse(json['harga_satuan']?.toString() ?? '0') ?? 0,
    );
  }
}

class DaftarRuanganItem {
  final String unit;
  final int jumlah;

  const DaftarRuanganItem({
    required this.unit,
    required this.jumlah,
  });

  factory DaftarRuanganItem.fromJson(Map<String, dynamic> json) {
    return DaftarRuanganItem(
      unit: json['unit']?.toString() ?? 'Ruangan',
      jumlah: int.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
    );
  }
}

class DetailBarangModel {
  final MasterBarangItemModel master;
  final List<DaftarAsetFisikItem> daftarAset;
  final List<DaftarBatchItem> daftarBatch;
  final List<DaftarRuanganItem> daftarRuangan;

  const DetailBarangModel({
    required this.master,
    required this.daftarAset,
    required this.daftarBatch,
    required this.daftarRuangan,
  });

  factory DetailBarangModel.fromJson(Map<String, dynamic> json) {
    final master = MasterBarangItemModel.fromJson(json);
    final List<DaftarAsetFisikItem> da = (json['daftar_aset'] as List<dynamic>?)
            ?.map((e) => DaftarAsetFisikItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final List<DaftarBatchItem> db = (json['daftar_batch'] as List<dynamic>?)
            ?.map((e) => DaftarBatchItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final List<DaftarRuanganItem> dr = (json['daftar_ruangan'] as List<dynamic>?)
            ?.map((e) => DaftarRuanganItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DetailBarangModel(
      master: master,
      daftarAset: da,
      daftarBatch: db,
      daftarRuangan: dr,
    );
  }
}
