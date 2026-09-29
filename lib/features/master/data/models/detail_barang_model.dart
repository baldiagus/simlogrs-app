import 'master_barang_entity.dart';

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
