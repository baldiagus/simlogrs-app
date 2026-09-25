class PenyesuaianDetailItemModel {
  final int id;
  final int barangId;
  final String kodeBarang;
  final String namaBarang;
  final String satuan;
  final String nomorBatch;
  final String lokasiRak;
  final String jenisPenyesuaian; // TAMBAH / KURANG
  final int jumlahPenyesuaian;
  final double hargaSatuan;
  final double subtotalNilai;
  final String catatan;

  const PenyesuaianDetailItemModel({
    required this.id,
    required this.barangId,
    required this.kodeBarang,
    required this.namaBarang,
    required this.satuan,
    required this.nomorBatch,
    required this.lokasiRak,
    required this.jenisPenyesuaian,
    required this.jumlahPenyesuaian,
    required this.hargaSatuan,
    required this.subtotalNilai,
    required this.catatan,
  });

  bool get isKurang => jenisPenyesuaian == 'KURANG';

  factory PenyesuaianDetailItemModel.fromJson(Map<String, dynamic> json) {
    return PenyesuaianDetailItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      barangId: json['barang_id'] is int ? json['barang_id'] as int : int.parse(json['barang_id'].toString()),
      kodeBarang: json['kode_barang']?.toString() ?? '-',
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      nomorBatch: json['nomor_batch']?.toString() ?? '-',
      lokasiRak: json['lokasi_rak']?.toString() ?? 'Tanpa Rak',
      jenisPenyesuaian: json['jenis_penyesuaian']?.toString() ?? 'KURANG',
      jumlahPenyesuaian: int.tryParse(json['jumlah_penyesuaian']?.toString() ?? '0') ?? 0,
      hargaSatuan: double.tryParse(json['harga_satuan']?.toString() ?? '0') ?? 0,
      subtotalNilai: double.tryParse(json['subtotal_nilai']?.toString() ?? '0') ?? 0,
      catatan: json['catatan']?.toString() ?? '-',
    );
  }
}

class PenyesuaianStokHeaderModel {
  final int id;
  final String kode;
  final String kodeOpname;
  final int gudangId;
  final String gudangNama;
  final String tanggalPenyesuaian;
  final String alasan;
  final String status; // 'MENUNGGU', 'DISETUJUI', 'DITOLAK'
  final int totalItem;
  final double totalNilaiSelisih;
  final String pengaju;
  final String penyetuju;
  final List<PenyesuaianDetailItemModel> items;

  const PenyesuaianStokHeaderModel({
    required this.id,
    required this.kode,
    required this.kodeOpname,
    required this.gudangId,
    required this.gudangNama,
    required this.tanggalPenyesuaian,
    required this.alasan,
    required this.status,
    required this.totalItem,
    required this.totalNilaiSelisih,
    required this.pengaju,
    required this.penyetuju,
    required this.items,
  });

  bool get isMenunggu => status == 'MENUNGGU';
  bool get isDisetujui => status == 'DISETUJUI';
  bool get isDitolak => status == 'DITOLAK';

  factory PenyesuaianStokHeaderModel.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?)
            ?.map((e) => PenyesuaianDetailItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PenyesuaianStokHeaderModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      kodeOpname: json['kode_opname']?.toString() ?? '-',
      gudangId: json['gudang_id'] is int ? json['gudang_id'] as int : int.parse(json['gudang_id'].toString()),
      gudangNama: json['gudang_nama']?.toString() ?? 'Gudang Sentral',
      tanggalPenyesuaian: json['tanggal_penyesuaian']?.toString() ?? '-',
      alasan: json['alasan']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'MENUNGGU',
      totalItem: int.tryParse(json['total_item']?.toString() ?? '0') ?? 0,
      totalNilaiSelisih: double.tryParse(json['total_nilai_selisih']?.toString() ?? '0') ?? 0,
      pengaju: json['pengaju']?.toString() ?? 'Petugas Gudang',
      penyetuju: json['penyetuju']?.toString() ?? '-',
      items: list,
    );
  }
}
