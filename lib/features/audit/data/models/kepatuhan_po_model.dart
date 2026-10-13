/// Satu baris item pada PO: jumlah dipesan vs diterima beserta harga.
class KepatuhanPoDetailModel {
  final int id;
  final String namaBarang;
  final String satuan;
  final int jumlahDipesan;
  final int jumlahDiterima;
  final double hargaSatuan;
  final double subtotal;

  const KepatuhanPoDetailModel({
    required this.id,
    required this.namaBarang,
    required this.satuan,
    required this.jumlahDipesan,
    required this.jumlahDiterima,
    required this.hargaSatuan,
    required this.subtotal,
  });

  /// Membangun detail item PO dari JSON dengan nilai default untuk field kosong.
  factory KepatuhanPoDetailModel.fromJson(Map<String, dynamic> json) {
    return KepatuhanPoDetailModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      jumlahDipesan: (json['jumlah_dipesan'] as num?)?.toInt() ?? 0,
      jumlahDiterima: (json['jumlah_diterima'] as num?)?.toInt() ?? 0,
      hargaSatuan: (json['harga_satuan'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// PO yang diperiksa kepatuhannya (PR, ketepatan waktu, selisih penerimaan) beserta tag anomali.
class KepatuhanPoModel {
  final int id;
  final String kode;
  final String pemasok;
  final String kodePemasok;
  final String tanggalPesan;
  final String estimasiTanggalKirim;
  final String status;
  final double totalBiaya;
  final String? prKode;
  final String? prUnit;
  final List<String> anomaliTags;
  final bool isCompliant;
  final int totalItem;
  final List<KepatuhanPoDetailModel> items;

  const KepatuhanPoModel({
    required this.id,
    required this.kode,
    required this.pemasok,
    required this.kodePemasok,
    required this.tanggalPesan,
    required this.estimasiTanggalKirim,
    required this.status,
    required this.totalBiaya,
    this.prKode,
    this.prUnit,
    required this.anomaliTags,
    required this.isCompliant,
    required this.totalItem,
    required this.items,
  });

  /// Membangun PO beserta tag anomali dan daftar itemnya dari JSON.
  factory KepatuhanPoModel.fromJson(Map<String, dynamic> json) {
    return KepatuhanPoModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode']?.toString() ?? '-',
      pemasok: json['pemasok']?.toString() ?? 'Vendor',
      kodePemasok: json['kode_pemasok']?.toString() ?? '-',
      tanggalPesan: json['tanggal_pesan']?.toString() ?? '-',
      estimasiTanggalKirim: json['estimasi_tanggal_kirim']?.toString() ?? '-',
      status: json['status']?.toString() ?? '-',
      totalBiaya: (json['total_biaya'] as num?)?.toDouble() ?? 0.0,
      prKode: json['pr_kode']?.toString(),
      prUnit: json['pr_unit']?.toString(),
      anomaliTags:
          (json['anomali_tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isCompliant: json['is_compliant'] == true,
      totalItem: (json['total_item'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => KepatuhanPoDetailModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
