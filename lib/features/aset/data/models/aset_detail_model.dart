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

class AsetDetailModel {
  final int id;
  final String kodeAset;
  final String nomorSeri;
  final String namaKomoditas;
  final String kategori;
  final String status; // 'TERSEDIA', 'DIPINJAM', 'DALAM_MAINTENANCE', 'RUSAK'
  final String kondisi; // 'BAIK', 'RUSAK_RINGAN', 'RUSAK_BERAT'
  final String lokasiTercatat;
  final String penanggungJawab;
  final PeminjamanAktifInfo? peminjamanAktif;

  const AsetDetailModel({
    required this.id,
    required this.kodeAset,
    required this.nomorSeri,
    required this.namaKomoditas,
    required this.kategori,
    required this.status,
    required this.kondisi,
    required this.lokasiTercatat,
    required this.penanggungJawab,
    this.peminjamanAktif,
  });

  bool get isTersedia => status.toUpperCase() == 'TERSEDIA';
  bool get isDipinjam => status.toUpperCase() == 'DIPINJAM';
  bool get isMaintenance => status.toUpperCase() == 'DALAM_MAINTENANCE';
  bool get isRusak => status.toUpperCase() == 'RUSAK';

  factory AsetDetailModel.fromJson(Map<String, dynamic> json) {
    return AsetDetailModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kodeAset: json['kode_aset']?.toString() ?? '',
      nomorSeri: json['nomor_seri']?.toString() ?? '-',
      namaKomoditas: json['nama_komoditas']?.toString() ?? 'Aset Fisik',
      kategori: json['kategori']?.toString() ?? 'Umum',
      status: json['status']?.toString() ?? 'TERSEDIA',
      kondisi: json['kondisi']?.toString() ?? 'BAIK',
      lokasiTercatat: json['lokasi_tercatat']?.toString() ?? '-',
      penanggungJawab: json['penanggung_jawab']?.toString() ?? '-',
      peminjamanAktif: json['peminjaman_aktif'] is Map<String, dynamic>
          ? PeminjamanAktifInfo.fromJson(json['peminjaman_aktif'] as Map<String, dynamic>)
          : null,
    );
  }
}
