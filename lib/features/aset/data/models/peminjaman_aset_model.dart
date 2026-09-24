class PeminjamanItemAset {
  final int id;
  final int asetId;
  final String kodeAset;
  final String namaKomoditas;
  final String kondisiSaatPinjam;

  const PeminjamanItemAset({
    required this.id,
    required this.asetId,
    required this.kodeAset,
    required this.namaKomoditas,
    required this.kondisiSaatPinjam,
  });

  factory PeminjamanItemAset.fromJson(Map<String, dynamic> json) {
    return PeminjamanItemAset(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      asetId: json['aset_id'] is int
          ? json['aset_id'] as int
          : int.parse(json['aset_id'].toString()),
      kodeAset: json['kode_aset']?.toString() ?? '-',
      namaKomoditas: json['nama_komoditas']?.toString() ?? 'Aset Fisik',
      kondisiSaatPinjam: json['kondisi_saat_pinjam']?.toString() ?? 'BAIK',
    );
  }
}

class PeminjamanAsetModel {
  final int id;
  final String kode;
  final String tipePenyedia; // 'RUANGAN' atau 'GUDANG'
  final String namaPenyedia;
  final String unitPeminjam;
  final String pengaju;
  final String tanggalPinjam;
  final String tanggalKembaliRencana;
  final String keperluan;
  final String status; // 'DIAJUKAN', 'DISETUJUI', 'DIPINJAM', 'SELESAI', 'DITOLAK'
  final String? catatan;
  final bool isOverdue;
  final int jumlahAset;
  final Map<String, dynamic>? asetPreview;
  final List<PeminjamanItemAset> items;

  const PeminjamanAsetModel({
    required this.id,
    required this.kode,
    required this.tipePenyedia,
    required this.namaPenyedia,
    required this.unitPeminjam,
    required this.pengaju,
    required this.tanggalPinjam,
    required this.tanggalKembaliRencana,
    required this.keperluan,
    required this.status,
    this.catatan,
    required this.isOverdue,
    required this.jumlahAset,
    this.asetPreview,
    required this.items,
  });

  bool get isDiajukan => status.toUpperCase() == 'DIAJUKAN';
  bool get isDisetujui => status.toUpperCase() == 'DISETUJUI';
  bool get isDipinjam => status.toUpperCase() == 'DIPINJAM';
  bool get isSelesai => status.toUpperCase() == 'SELESAI';
  bool get isDitolak => status.toUpperCase() == 'DITOLAK';

  factory PeminjamanAsetModel.fromJson(Map<String, dynamic> json) {
    return PeminjamanAsetModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      tipePenyedia: json['tipe_penyedia']?.toString() ?? 'GUDANG',
      namaPenyedia: json['nama_penyedia']?.toString() ?? '-',
      unitPeminjam: json['unit_peminjam']?.toString() ?? '-',
      pengaju: json['pengaju']?.toString() ?? 'Staf',
      tanggalPinjam: json['tanggal_pinjam']?.toString() ?? '',
      tanggalKembaliRencana: json['tanggal_kembali_rencana']?.toString() ?? '',
      keperluan: json['keperluan']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DIAJUKAN',
      catatan: json['catatan']?.toString(),
      isOverdue: json['is_overdue'] == true,
      jumlahAset: json['jumlah_aset'] is int
          ? json['jumlah_aset'] as int
          : int.tryParse(json['jumlah_aset']?.toString() ?? '') ?? 1,
      asetPreview: json['aset_preview'] is Map<String, dynamic>
          ? json['aset_preview'] as Map<String, dynamic>
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PeminjamanItemAset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ApprovalPeminjamanModel {
  final int id;
  final String kode;
  final String tipePenyedia;
  final String unitPeminjam;
  final String pengaju;
  final String tanggalPinjam;
  final String tanggalKembaliRencana;
  final String keperluan;
  final String status;
  final String? catatan;
  final String namaAset;
  final String kodeAset;

  const ApprovalPeminjamanModel({
    required this.id,
    required this.kode,
    required this.tipePenyedia,
    required this.unitPeminjam,
    required this.pengaju,
    required this.tanggalPinjam,
    required this.tanggalKembaliRencana,
    required this.keperluan,
    required this.status,
    this.catatan,
    required this.namaAset,
    required this.kodeAset,
  });

  bool get isDiajukan => status.toUpperCase() == 'DIAJUKAN';
  bool get isDisetujui => status.toUpperCase() == 'DISETUJUI';

  factory ApprovalPeminjamanModel.fromJson(Map<String, dynamic> json) {
    return ApprovalPeminjamanModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      tipePenyedia: json['tipe_penyedia']?.toString() ?? 'GUDANG',
      unitPeminjam: json['unit_peminjam']?.toString() ?? '-',
      pengaju: json['pengaju']?.toString() ?? 'Staf',
      tanggalPinjam: json['tanggal_pinjam']?.toString() ?? '',
      tanggalKembaliRencana: json['tanggal_kembali_rencana']?.toString() ?? '',
      keperluan: json['keperluan']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DIAJUKAN',
      catatan: json['catatan']?.toString(),
      namaAset: json['nama_aset']?.toString() ?? 'Aset Fisik',
      kodeAset: json['kode_aset']?.toString() ?? '-',
    );
  }
}
