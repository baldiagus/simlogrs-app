class AsetUnitModel {
  final int id;
  final String kodeAset;
  final String nama;
  final String nomorSeri;
  final String kategori;
  final String kondisi;
  final String status;

  const AsetUnitModel({
    required this.id,
    required this.kodeAset,
    required this.nama,
    required this.nomorSeri,
    required this.kategori,
    required this.kondisi,
    required this.status,
  });

  factory AsetUnitModel.fromJson(Map<String, dynamic> json) {
    return AsetUnitModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kodeAset: json['kode_aset']?.toString() ?? '-',
      nama: json['nama']?.toString() ?? 'Aset Fisik',
      nomorSeri: json['nomor_seri']?.toString() ?? '-',
      kategori: json['kategori']?.toString() ?? 'Umum',
      kondisi: json['kondisi']?.toString() ?? 'BAIK',
      status: json['status']?.toString() ?? 'TERSEDIA',
    );
  }
}

class PenugasanAktifInfo {
  final String kodeSpk;
  final String namaTeknisi;
  final String? statusSpk;

  const PenugasanAktifInfo({
    required this.kodeSpk,
    required this.namaTeknisi,
    this.statusSpk,
  });

  factory PenugasanAktifInfo.fromJson(Map<String, dynamic> json) {
    return PenugasanAktifInfo(
      kodeSpk: json['kode_spk']?.toString() ?? '',
      namaTeknisi: json['nama_teknisi']?.toString() ?? 'Teknisi IPSRS',
      statusSpk: json['status_spk']?.toString(),
    );
  }
}

class TiketMaintenanceModel {
  final int id;
  final String kode;
  final String status; // 'DILAPORKAN', 'DITUGASKAN', 'SEDANG_DIKERJAKAN', 'MENUNGGU_SPAREPART', 'UJI_FUNGSI', 'SELESAI', 'DIBATALKAN'
  final String prioritas; // 'RENDAH', 'SEDANG', 'TINGGI', 'CITO'
  final String deskripsiMasalah;
  final String? fotoUrl;
  final String? dibuatPada;
  final String unit;
  final String pelapor;
  final bool canCancel;
  final Map<String, dynamic> aset;
  final PenugasanAktifInfo? penugasanAktif;

  const TiketMaintenanceModel({
    required this.id,
    required this.kode,
    required this.status,
    required this.prioritas,
    required this.deskripsiMasalah,
    this.fotoUrl,
    this.dibuatPada,
    required this.unit,
    required this.pelapor,
    required this.canCancel,
    required this.aset,
    this.penugasanAktif,
  });

  bool get isCito => prioritas.toUpperCase() == 'CITO';
  bool get isTinggi => prioritas.toUpperCase() == 'TINGGI';
  bool get isDilaporkan => status.toUpperCase() == 'DILAPORKAN';
  bool get isSelesai => status.toUpperCase() == 'SELESAI';
  bool get isDibatalkan => status.toUpperCase() == 'DIBATALKAN';

  String get namaAset => aset['nama']?.toString() ?? 'Aset Fisik';
  String get kodeAset => aset['kode_aset']?.toString() ?? '-';
  String get nomorSeri => aset['nomor_seri']?.toString() ?? '-';

  factory TiketMaintenanceModel.fromJson(Map<String, dynamic> json) {
    return TiketMaintenanceModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DILAPORKAN',
      prioritas: json['prioritas']?.toString() ?? 'SEDANG',
      deskripsiMasalah: json['deskripsi_masalah']?.toString() ?? '',
      fotoUrl: json['foto_url']?.toString(),
      dibuatPada: json['dibuat_pada']?.toString(),
      unit: json['unit']?.toString() ?? '-',
      pelapor: json['pelapor']?.toString() ?? '-',
      canCancel: json['can_cancel'] == true,
      aset: json['aset'] is Map<String, dynamic>
          ? json['aset'] as Map<String, dynamic>
          : {},
      penugasanAktif: json['penugasan_aktif'] is Map<String, dynamic>
          ? PenugasanAktifInfo.fromJson(json['penugasan_aktif'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TiketDetailModel {
  final int id;
  final String kode;
  final String status;
  final String prioritas;
  final String deskripsiMasalah;
  final String? fotoUrl;
  final String? dibuatPada;
  final String unit;
  final String pelapor;
  final bool canCancel;
  final Map<String, dynamic> aset;
  final List<Map<String, dynamic>> penugasan;
  final List<Map<String, dynamic>> riwayatLog;

  const TiketDetailModel({
    required this.id,
    required this.kode,
    required this.status,
    required this.prioritas,
    required this.deskripsiMasalah,
    this.fotoUrl,
    this.dibuatPada,
    required this.unit,
    required this.pelapor,
    required this.canCancel,
    required this.aset,
    required this.penugasan,
    required this.riwayatLog,
  });

  bool get isCito => prioritas.toUpperCase() == 'CITO';
  bool get isDilaporkan => status.toUpperCase() == 'DILAPORKAN';
  String get namaAset => aset['nama']?.toString() ?? 'Aset Fisik';
  String get kodeAset => aset['kode_aset']?.toString() ?? '-';
  String get nomorSeri => aset['nomor_seri']?.toString() ?? '-';

  factory TiketDetailModel.fromJson(Map<String, dynamic> json) {
    return TiketDetailModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DILAPORKAN',
      prioritas: json['prioritas']?.toString() ?? 'SEDANG',
      deskripsiMasalah: json['deskripsi_masalah']?.toString() ?? '',
      fotoUrl: json['foto_url']?.toString(),
      dibuatPada: json['dibuat_pada']?.toString(),
      unit: json['unit']?.toString() ?? '-',
      pelapor: json['pelapor']?.toString() ?? '-',
      canCancel: json['can_cancel'] == true,
      aset: json['aset'] is Map<String, dynamic> ? json['aset'] as Map<String, dynamic> : {},
      penugasan: (json['penugasan'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      riwayatLog: (json['riwayat_log'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}
