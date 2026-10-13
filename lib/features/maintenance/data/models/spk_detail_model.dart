import 'spk_header_model.dart';

class SpkSparepartModel {
  final String barang;
  final int jumlah;
  final double subtotal;

  /// Membuat SpkSparepartModel.
  const SpkSparepartModel({
    required this.barang,
    required this.jumlah,
    required this.subtotal,
  });

  /// Membuat SpkSparepartModel dari JSON respons API.
  factory SpkSparepartModel.fromJson(Map<String, dynamic> json) {
    return SpkSparepartModel(
      barang: json['barang']?.toString() ?? 'Suku Cadang',
      jumlah: json['jumlah'] is int
          ? json['jumlah'] as int
          : int.tryParse(json['jumlah']?.toString() ?? '') ?? 1,
      subtotal: json['subtotal'] is num
          ? (json['subtotal'] as num).toDouble()
          : double.tryParse(json['subtotal']?.toString() ?? '') ?? 0.0,
    );
  }
}

class SpkLogModel {
  final int id;
  final String? tanggalPengerjaan;
  final String? teknisi;
  final String diagnosa;
  final String tindakan;
  final String hasil; // 'BERHASIL', 'PENDING', 'GAGAL'
  final String? catatan;
  final String? fotoUrl;
  final List<SpkSparepartModel> sukuCadang;

  /// Membuat SpkLogModel.
  const SpkLogModel({
    required this.id,
    this.tanggalPengerjaan,
    this.teknisi,
    required this.diagnosa,
    required this.tindakan,
    required this.hasil,
    this.catatan,
    this.fotoUrl,
    required this.sukuCadang,
  });

  /// Membuat SpkLogModel dari JSON respons API.
  factory SpkLogModel.fromJson(Map<String, dynamic> json) {
    return SpkLogModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      tanggalPengerjaan: json['tanggal_pengerjaan']?.toString(),
      teknisi: json['teknisi']?.toString(),
      diagnosa: json['diagnosa']?.toString() ?? '',
      tindakan: json['tindakan']?.toString() ?? '',
      hasil: json['hasil']?.toString() ?? 'BERHASIL',
      catatan: json['catatan']?.toString(),
      fotoUrl: json['foto_url']?.toString(),
      sukuCadang: (json['suku_cadang'] as List<dynamic>?)
              ?.map((e) => SpkSparepartModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SpkDetailModel {
  final int id;
  final String kodeSpk;
  final String status;
  final String? tanggalPenugasan;
  final String? targetSelesai;
  final String? instruksiKhusus;
  final String teknisi;
  final SpkTiketModel tiket;
  final SpkAsetModel aset;
  final List<SpkLogModel> riwayatLog;

  /// Membuat SpkDetailModel.
  const SpkDetailModel({
    required this.id,
    required this.kodeSpk,
    required this.status,
    this.tanggalPenugasan,
    this.targetSelesai,
    this.instruksiKhusus,
    required this.teknisi,
    required this.tiket,
    required this.aset,
    required this.riwayatLog,
  });

  /// Membuat SpkDetailModel dari JSON respons API.
  factory SpkDetailModel.fromJson(Map<String, dynamic> json) {
    return SpkDetailModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kodeSpk: json['kode_spk']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DITUGASKAN',
      tanggalPenugasan: json['tanggal_penugasan']?.toString(),
      targetSelesai: json['target_selesai']?.toString(),
      instruksiKhusus: json['instruksi_khusus']?.toString(),
      teknisi: json['teknisi'] is Map<String, dynamic>
          ? json['teknisi']['nama']?.toString() ?? '-'
          : json['teknisi']?.toString() ?? '-',
      tiket: json['tiket'] is Map<String, dynamic>
          ? SpkTiketModel.fromJson(json['tiket'] as Map<String, dynamic>)
          : const SpkTiketModel(kode: 'MNT', prioritas: 'SEDANG', deskripsiMasalah: ''),
      aset: json['aset'] is Map<String, dynamic>
          ? SpkAsetModel.fromJson(json['aset'] as Map<String, dynamic>)
          : const SpkAsetModel(kodeAset: '-', nama: '-', nomorSeri: '-', lokasi: '-'),
      riwayatLog: (json['riwayat_log'] as List<dynamic>?)
              ?.map((e) => SpkLogModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
