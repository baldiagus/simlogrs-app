class RekamMedisSukuCadangModel {
  final String namaBarang;
  final String nomorBatch;
  final int jumlah;

  const RekamMedisSukuCadangModel({
    required this.namaBarang,
    required this.nomorBatch,
    required this.jumlah,
  });

  factory RekamMedisSukuCadangModel.fromJson(Map<String, dynamic> json) {
    return RekamMedisSukuCadangModel(
      namaBarang: json['nama_barang']?.toString() ?? 'Suku Cadang',
      nomorBatch: json['nomor_batch']?.toString() ?? '-',
      jumlah: int.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
    );
  }
}

class RekamMedisServisEntryModel {
  final int id;
  final String kodeTiket;
  final String tanggalLapor;
  final String pelapor;
  final String deskripsiMasalah;
  final String prioritas;
  final String statusTiket;
  final String kodeSpk;
  final String teknisi;
  final String tanggalPenugasan;
  final String statusSpk;
  final String diagnosa;
  final String tindakan;
  final String hasilPengerjaan;
  final String tanggalSelesai;
  final List<RekamMedisSukuCadangModel> sukuCadang;

  const RekamMedisServisEntryModel({
    required this.id,
    required this.kodeTiket,
    required this.tanggalLapor,
    required this.pelapor,
    required this.deskripsiMasalah,
    required this.prioritas,
    required this.statusTiket,
    required this.kodeSpk,
    required this.teknisi,
    required this.tanggalPenugasan,
    required this.statusSpk,
    required this.diagnosa,
    required this.tindakan,
    required this.hasilPengerjaan,
    required this.tanggalSelesai,
    required this.sukuCadang,
  });

  factory RekamMedisServisEntryModel.fromJson(Map<String, dynamic> json) {
    final sc = (json['suku_cadang'] as List<dynamic>?)
            ?.map((e) => RekamMedisSukuCadangModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return RekamMedisServisEntryModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kodeTiket: json['kode_tiket']?.toString() ?? '-',
      tanggalLapor: json['tanggal_lapor']?.toString() ?? '-',
      pelapor: json['pelapor']?.toString() ?? 'Staf',
      deskripsiMasalah: json['deskripsi_masalah']?.toString() ?? '-',
      prioritas: json['prioritas']?.toString() ?? 'SEDANG',
      statusTiket: json['status_tiket']?.toString() ?? '-',
      kodeSpk: json['kode_spk']?.toString() ?? '-',
      teknisi: json['teknisi']?.toString() ?? '-',
      tanggalPenugasan: json['tanggal_penugasan']?.toString() ?? '-',
      statusSpk: json['status_spk']?.toString() ?? '-',
      diagnosa: json['diagnosa']?.toString() ?? '-',
      tindakan: json['tindakan']?.toString() ?? '-',
      hasilPengerjaan: json['hasil_pengerjaan']?.toString() ?? '-',
      tanggalSelesai: json['tanggal_selesai']?.toString() ?? '-',
      sukuCadang: sc,
    );
  }
}

class RekamMedisAsetKatalogModel {
  final int id;
  final String kodeAset;
  final String nomorSeri;
  final String namaSarana;
  final String kategori;
  final String merek;
  final String kondisi;
  final String status;
  final String lokasi;
  final int totalServis;

  const RekamMedisAsetKatalogModel({
    required this.id,
    required this.kodeAset,
    required this.nomorSeri,
    required this.namaSarana,
    required this.kategori,
    required this.merek,
    required this.kondisi,
    required this.status,
    required this.lokasi,
    required this.totalServis,
  });

  factory RekamMedisAsetKatalogModel.fromJson(Map<String, dynamic> json) {
    return RekamMedisAsetKatalogModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kodeAset: json['kode_aset']?.toString() ?? '-',
      nomorSeri: json['nomor_seri']?.toString() ?? '-',
      namaSarana: json['nama_sarana']?.toString() ?? 'Sarana Fisik',
      kategori: json['kategori']?.toString() ?? 'Umum',
      merek: json['merek']?.toString() ?? '-',
      kondisi: json['kondisi']?.toString() ?? 'BAIK',
      status: json['status']?.toString() ?? 'TERSEDIA',
      lokasi: json['lokasi']?.toString() ?? '-',
      totalServis: int.tryParse(json['total_servis']?.toString() ?? '0') ?? 0,
    );
  }
}

class RekamMedisDetailResponse {
  final Map<String, dynamic> identitas;
  final List<RekamMedisServisEntryModel> riwayatServis;
  final List<Map<String, dynamic>> jadwalPreventif;

  const RekamMedisDetailResponse({
    required this.identitas,
    required this.riwayatServis,
    required this.jadwalPreventif,
  });

  factory RekamMedisDetailResponse.fromJson(Map<String, dynamic> json) {
    final rs = (json['riwayat_servis'] as List<dynamic>?)
            ?.map((e) => RekamMedisServisEntryModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final jp = (json['jadwal_preventif'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    return RekamMedisDetailResponse(
      identitas: json['identitas'] as Map<String, dynamic>? ?? {},
      riwayatServis: rs,
      jadwalPreventif: jp,
    );
  }
}
