class SpkAsetModel {
  final int? id;
  final String kodeAset;
  final String nama;
  final String nomorSeri;
  final String lokasi;

  const SpkAsetModel({
    this.id,
    required this.kodeAset,
    required this.nama,
    required this.nomorSeri,
    required this.lokasi,
  });

  factory SpkAsetModel.fromJson(Map<String, dynamic> json) {
    return SpkAsetModel(
      id: json['id'] is int ? json['id'] as int : null,
      kodeAset: json['kode_aset']?.toString() ?? '-',
      nama: json['nama']?.toString() ?? 'Sarana / Aset',
      nomorSeri: json['nomor_seri']?.toString() ?? '-',
      lokasi: json['lokasi']?.toString() ?? json['unit']?.toString() ?? '-',
    );
  }
}

class SpkTiketModel {
  final int? id;
  final String kode;
  final String prioritas; // 'RENDAH', 'SEDANG', 'TINGGI', 'CITO'
  final String? status;
  final String deskripsiMasalah;
  final String? fotoUrl;
  final String? pelapor;

  const SpkTiketModel({
    this.id,
    required this.kode,
    required this.prioritas,
    this.status,
    required this.deskripsiMasalah,
    this.fotoUrl,
    this.pelapor,
  });

  bool get isCito => prioritas.toUpperCase() == 'CITO';
  bool get isTinggi => prioritas.toUpperCase() == 'TINGGI';

  factory SpkTiketModel.fromJson(Map<String, dynamic> json) {
    return SpkTiketModel(
      id: json['id'] is int ? json['id'] as int : null,
      kode: json['kode']?.toString() ?? 'MNT',
      prioritas: json['prioritas']?.toString() ?? 'SEDANG',
      status: json['status']?.toString(),
      deskripsiMasalah: json['deskripsi_masalah']?.toString() ?? '',
      fotoUrl: json['foto_url']?.toString(),
      pelapor: json['pelapor']?.toString(),
    );
  }
}

class SpkHeaderModel {
  final int id;
  final String kodeSpk;
  final String status; // 'DITUGASKAN', 'DITERIMA', 'SELESAI', 'DIBATALKAN'
  final String? tanggalPenugasan;
  final String? targetSelesai;
  final String? instruksiKhusus;
  final String teknisi;
  final SpkTiketModel tiket;
  final SpkAsetModel aset;

  const SpkHeaderModel({
    required this.id,
    required this.kodeSpk,
    required this.status,
    this.tanggalPenugasan,
    this.targetSelesai,
    this.instruksiKhusus,
    required this.teknisi,
    required this.tiket,
    required this.aset,
  });

  bool get isSelesai => status.toUpperCase() == 'SELESAI';

  factory SpkHeaderModel.fromJson(Map<String, dynamic> json) {
    return SpkHeaderModel(
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
    );
  }
}
