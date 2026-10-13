import 'rak_model.dart';
import 'barang_rak_model.dart';

/// Aset fisik (inventaris) yang ditempatkan pada sebuah rak gudang.
class AsetRakModel {
  final int id;
  final String kodeAset;
  final String namaAset;
  final String? merk;
  final String? model;
  final String? nomorSeri;
  final String statusKetersediaan; // 'TERSEDIA', 'DIPINJAM', 'DALAM_MAINTENANCE', 'RUSAK'
  final String kondisiFisik; // 'BAIK', 'RUSAK_RINGAN', 'RUSAK_BERAT'

  const AsetRakModel({
    required this.id,
    required this.kodeAset,
    required this.namaAset,
    this.merk,
    this.model,
    this.nomorSeri,
    required this.statusKetersediaan,
    required this.kondisiFisik,
  });

  /// Membangun [AsetRakModel] dari JSON API; field kosong diisi nilai default aman.
  factory AsetRakModel.fromJson(Map<String, dynamic> json) {
    return AsetRakModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kodeAset: json['kode_aset']?.toString() ?? '',
      namaAset: json['nama_aset']?.toString() ?? json['nama']?.toString() ?? 'Aset Fisik',
      merk: json['merk']?.toString(),
      model: json['model']?.toString(),
      nomorSeri: json['nomor_seri']?.toString(),
      statusKetersediaan:
          json['status_ketersediaan']?.toString() ?? json['status']?.toString() ?? 'TERSEDIA',
      kondisiFisik:
          json['kondisi_fisik']?.toString() ?? json['kondisi']?.toString() ?? 'BAIK',
    );
  }
}

/// Detail rak: data rak beserta daftar barang dan aset yang tersimpan di dalamnya.
class RakDetailModel {
  final RakModel rak;
  final List<BarangRakModel> barang;
  final List<AsetRakModel> aset;

  const RakDetailModel({
    required this.rak,
    required this.barang,
    required this.aset,
  });

  /// Membangun [RakDetailModel] dari JSON API, termasuk list `barang` dan `aset` bersarang.
  factory RakDetailModel.fromJson(Map<String, dynamic> json) {
    return RakDetailModel(
      rak: RakModel.fromJson(json),
      barang: (json['barang'] as List<dynamic>?)
              ?.map((e) => BarangRakModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      aset: (json['aset'] as List<dynamic>?)
              ?.map((e) => AsetRakModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
