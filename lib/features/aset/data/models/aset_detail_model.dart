/// Info peminjaman aktif yang sedang melekat pada sebuah aset (kode, peminjam, jadwal, status terlambat).
class PeminjamanAktifInfo {
  final int peminjamanId;
  final int? peminjamanDetailId;
  final String kodePinjam;
  final String unitPeminjam;
  final String? tanggalPinjam;
  final String? tanggalKembaliRencana;
  final bool isOverdue;
  /// Membuat info peminjaman aktif; [peminjamanDetailId], [tanggalPinjam], dan [tanggalKembaliRencana] opsional.
  const PeminjamanAktifInfo({
    required this.peminjamanId,
    this.peminjamanDetailId,
    required this.kodePinjam,
    required this.unitPeminjam,
    this.tanggalPinjam,
    this.tanggalKembaliRencana,
    required this.isOverdue,
  });

  /// Membuat [PeminjamanAktifInfo] dari JSON API dengan nilai default aman untuk field kosong.
  factory PeminjamanAktifInfo.fromJson(Map<String, dynamic> json) {
    return PeminjamanAktifInfo(
      peminjamanId: json['peminjaman_id'] is int
          ? json['peminjaman_id'] as int
          : int.parse(json['peminjaman_id'].toString()),
      peminjamanDetailId: json['peminjaman_detail_id'] != null
          ? int.tryParse(json['peminjaman_detail_id'].toString())
          : null,
      kodePinjam: json['kode_pinjam']?.toString() ?? '',
      unitPeminjam: json['unit_peminjam']?.toString() ?? 'Unit Peminjam',
      tanggalPinjam: json['tanggal_pinjam']?.toString(),
      tanggalKembaliRencana: json['tanggal_kembali_rencana']?.toString(),
      isOverdue: json['is_overdue'] == true,
    );
  }
}

/// Ringkasan servis terakhir aset (kode, status, prioritas, deskripsi, tanggal pengajuan).
class ServisTerakhirInfo {
  final String kode;
  final String status;
  final String prioritas;
  final String deskripsi;
  final String tanggalPengajuan;

  /// Membuat info servis terakhir dengan semua field wajib terisi.
  const ServisTerakhirInfo({
    required this.kode,
    required this.status,
    required this.prioritas,
    required this.deskripsi,
    required this.tanggalPengajuan,
  });

  /// Membuat [ServisTerakhirInfo] dari JSON API dengan default bila field kosong.
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

/// Satu baris riwayat peminjaman suatu aset, termasuk kondisi saat dipinjam dan dikembalikan.
class RiwayatPeminjamanAsetItemModel {
  final int id;
  final String kodePeminjaman;
  final String unitPeminjam;
  final String peminjam;
  final String tanggalPinjam;
  final String tanggalKembaliRencana;
  final String? tanggalKembaliAktual;
  final String status;
  final String keperluan;
  final String kondisiSaatPinjam;
  final String? kondisiSaatKembali;
  final String? catatanPengembalian;
  final String? pemeriksaKembali;

  /// Membuat item riwayat peminjaman; data pengembalian bersifat opsional karena bisa belum dikembalikan.
  const RiwayatPeminjamanAsetItemModel({
    required this.id,
    required this.kodePeminjaman,
    required this.unitPeminjam,
    required this.peminjam,
    required this.tanggalPinjam,
    required this.tanggalKembaliRencana,
    this.tanggalKembaliAktual,
    required this.status,
    required this.keperluan,
    required this.kondisiSaatPinjam,
    this.kondisiSaatKembali,
    this.catatanPengembalian,
    this.pemeriksaKembali,
  });

  /// Membuat [RiwayatPeminjamanAsetItemModel] dari JSON API dengan default bila field kosong.
  factory RiwayatPeminjamanAsetItemModel.fromJson(Map<String, dynamic> json) {
    return RiwayatPeminjamanAsetItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kodePeminjaman: json['kode_peminjaman']?.toString() ?? '-',
      unitPeminjam: json['unit_peminjam']?.toString() ?? 'Ruangan',
      peminjam: json['peminjam']?.toString() ?? '-',
      tanggalPinjam: json['tanggal_pinjam']?.toString() ?? '-',
      tanggalKembaliRencana: json['tanggal_kembali_rencana']?.toString() ?? '-',
      tanggalKembaliAktual: json['tanggal_kembali_aktual']?.toString(),
      status: json['status']?.toString() ?? '-',
      keperluan: json['keperluan']?.toString() ?? '-',
      kondisiSaatPinjam: json['kondisi_saat_pinjam']?.toString() ?? 'BAIK',
      kondisiSaatKembali: json['kondisi_saat_kembali']?.toString(),
      catatanPengembalian: json['catatan_pengembalian']?.toString(),
      pemeriksaKembali: json['pemeriksa_kembali']?.toString(),
    );
  }
}
/// Satu baris riwayat pengalihan suatu aset (asal, tujuan, tanggal, kondisi, pihak terkait).
class RiwayatPengalihanAsetItemModel {
  final int id;
  final int? pengalihanId;
  final String kodePengalihan;
  final String asalNama;
  final String tujuanNama;
  final String tanggalPengalihan;
  final String tanggalSerahTerima;
  final String status;
  final String alasan;
  final String kondisiSebelum;
  final String kondisiSaatDiterima;
  final String pengaju;
  final String penerima;
  final String? catatan;

  /// Membuat item riwayat pengalihan; [pengalihanId] dan [catatan] opsional.
  const RiwayatPengalihanAsetItemModel({
    required this.id,
    this.pengalihanId,
    required this.kodePengalihan,
    required this.asalNama,
    required this.tujuanNama,
    required this.tanggalPengalihan,
    required this.tanggalSerahTerima,
    required this.status,
    required this.alasan,
    required this.kondisiSebelum,
    required this.kondisiSaatDiterima,
    required this.pengaju,
    required this.penerima,
    this.catatan,
  });

  /// Membuat [RiwayatPengalihanAsetItemModel] dari JSON API dengan default bila field kosong.
  factory RiwayatPengalihanAsetItemModel.fromJson(Map<String, dynamic> json) {
    return RiwayatPengalihanAsetItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      pengalihanId: (json['pengalihan_id'] as num?)?.toInt(),
      kodePengalihan: json['kode_pengalihan']?.toString() ?? '-',
      asalNama: json['asal_nama']?.toString() ?? '-',
      tujuanNama: json['tujuan_nama']?.toString() ?? '-',
      tanggalPengalihan: json['tanggal_pengalihan']?.toString() ?? '-',
      tanggalSerahTerima: json['tanggal_serah_terima']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'SELESAI',
      alasan: json['alasan']?.toString() ?? '-',
      kondisiSebelum: json['kondisi_sebelum']?.toString() ?? 'BAIK',
      kondisiSaatDiterima: json['kondisi_saat_diterima']?.toString() ?? 'BAIK',
      pengaju: json['pengaju']?.toString() ?? '-',
      penerima: json['penerima']?.toString() ?? '-',
      catatan: json['catatan']?.toString(),
    );
  }
}

/// Detail lengkap aset fisik hasil scan/pencarian, termasuk riwayat servis, peminjaman, dan pengalihan.
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
  final int totalRiwayatPeminjaman;
  final ServisTerakhirInfo? servisTerakhir;
  final PeminjamanAktifInfo? peminjamanAktif;
  final List<RiwayatPeminjamanAsetItemModel> riwayatPeminjaman;
  final int totalRiwayatPengalihan;
  final List<RiwayatPengalihanAsetItemModel> riwayatPengalihan;
  final int? unitId;
  final int? gudangId;
  final String? tipePenyedia;
  final int? penyediaId;
  final String? namaPenyedia;
  final bool isSedangDiajukan;
  final String? statusSirkulasi;
  final Map<String, dynamic>? antreanPeminjaman;

  /// Membuat detail aset; field riwayat dan status sirkulasi punya nilai default kosong.
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
    this.totalRiwayatPeminjaman = 0,
    this.servisTerakhir,
    this.peminjamanAktif,
    this.riwayatPeminjaman = const [],
    this.totalRiwayatPengalihan = 0,
    this.riwayatPengalihan = const [],
    this.unitId,
    this.gudangId,
    this.tipePenyedia,
    this.penyediaId,
    this.namaPenyedia,
    this.isSedangDiajukan = false,
    this.statusSirkulasi,
    this.antreanPeminjaman,
  });

  /// True bila aset berstatus TERSEDIA (siap dipinjam).
  bool get isTersedia => status.toUpperCase() == 'TERSEDIA';
  /// True bila aset sedang berstatus DIPINJAM.
  bool get isDipinjam => status.toUpperCase() == 'DIPINJAM';
  /// True bila aset sedang DALAM_MAINTENANCE.
  bool get isMaintenance => status.toUpperCase() == 'DALAM_MAINTENANCE';
  /// True bila status RUSAK atau kondisi mengandung kata RUSAK.
  bool get isRusak => status.toUpperCase() == 'RUSAK' || kondisi.toUpperCase().contains('RUSAK');
  /// True bila aset sudah diajukan/disetujui untuk dipinjam atau punya antrean peminjaman, sehingga tidak bisa diajukan lagi.
  bool get isSedangDalamProsesPinjam =>
      isSedangDiajukan ||
      statusSirkulasi == 'DIAJUKAN' ||
      statusSirkulasi == 'DISETUJUI' ||
      antreanPeminjaman != null;
  /// Membuat [AsetDetailModel] dari JSON API, termasuk parsing objek bersarang dan daftar riwayat.
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
      totalRiwayatPeminjaman: int.tryParse(json['total_riwayat_peminjaman']?.toString() ?? '0') ?? 0,
      servisTerakhir: json['servis_terakhir'] is Map<String, dynamic>
          ? ServisTerakhirInfo.fromJson(json['servis_terakhir'] as Map<String, dynamic>)
          : null,
      peminjamanAktif: json['peminjaman_aktif'] is Map<String, dynamic>
          ? PeminjamanAktifInfo.fromJson(json['peminjaman_aktif'] as Map<String, dynamic>)
          : null,
      riwayatPeminjaman: (json['riwayat_peminjaman'] as List<dynamic>?)
              ?.map((e) => RiwayatPeminjamanAsetItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalRiwayatPengalihan: int.tryParse(json['total_riwayat_pengalihan']?.toString() ?? '0') ?? 0,
      riwayatPengalihan: (json['riwayat_pengalihan'] as List<dynamic>?)
              ?.map((e) => RiwayatPengalihanAsetItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      unitId: (json['unit_id'] as num?)?.toInt(),
      gudangId: (json['gudang_id'] as num?)?.toInt(),
      tipePenyedia: json['tipe_penyedia']?.toString(),
      penyediaId: (json['penyedia_id'] as num?)?.toInt(),
      namaPenyedia: json['nama_penyedia']?.toString(),
      isSedangDiajukan: json['is_sedang_diajukan'] == true,
      statusSirkulasi: json['status_sirkulasi']?.toString(),
      antreanPeminjaman: json['antrean_peminjaman'] is Map<String, dynamic>
          ? json['antrean_peminjaman'] as Map<String, dynamic>
          : null,
    );
  }
}
