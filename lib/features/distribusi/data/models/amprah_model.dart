class BarangAmprahKatalogModel {
  final int id;
  final String kode;
  final String nama;
  final String? spesifikasi;
  final String tipe;
  final String tipeLabel;
  final String kategori;
  final String satuan;
  final String merek;
  final int stokTersedia;

  const BarangAmprahKatalogModel({
    required this.id,
    required this.kode,
    required this.nama,
    this.spesifikasi,
    required this.tipe,
    required this.tipeLabel,
    required this.kategori,
    required this.satuan,
    required this.merek,
    required this.stokTersedia,
  });

  /// Membangun model katalog barang dari respons JSON API, dengan nilai default aman
  /// agar field yang hilang atau bertipe tidak sesuai tidak membuat parsing gagal.
  factory BarangAmprahKatalogModel.fromJson(Map<String, dynamic> json) {
    return BarangAmprahKatalogModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '-',
      nama: json['nama']?.toString() ?? 'Barang',
      spesifikasi: json['spesifikasi']?.toString(),
      tipe: json['tipe']?.toString() ?? 'HABIS_PAKAI',
      tipeLabel: json['tipe_label']?.toString() ?? 'Habis Pakai (ATK/ART)',
      kategori: json['kategori']?.toString() ?? 'Umum',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      merek: json['merek']?.toString() ?? '-',
      stokTersedia: json['stok_tersedia'] is int
          ? json['stok_tersedia'] as int
          : int.tryParse(json['stok_tersedia']?.toString() ?? '') ?? 0,
    );
  }
}

class AmprahDetailItemModel {
  final int id;
  final int barangId;
  final String namaBarang;
  final String kodeBarang;
  final String satuan;
  final int jumlahDiminta;
  final int jumlahDisetujui;
  final int jumlahDikirim;
  final String? catatan;

  const AmprahDetailItemModel({
    required this.id,
    required this.barangId,
    required this.namaBarang,
    required this.kodeBarang,
    required this.satuan,
    required this.jumlahDiminta,
    required this.jumlahDisetujui,
    this.jumlahDikirim = 0,
    this.catatan,
  });

  /// Sisa jumlah disetujui yang belum dikirim (backorder), dibatasi minimal 0
  /// supaya pengiriman berlebih tidak menghasilkan angka negatif.
  int get sisaBackorder => (jumlahDisetujui - jumlahDikirim).clamp(0, jumlahDisetujui);

  /// Membangun item detail amprah dari JSON API, menoleransi angka berupa string atau int.
  factory AmprahDetailItemModel.fromJson(Map<String, dynamic> json) {
    return AmprahDetailItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      barangId: json['barang_id'] is int
          ? json['barang_id'] as int
          : int.parse(json['barang_id'].toString()),
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      kodeBarang: json['kode_barang']?.toString() ?? '-',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      jumlahDiminta: json['jumlah_diminta'] is int
          ? json['jumlah_diminta'] as int
          : int.tryParse(json['jumlah_diminta']?.toString() ?? '') ?? 0,
      jumlahDisetujui: json['jumlah_disetujui'] is int
          ? json['jumlah_disetujui'] as int
          : int.tryParse(json['jumlah_disetujui']?.toString() ?? '') ?? 0,
      jumlahDikirim: json['jumlah_dikirim'] is int
          ? json['jumlah_dikirim'] as int
          : (json['jumlah_terkirim'] is int
              ? json['jumlah_terkirim'] as int
              : (int.tryParse(json['jumlah_dikirim']?.toString() ??
                      json['jumlah_terkirim']?.toString() ??
                      json['terkirim']?.toString() ??
                      '') ??
                  0)),
      catatan: json['catatan']?.toString(),
    );
  }
}

class AmprahHeaderModel {
  final int id;
  final String kode;
  final String unit;
  final String gudang;
  final String pengaju;
  final String tanggalPermintaan;
  final String urgensi;
  final String status;
  final String? catatan;
  final bool canCancel;
  final int jumlahItem;
  final List<AmprahDetailItemModel> items;

  const AmprahHeaderModel({
    required this.id,
    required this.kode,
    required this.unit,
    required this.gudang,
    required this.pengaju,
    required this.tanggalPermintaan,
    required this.urgensi,
    required this.status,
    this.catatan,
    required this.canCancel,
    required this.jumlahItem,
    required this.items,
  });

  /// True bila permintaan berurgensi CITO (darurat) sehingga perlu diprioritaskan di UI.
  bool get isCito => urgensi.toUpperCase() == 'CITO';
  /// True bila amprah baru diajukan dan menunggu persetujuan Karu.
  bool get isDiajukan => status.toUpperCase() == 'DIAJUKAN';
  /// True bila amprah sudah disetujui Kepala Ruangan dan menunggu gudang.
  bool get isDisetujuiKaru => status.toUpperCase() == 'DISETUJUI_KARU';
  /// True bila amprah sudah disetujui gudang dan siap diproses picking.
  bool get isDisetujuiGudang => status.toUpperCase() == 'DISETUJUI_GUDANG';
  /// True bila seluruh barang amprah sudah dikirim dan diterima (proses selesai).
  bool get isSelesai => status.toUpperCase() == 'SELESAI';
  /// True bila amprah ditolak sehingga tidak akan diproses lebih lanjut.
  bool get isDitolak => status.toUpperCase() == 'DITOLAK';
  /// True bila barang baru dikirim sebagian dan masih ada sisa backorder.
  bool get isDikirimSebagian => status.toUpperCase() == 'DIKIRIM_SEBAGIAN';

  /// Membangun header amprah beserta daftar item dari JSON API, mengisi default
  /// untuk field kosong agar tampilan daftar tetap konsisten.
  factory AmprahHeaderModel.fromJson(Map<String, dynamic> json) {
    return AmprahHeaderModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'Unit Ruangan',
      gudang: json['gudang']?.toString() ?? 'Gudang Sentral',
      pengaju: json['pengaju']?.toString() ?? 'Staf',
      tanggalPermintaan: json['tanggal_permintaan']?.toString() ?? '',
      urgensi: json['urgensi']?.toString() ?? 'REGULER',
      status: json['status']?.toString() ?? 'DIAJUKAN',
      catatan: json['catatan']?.toString(),
      canCancel: json['can_cancel'] == true,
      jumlahItem: json['jumlah_item'] is int
          ? json['jumlah_item'] as int
          : int.tryParse(json['jumlah_item']?.toString() ?? '') ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => AmprahDetailItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AmprahCartDraftItem {
  final BarangAmprahKatalogModel barang;
  int jumlah;
  String? catatan;

  AmprahCartDraftItem({
    required this.barang,
    this.jumlah = 1,
    this.catatan,
  });

  /// Mengubah draft keranjang menjadi payload JSON untuk pengiriman amprah ke server;
  /// catatan hanya disertakan bila terisi.
  Map<String, dynamic> toSubmissionJson() => {
        'barang_id': barang.id,
        'jumlah': jumlah,
        if (catatan != null && catatan!.isNotEmpty) 'catatan': catatan,
      };
}
