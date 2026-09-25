class JadwalPreventifItemModel {
  final int id;
  final String kode;
  final int asetId;
  final String kodeAset;
  final String nomorSeri;
  final String namaSarana;
  final String lokasi;
  final String jenisMaintenance;
  final int intervalNilai;
  final String intervalTipe;
  final String intervalLabel;
  final String tanggalTerakhir;
  final String tanggalBerikutnya;
  final int? sisaHari;
  final String statusJadwal; // OVERDUE, HARI_INI, MENDATANG, NONAKTIF
  final String statusAktif;
  final int? teknisiId;
  final String teknisiNama;
  final String catatan;

  const JadwalPreventifItemModel({
    required this.id,
    required this.kode,
    required this.asetId,
    required this.kodeAset,
    required this.nomorSeri,
    required this.namaSarana,
    required this.lokasi,
    required this.jenisMaintenance,
    required this.intervalNilai,
    required this.intervalTipe,
    required this.intervalLabel,
    required this.tanggalTerakhir,
    required this.tanggalBerikutnya,
    this.sisaHari,
    required this.statusJadwal,
    required this.statusAktif,
    this.teknisiId,
    required this.teknisiNama,
    required this.catatan,
  });

  bool get isOverdue => statusJadwal == 'OVERDUE';
  bool get isHariIni => statusJadwal == 'HARI_INI';

  factory JadwalPreventifItemModel.fromJson(Map<String, dynamic> json) {
    return JadwalPreventifItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kode: json['kode']?.toString() ?? '',
      asetId: json['aset_id'] is int ? json['aset_id'] as int : int.parse(json['aset_id'].toString()),
      kodeAset: json['kode_aset']?.toString() ?? '-',
      nomorSeri: json['nomor_seri']?.toString() ?? '-',
      namaSarana: json['nama_sarana']?.toString() ?? 'Sarana Medis/Non-Medis',
      lokasi: json['lokasi']?.toString() ?? '-',
      jenisMaintenance: json['jenis_maintenance']?.toString() ?? 'Servis Berkala',
      intervalNilai: int.tryParse(json['interval_nilai']?.toString() ?? '1') ?? 1,
      intervalTipe: json['interval_tipe']?.toString() ?? 'BULAN',
      intervalLabel: json['interval_label']?.toString() ?? 'Bulanan',
      tanggalTerakhir: json['tanggal_terakhir']?.toString() ?? '-',
      tanggalBerikutnya: json['tanggal_berikutnya']?.toString() ?? '-',
      sisaHari: json['sisa_hari'] != null ? int.tryParse(json['sisa_hari'].toString()) : null,
      statusJadwal: json['status_jadwal']?.toString() ?? 'MENDATANG',
      statusAktif: json['status_aktif']?.toString() ?? 'AKTIF',
      teknisiId: json['teknisi_id'] != null ? int.tryParse(json['teknisi_id'].toString()) : null,
      teknisiNama: json['teknisi_nama']?.toString() ?? 'Teknisi IPSRS',
      catatan: json['catatan']?.toString() ?? '-',
    );
  }
}
