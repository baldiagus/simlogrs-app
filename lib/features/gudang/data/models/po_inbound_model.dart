/// Item baris pada PO inbound: jumlah dipesan, sudah diterima, dan sisa kebutuhan.
class PoInboundItemModel {
  final int id;
  final int barangId;
  final String kodeBarang;
  final String namaBarang;
  final String satuan;
  final int jumlahDipesan;
  final int jumlahSudahDiterima;
  final int sisaKebutuhan;
  final double hargaSatuan;

  const PoInboundItemModel({
    required this.id,
    required this.barangId,
    required this.kodeBarang,
    required this.namaBarang,
    required this.satuan,
    required this.jumlahDipesan,
    required this.jumlahSudahDiterima,
    required this.sisaKebutuhan,
    required this.hargaSatuan,
  });

  /// Membangun [PoInboundItemModel] dari JSON API dengan konversi tipe aman.
  factory PoInboundItemModel.fromJson(Map<String, dynamic> json) {
    return PoInboundItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      barangId: json['barang_id'] is int
          ? json['barang_id'] as int
          : int.parse(json['barang_id'].toString()),
      kodeBarang: json['kode_barang']?.toString() ?? '-',
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      jumlahDipesan: json['jumlah_dipesan'] is int
          ? json['jumlah_dipesan'] as int
          : int.tryParse(json['jumlah_dipesan']?.toString() ?? '') ?? 0,
      jumlahSudahDiterima: json['jumlah_sudah_diterima'] is int
          ? json['jumlah_sudah_diterima'] as int
          : int.tryParse(json['jumlah_sudah_diterima']?.toString() ?? '') ?? 0,
      sisaKebutuhan: json['sisa_kebutuhan'] is int
          ? json['sisa_kebutuhan'] as int
          : int.tryParse(json['sisa_kebutuhan']?.toString() ?? '') ?? 0,
      hargaSatuan: json['harga_satuan'] is num
          ? (json['harga_satuan'] as num).toDouble()
          : double.tryParse(json['harga_satuan']?.toString() ?? '') ?? 0.0,
    );
  }
}

/// Header PO inbound (pemasok, tanggal, status) beserta daftar itemnya.
class PoInboundHeaderModel {
  final int id;
  final String kodePo;
  final String pemasok;
  final String tanggalPo;
  final String? estimasiTanggalKirim;
  final String status;
  final int totalItem;
  final List<PoInboundItemModel> items;

  const PoInboundHeaderModel({
    required this.id,
    required this.kodePo,
    required this.pemasok,
    required this.tanggalPo,
    this.estimasiTanggalKirim,
    required this.status,
    required this.totalItem,
    required this.items,
  });

  /// True bila PO boleh menerima barang (sudah dikirim vendor atau diterima sebagian).
  bool get canReceive => status == 'DIKIRIM_VENDOR' || status == 'DITERIMA_SEBAGIAN';
  /// True bila PO baru diterbitkan dan belum dikirim vendor.
  bool get isDiterbitkan => status == 'DITERBITKAN';

  /// Membangun [PoInboundHeaderModel] dari JSON API, termasuk item bersarang.
  factory PoInboundHeaderModel.fromJson(Map<String, dynamic> json) {
    return PoInboundHeaderModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kodePo: json['kode_po']?.toString() ?? '',
      pemasok: json['pemasok']?.toString() ?? '-',
      tanggalPo: json['tanggal_po']?.toString() ?? '',
      estimasiTanggalKirim: json['estimasi_tanggal_kirim']?.toString(),
      status: json['status']?.toString() ?? 'DIKIRIM_VENDOR',
      totalItem: json['total_item'] is int
          ? json['total_item'] as int
          : int.tryParse(json['total_item']?.toString() ?? '') ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PoInboundItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Draft input penerimaan barang per item PO sebelum dikirim ke server.
class InboundItemDraft {
  final PoInboundItemModel poItem;
  int jumlahDiterima;
  int jumlahRusak;
  String nomorBatch;
  String? tanggalKedaluwarsa;
  int? lokasiGudangId;

  /// Membuat draft penerimaan satu item PO (jumlah, batch, kedaluwarsa, lokasi) sebelum dikirim.
  InboundItemDraft({
    required this.poItem,
    required this.jumlahDiterima,
    this.jumlahRusak = 0,
    required this.nomorBatch,
    this.tanggalKedaluwarsa,
    this.lokasiGudangId,
  });

  /// Serialisasi draft ke payload JSON penerimaan; tanggal kedaluwarsa hanya disertakan bila terisi.
  Map<String, dynamic> toJson() => {
        'barang_id': poItem.barangId,
        'lokasi_gudang_id': lokasiGudangId,
        'nomor_batch': nomorBatch,
        if (tanggalKedaluwarsa != null && tanggalKedaluwarsa!.isNotEmpty)
          'tanggal_kedaluwarsa': tanggalKedaluwarsa,
        'jumlah_diterima': jumlahDiterima,
        'jumlah_rusak': jumlahRusak,
      };
}
