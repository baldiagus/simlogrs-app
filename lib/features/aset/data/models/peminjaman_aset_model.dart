/// Satu aset fisik di dalam sebuah peminjaman beserta kondisinya saat dipinjam.
class PeminjamanItemAset {
  final int id;
  final int asetId;
  final String kodeAset;
  final String namaKomoditas;
  final String kondisiSaatPinjam;

  /// Membuat item aset peminjaman dengan semua field wajib terisi.
  const PeminjamanItemAset({
    required this.id,
    required this.asetId,
    required this.kodeAset,
    required this.namaKomoditas,
    required this.kondisiSaatPinjam,
  });

  /// Membuat [PeminjamanItemAset] dari JSON API dengan default bila field kosong.
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

/// Data peminjaman aset (daftar peminjam/penyedia): jadwal, status, jumlah aset, dan item-itemnya.
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
  final int? diajukanOleh;
  final bool canCancel;

  /// Membuat model peminjaman aset; [catatan] dan [asetPreview] opsional.
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
    this.diajukanOleh,
    this.canCancel = false,
  });

  /// True bila status peminjaman DIAJUKAN (menunggu persetujuan).
  bool get isDiajukan => status.toUpperCase() == 'DIAJUKAN';
  /// True bila status peminjaman DISETUJUI (menunggu serah terima).
  bool get isDisetujui => status.toUpperCase() == 'DISETUJUI';
  /// True bila status peminjaman DIPINJAM (aset sedang dipinjam).
  bool get isDipinjam => status.toUpperCase() == 'DIPINJAM';
  /// True bila status peminjaman SELESAI (aset sudah dikembalikan).
  bool get isSelesai => status.toUpperCase() == 'SELESAI';
  /// True bila status peminjaman DITOLAK.
  bool get isDitolak => status.toUpperCase() == 'DITOLAK';
  /// True bila status peminjaman DIBATALKAN.
  bool get isDibatalkan => status.toUpperCase() == 'DIBATALKAN';

  /// Membuat [PeminjamanAsetModel] dari JSON API dengan default bila field kosong, termasuk daftar item.
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
      diajukanOleh: json['diajukan_oleh'] is int
          ? json['diajukan_oleh'] as int
          : int.tryParse(json['diajukan_oleh']?.toString() ?? ''),
      canCancel: json['can_cancel'] == true,
    );
  }
}

/// Data peminjaman yang perlu diproses penyetuju (antrean approval), dengan ringkasan aset yang diminta.
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

  /// Membuat model approval peminjaman; [catatan] opsional.
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

  /// True bila status DIAJUKAN (perlu disetujui/ditolak).
  bool get isDiajukan => status.toUpperCase() == 'DIAJUKAN';
  /// True bila status DISETUJUI (siap diserahterimakan).
  bool get isDisetujui => status.toUpperCase() == 'DISETUJUI';

  /// Membuat [ApprovalPeminjamanModel] dari JSON API dengan default bila field kosong.
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
