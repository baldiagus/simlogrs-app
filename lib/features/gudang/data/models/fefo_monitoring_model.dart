class FefoMetrikModel {
  final int countExpired;
  final int countKritis30;
  final int countPeringatan90;
  final int countRop;
  final int totalBatchAktif;

  const FefoMetrikModel({
    required this.countExpired,
    required this.countKritis30,
    required this.countPeringatan90,
    required this.countRop,
    required this.totalBatchAktif,
  });

  factory FefoMetrikModel.fromJson(Map<String, dynamic> json) {
    return FefoMetrikModel(
      countExpired: int.tryParse(json['count_expired']?.toString() ?? '0') ?? 0,
      countKritis30: int.tryParse(json['count_kritis_30']?.toString() ?? '0') ?? 0,
      countPeringatan90: int.tryParse(json['count_peringatan_90']?.toString() ?? '0') ?? 0,
      countRop: int.tryParse(json['count_rop']?.toString() ?? '0') ?? 0,
      totalBatchAktif: int.tryParse(json['total_batch_aktif']?.toString() ?? '0') ?? 0,
    );
  }
}

class FefoBatchItemModel {
  final int id;
  final String nomorBatch;
  final int barangId;
  final String kodeBarang;
  final String namaBarang;
  final String kategori;
  final String satuan;
  final String gudang;
  final String lokasiRak;
  final String? tanggalKedaluwarsa;
  final int? sisaHari;
  final int jumlah;
  final double hargaSatuan;
  final double nilaiTotal;
  final String statusFefo; // 'KEDALUWARSA', 'KRITIS', 'PERINGATAN', 'AMAN', 'TANPA_ED'

  const FefoBatchItemModel({
    required this.id,
    required this.nomorBatch,
    required this.barangId,
    required this.kodeBarang,
    required this.namaBarang,
    required this.kategori,
    required this.satuan,
    required this.gudang,
    required this.lokasiRak,
    this.tanggalKedaluwarsa,
    this.sisaHari,
    required this.jumlah,
    required this.hargaSatuan,
    required this.nilaiTotal,
    required this.statusFefo,
  });

  factory FefoBatchItemModel.fromJson(Map<String, dynamic> json) {
    return FefoBatchItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      nomorBatch: json['nomor_batch']?.toString() ?? '-',
      barangId: json['barang_id'] is int ? json['barang_id'] as int : int.parse(json['barang_id'].toString()),
      kodeBarang: json['kode_barang']?.toString() ?? '-',
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      kategori: json['kategori']?.toString() ?? 'Umum',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      gudang: json['gudang']?.toString() ?? 'Gudang Sentral',
      lokasiRak: json['lokasi_rak']?.toString() ?? 'Tanpa Rak',
      tanggalKedaluwarsa: json['tanggal_kedaluwarsa']?.toString(),
      sisaHari: json['sisa_hari'] != null ? int.tryParse(json['sisa_hari'].toString()) : null,
      jumlah: int.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
      hargaSatuan: double.tryParse(json['harga_satuan']?.toString() ?? '0') ?? 0,
      nilaiTotal: double.tryParse(json['nilai_total']?.toString() ?? '0') ?? 0,
      statusFefo: json['status_fefo']?.toString() ?? 'AMAN',
    );
  }
}

class FefoMonitoringResponse {
  final FefoMetrikModel metrik;
  final List<FefoBatchItemModel> items;

  const FefoMonitoringResponse({
    required this.metrik,
    required this.items,
  });

  factory FefoMonitoringResponse.fromJson(Map<String, dynamic> json) {
    final m = json['metrik'] is Map<String, dynamic>
        ? FefoMetrikModel.fromJson(json['metrik'] as Map<String, dynamic>)
        : const FefoMetrikModel(
            countExpired: 0,
            countKritis30: 0,
            countPeringatan90: 0,
            countRop: 0,
            totalBatchAktif: 0,
          );

    final list = (json['items'] as List<dynamic>?)
            ?.map((e) => FefoBatchItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return FefoMonitoringResponse(metrik: m, items: list);
  }
}
