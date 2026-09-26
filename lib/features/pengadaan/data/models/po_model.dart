class PemasokOptionModel {
  final int id;
  final String kode;
  final String nama;
  final String? kota;
  final String? noTelepon;
  final String? alamat;

  const PemasokOptionModel({
    required this.id,
    required this.kode,
    required this.nama,
    this.kota,
    this.noTelepon,
    this.alamat,
  });

  factory PemasokOptionModel.fromJson(Map<String, dynamic> json) {
    return PemasokOptionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode']?.toString() ?? '-',
      nama: json['nama']?.toString() ?? '-',
      kota: json['kota']?.toString(),
      noTelepon: json['no_telepon']?.toString(),
      alamat: json['alamat']?.toString(),
    );
  }
}

class PoItemDetailModel {
  final int id;
  final int barangId;
  final String namaBarang;
  final String satuan;
  final int jumlahDipesan;
  final int jumlahDiterima;
  final double hargaSatuan;
  final double subtotal;

  const PoItemDetailModel({
    required this.id,
    required this.barangId,
    required this.namaBarang,
    required this.satuan,
    required this.jumlahDipesan,
    required this.jumlahDiterima,
    required this.hargaSatuan,
    required this.subtotal,
  });

  factory PoItemDetailModel.fromJson(Map<String, dynamic> json) {
    return PoItemDetailModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      barangId: (json['barang_id'] as num?)?.toInt() ?? 0,
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      jumlahDipesan: (json['jumlah_dipesan'] as num?)?.toInt() ?? 0,
      jumlahDiterima: (json['jumlah_diterima'] as num?)?.toInt() ?? 0,
      hargaSatuan: (json['harga_satuan'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PesananPembelianModel {
  final int id;
  final String kode;
  final int pemasokId;
  final String namaPemasok;
  final String kodePemasok;
  final int? permintaanPengadaanId;
  final String? prKode;
  final String? prUnit;
  final String tanggalPo;
  final String estimasiTanggalKirim;
  final double totalBiaya;
  final String syaratPembayaran;
  final String status;
  final String? catatan;
  final String pembuat;
  final int totalItem;
  final List<PoItemDetailModel> items;

  const PesananPembelianModel({
    required this.id,
    required this.kode,
    required this.pemasokId,
    required this.namaPemasok,
    required this.kodePemasok,
    this.permintaanPengadaanId,
    this.prKode,
    this.prUnit,
    required this.tanggalPo,
    required this.estimasiTanggalKirim,
    required this.totalBiaya,
    required this.syaratPembayaran,
    required this.status,
    this.catatan,
    required this.pembuat,
    required this.totalItem,
    required this.items,
  });

  bool get isDiterbitkan => status.toUpperCase() == 'DITERBITKAN';
  bool get isDikirimVendor => status.toUpperCase() == 'DIKIRIM_VENDOR';
  bool get isDiterimaSebagian => status.toUpperCase() == 'DITERIMA_SEBAGIAN';
  bool get isSelesai => status.toUpperCase() == 'DITERIMA_LENGKAP';

  factory PesananPembelianModel.fromJson(Map<String, dynamic> json) {
    return PesananPembelianModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode']?.toString() ?? '-',
      pemasokId: (json['pemasok_id'] as num?)?.toInt() ?? 0,
      namaPemasok: json['nama_pemasok']?.toString() ?? (json['pemasok'] is Map ? (json['pemasok']['nama']?.toString() ?? 'Vendor') : 'Vendor'),
      kodePemasok: json['kode_pemasok']?.toString() ?? (json['pemasok'] is Map ? (json['pemasok']['kode']?.toString() ?? '-') : '-'),
      permintaanPengadaanId: (json['permintaan_pengadaan_id'] as num?)?.toInt(),
      prKode: json['pr_kode']?.toString(),
      prUnit: json['pr_unit']?.toString(),
      tanggalPo: json['tanggal_po']?.toString() ?? '-',
      estimasiTanggalKirim: json['estimasi_tanggal_kirim']?.toString() ?? '-',
      totalBiaya: (json['total_biaya'] as num?)?.toDouble() ?? 0.0,
      syaratPembayaran: json['syarat_pembayaran']?.toString() ?? 'TEMPO_30_HARI',
      status: json['status']?.toString() ?? 'DITERBITKAN',
      catatan: json['catatan']?.toString(),
      pembuat: json['pembuat']?.toString() ?? '-',
      totalItem: (json['total_item'] as num?)?.toInt() ?? (json['items'] is List ? (json['items'] as List).length : 0),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PoItemDetailModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
