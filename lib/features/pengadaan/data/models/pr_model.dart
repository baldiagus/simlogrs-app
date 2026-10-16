import 'approval_item_model.dart';
import 'master_barang_model.dart';

abstract final class PrStatus {
  static const String diajukan = 'DIAJUKAN';
  static const String diteruskanKePengadaan = 'DITERUSKAN_KE_PENGADAAN';
  static const String diproses = 'DIPROSES';
  static const String selesai = 'SELESAI';
  static const String ditolak = 'DITOLAK';
  static const String disetujui = 'DISETUJUI';
  static const String disetujuiKaru = 'DISETUJUI_KARU';

  /// Status yang menandakan PR sudah melewati tahap persetujuan.
  static const Set<String> sudahDisetujui = {
    disetujui,
    disetujuiKaru,
    diteruskanKePengadaan,
    diproses,
    selesai,
  };
}
class PrDetailItemModel {
  final int id;
  final int barangId;
  final String namaBarang;
  final String? kodeBarang;
  final String satuan;
  final int jumlah;
  final String? catatan;
  final double? hargaBeliTerakhir;
  final double? hargaEstimasi;

  const PrDetailItemModel({
    required this.id,
    required this.barangId,
    required this.namaBarang,
    this.kodeBarang,
    required this.satuan,
    required this.jumlah,
    this.catatan,
    this.hargaBeliTerakhir,
    this.hargaEstimasi,
  });

  /// Membuat [PrDetailItemModel] dari JSON item permintaan pengadaan (PR).
  factory PrDetailItemModel.fromJson(Map<String, dynamic> json) {
    return PrDetailItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      barangId: json['barang_id'] is int
          ? json['barang_id'] as int
          : int.parse(json['barang_id'].toString()),
      namaBarang: json['nama_barang']?.toString() ?? 'Barang',
      kodeBarang: json['kode_barang']?.toString(),
      satuan: json['satuan']?.toString() ?? 'Pcs',
      jumlah: json['jumlah'] is int
          ? json['jumlah'] as int
          : int.tryParse(json['jumlah'].toString()) ?? 1,
      catatan: json['catatan']?.toString(),
      hargaBeliTerakhir: (json['harga_beli_terakhir'] as num?)?.toDouble(),
      hargaEstimasi: (json['harga_estimasi'] as num?)?.toDouble(),
    );
  }
}

class PrHeaderModel {
  final int id;
  final String kode;
  final String unit;
  final String pengaju;
  final String tanggalPermintaan;
  final String urgensi;
  final String status;
  final String? catatan;
  final String? nomorPo;
  final String? statusPo;
  final int jumlahItem;
  final List<PrDetailItemModel> items;

  const PrHeaderModel({
    required this.id,
    required this.kode,
    required this.unit,
    required this.pengaju,
    required this.tanggalPermintaan,
    required this.urgensi,
    required this.status,
    this.catatan,
    this.nomorPo,
    this.statusPo,
    required this.jumlahItem,
    required this.items,
  });

  /// True jika permintaan bersifat darurat (CITO/MENDESAK) sehingga perlu diprioritaskan.
  bool get isCito => urgensi.toUpperCase() == 'CITO' || urgensi.toUpperCase() == 'MENDESAK';

  /// True jika PR baru diajukan dan menunggu persetujuan.
  bool get isDiajukan => status.toUpperCase() == 'DIAJUKAN';
  /// True jika PR sedang diproses oleh bagian pengadaan.
  bool get isDiproses => status.toUpperCase() == 'DIPROSES';
  /// True jika proses PR sudah selesai.
  bool get isSelesai => status.toUpperCase() == 'SELESAI';

  /// True jika PR sudah melewati tahap persetujuan (disetujui, disetujui Karu, diteruskan, diproses, atau selesai).
  bool get isDisetujui => PrStatus.sudahDisetujui.contains(status.toUpperCase());

  /// Mengubah PR menjadi [ApprovalItemModel] agar dapat ditampilkan di alur persetujuan.
  ApprovalItemModel toApprovalItem() {
    return ApprovalItemModel(
      id: id,
      tipe: 'PR',
      kode: kode,
      unit: unit,
      pengaju: pengaju,
      tanggal: tanggalPermintaan,
      urgensi: urgensi,
      status: status,
      jumlahItem: jumlahItem,
      items: items
          .map((i) => ApprovalDetailItem(
                barangId: i.barangId,
                namaBarang: i.namaBarang,
                kodeBarang: i.kodeBarang,
                satuan: i.satuan,
                jumlah: i.jumlah,
                hargaBeliTerakhir: i.hargaBeliTerakhir,
                hargaEstimasi: i.hargaEstimasi,
              ))
          .toList(),
    );
  }
  /// Membuat [PrHeaderModel] dari JSON header PR beserta item-nya, dengan nilai bawaan bila field kosong.
  factory PrHeaderModel.fromJson(Map<String, dynamic> json) {
    return PrHeaderModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'Unit',
      pengaju: json['pengaju']?.toString() ?? 'Staf',
      tanggalPermintaan: json['tanggal_permintaan']?.toString() ?? '',
      urgensi: json['urgensi']?.toString() ?? 'REGULER',
      status: json['status']?.toString() ?? 'DIAJUKAN',
      catatan: json['catatan']?.toString(),
      nomorPo: json['nomor_po']?.toString(),
      statusPo: json['status_po']?.toString(),
      jumlahItem: json['jumlah_item'] is int
          ? json['jumlah_item'] as int
          : int.tryParse(json['jumlah_item'].toString()) ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PrDetailItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PrCartItemModel {
  final MasterBarangModel barang;
  int jumlah;
  String? catatan;

  PrCartItemModel({
    required this.barang,
    this.jumlah = 1,
    this.catatan,
  });

  /// Mengubah item keranjang menjadi payload JSON untuk dikirim saat pengajuan PR.
  Map<String, dynamic> toSubmissionJson() => {
        'barang_id': barang.id,
        'jumlah': jumlah,
        if (catatan != null && catatan!.isNotEmpty) 'catatan': catatan,
      };
}
