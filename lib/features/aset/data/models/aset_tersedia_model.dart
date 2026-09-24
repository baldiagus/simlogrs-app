class AsetTersediaModel {
  final int id;
  final String kodeAset;
  final String nomorSeri;
  final String namaKomoditas;
  final String? spesifikasi;
  final String kategori;
  final String satuan;
  final String merek;
  final String kondisi;
  final String tipePenyedia; // 'RUANGAN' atau 'GUDANG'
  final int? penyediaId;
  final String namaPenyedia;
  final String lokasiLengkap;

  const AsetTersediaModel({
    required this.id,
    required this.kodeAset,
    required this.nomorSeri,
    required this.namaKomoditas,
    this.spesifikasi,
    required this.kategori,
    required this.satuan,
    required this.merek,
    required this.kondisi,
    required this.tipePenyedia,
    this.penyediaId,
    required this.namaPenyedia,
    required this.lokasiLengkap,
  });

  bool get isGudang => tipePenyedia.toUpperCase() == 'GUDANG';
  bool get isRuangan => tipePenyedia.toUpperCase() == 'RUANGAN';

  factory AsetTersediaModel.fromJson(Map<String, dynamic> json) {
    return AsetTersediaModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kodeAset: json['kode_aset']?.toString() ?? '',
      nomorSeri: json['nomor_seri']?.toString() ?? '-',
      namaKomoditas: json['nama_komoditas']?.toString() ?? 'Aset Fisik',
      spesifikasi: json['spesifikasi']?.toString(),
      kategori: json['kategori']?.toString() ?? 'Umum',
      satuan: json['satuan']?.toString() ?? 'Unit',
      merek: json['merek']?.toString() ?? '-',
      kondisi: json['kondisi']?.toString() ?? 'BAIK',
      tipePenyedia: json['tipe_penyedia']?.toString() ?? 'GUDANG',
      penyediaId: json['penyedia_id'] is int ? json['penyedia_id'] as int : null,
      namaPenyedia: json['nama_penyedia']?.toString() ?? '-',
      lokasiLengkap: json['lokasi_lengkap']?.toString() ?? '-',
    );
  }
}
