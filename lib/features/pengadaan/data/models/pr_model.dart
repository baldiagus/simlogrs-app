import '../../../approval/data/models/approval_item_model.dart';
import 'master_barang_model.dart';
class PrDetailItemModel {
  final int id;
  final int barangId;
  final String namaBarang;
  final String? kodeBarang;
  final String satuan;
  final int jumlah;
  final String? catatan;

  const PrDetailItemModel({
    required this.id,
    required this.barangId,
    required this.namaBarang,
    this.kodeBarang,
    required this.satuan,
    required this.jumlah,
    this.catatan,
  });

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
    required this.jumlahItem,
    required this.items,
  });

  bool get isCito => urgensi.toUpperCase() == 'CITO' || urgensi.toUpperCase() == 'MENDESAK';

  bool get isDiajukan => status.toUpperCase() == 'DIAJUKAN';

  bool get isSiapPo {
    final s = status.toUpperCase();
    return s == 'DISETUJUI' || s == 'DITERUSKAN_KE_PENGADAAN';
  }

  bool get isDisetujui {
    final s = status.toUpperCase();
    return s.contains('SETUJU') ||
        s == 'DITERUSKAN_KE_PENGADAAN' ||
        s.contains('PO') ||
        s == 'SELESAI';
  }

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
              ))
          .toList(),
    );
  }
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

  Map<String, dynamic> toSubmissionJson() => {
        'barang_id': barang.id,
        'jumlah': jumlah,
        if (catatan != null && catatan!.isNotEmpty) 'catatan': catatan,
      };
}
