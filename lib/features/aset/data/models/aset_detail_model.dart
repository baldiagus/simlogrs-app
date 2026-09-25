class PeminjamanAktifInfo {
  final int peminjamanId;
  final String kodePinjam;
  final String unitPeminjam;
  final String? tanggalPinjam;
  final String? tanggalKembaliRencana;
  final bool isOverdue;

  const PeminjamanAktifInfo({
    required this.peminjamanId,
    required this.kodePinjam,
    required this.unitPeminjam,
    this.tanggalPinjam,
    this.tanggalKembaliRencana,
    required this.isOverdue,
  });

  factory PeminjamanAktifInfo.fromJson(Map<String, dynamic> json) {
    return PeminjamanAktifInfo(
      peminjamanId: json['peminjaman_id'] is int
          ? json['peminjaman_id'] as int
          : int.parse(json['peminjaman_id'].toString()),
      kodePinjam: json['kode_pinjam']?.toString() ?? '',
      unitPeminjam: json['unit_peminjam']?.toString() ?? 'Unit Peminjam',
      tanggalPinjam: json['tanggal_pinjam']?.toString(),
      tanggalKembaliRencana: json['tanggal_kembali_rencana']?.toString(),
      isOverdue: json['is_overdue'] == true,
    );
  }
}

class ServisTerakhirInfo {
  final String kode;
  final String status;
  final String prioritas;
  final String deskripsi;
  final String tanggalPengajuan;

  const ServisTerakhirInfo({
    required this.kode,
    required this.status,
    required this.prioritas,
    required this.deskripsi,
    required this.tanggalPengajuan,
  });

  factory ServisTerakhirInfo.fromJson(Map<String, dynamic> json) {
    return ServisTerakhirInfo(
      kode: json['kode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'MENUNGGU_SPK',
      prioritas: json['prioritas']?.toString() ?? 'SEDANG',
      deskripsi: json['deskripsi']?.toString() ?? '-',
      tanggalPengajuan: json['tanggal_pengajuan']?.toString() ?? '-',
    );
  }
}

class AsetDetailModel {
  final int id;
  final String kodeAset;
  final String nomorSeri;
  final String namaKomoditas;
  final String kategori;
  final String merek;
  final String spesifikasi;
  final String status; // 'TERSEDIA', 'DIPINJAM', 'DALAM_MAINTENANCE', 'RUSAK'
  final String kondisi; // 'BAIK', 'RUSAK_RINGAN', 'RUSAK_BERAT'
  final String lokasiTercatat;
  final String penanggungJawab;
  final double nilaiPerolehan;
  final String tanggalPerolehan;
  final int totalRiwayatServis;
  final ServisTerakhirInfo? servisTerakhir;
  final PeminjamanAktifInfo? peminjamanAktif;

  const AsetDetailModel({
    required this.id,
    required this.kodeAset,
    required this.nomorSeri,
    required this.namaKomoditas,
    required this.kategori,
    required this.merek,
    required this.spesifikasi,
    required this.status,
    required this.kondisi,
    required this.lokasiTercatat,
    required this.penanggungJawab,
    required this.nilaiPerolehan,
    required this.tanggalPerolehan,
    required this.totalRiwayatServis,
    this.servisTerakhir,
    this.peminjamanAktif,
  });

  bool get isTersedia => status.toUpperCase() == 'TERSEDIA';
  bool get isDipinjam => status.toUpperCase() == 'DIPINJAM';
  bool get isMaintenance => status.toUpperCase() == 'DALAM_MAINTENANCE';
  bool get isRusak => status.toUpperCase() == 'RUSAK' || kondisi.toUpperCase().contains('RUSAK');

  factory AsetDetailModel.fromJson(Map<String, dynamic> json) {
    return AsetDetailModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kodeAset: json['kode_aset']?.toString() ?? '',
      nomorSeri: json['nomor_seri']?.toString() ?? '-',
      namaKomoditas: json['nama_komoditas']?.toString() ?? 'Aset Fisik',
      kategori: json['kategori']?.toString() ?? 'Umum',
      merek: json['merek']?.toString() ?? '-',
      spesifikasi: json['spesifikasi']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'TERSEDIA',
      kondisi: json['kondisi']?.toString() ?? 'BAIK',
      lokasiTercatat: json['lokasi_tercatat']?.toString() ?? '-',
      penanggungJawab: json['penanggung_jawab']?.toString() ?? '-',
      nilaiPerolehan: double.tryParse(json['nilai_perolehan']?.toString() ?? '0') ?? 0,
      tanggalPerolehan: json['tanggal_perolehan']?.toString() ?? '-',
      totalRiwayatServis: int.tryParse(json['total_riwayat_servis']?.toString() ?? '0') ?? 0,
      servisTerakhir: json['servis_terakhir'] is Map<String, dynamic>
          ? ServisTerakhirInfo.fromJson(json['servis_terakhir'] as Map<String, dynamic>)
          : null,
      peminjamanAktif: json['peminjaman_aktif'] is Map<String, dynamic>
          ? PeminjamanAktifInfo.fromJson(json['peminjaman_aktif'] as Map<String, dynamic>)
          : null,
    );
  }
}
