class RegisterAsetItemModel {
  final int id;
  final String kodeAset;
  final String nomorSeri;
  final String namaKomoditas;
  final String kategori;
  final String merek;
  final String lokasiTipe; // 'RUANGAN' atau 'GUDANG'
  final String lokasiNama;
  final String kondisi; // 'BAIK', 'RUSAK_RINGAN', 'RUSAK_BERAT'
  final String status; // 'TERSEDIA', 'DIGUNAKAN', 'DIPINJAM', 'DALAM_MAINTENANCE', 'DIHAPUSKAN'
  final String tanggalPerolehan;
  final double nilaiPerolehan;

  const RegisterAsetItemModel({
    required this.id,
    required this.kodeAset,
    required this.nomorSeri,
    required this.namaKomoditas,
    required this.kategori,
    required this.merek,
    required this.lokasiTipe,
    required this.lokasiNama,
    required this.kondisi,
    required this.status,
    required this.tanggalPerolehan,
    required this.nilaiPerolehan,
  });

  bool get isTersedia => status.toUpperCase() == 'TERSEDIA';
  bool get isDipinjam => status.toUpperCase() == 'DIPINJAM';
  bool get isMaintenance => status.toUpperCase() == 'DALAM_MAINTENANCE';

  factory RegisterAsetItemModel.fromJson(Map<String, dynamic> json) {
    return RegisterAsetItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      kodeAset: json['kode_aset']?.toString() ?? '',
      nomorSeri: json['nomor_seri']?.toString() ?? '-',
      namaKomoditas: json['nama_komoditas']?.toString() ?? 'Aset Fisik',
      kategori: json['kategori']?.toString() ?? 'Umum',
      merek: json['merek']?.toString() ?? '-',
      lokasiTipe: json['lokasi_tipe']?.toString() ?? 'RUANGAN',
      lokasiNama: json['lokasi_nama']?.toString() ?? '-',
      kondisi: json['kondisi']?.toString() ?? 'BAIK',
      status: json['status']?.toString() ?? 'TERSEDIA',
      tanggalPerolehan: json['tanggal_perolehan']?.toString() ?? '-',
      nilaiPerolehan: double.tryParse(json['nilai_perolehan']?.toString() ?? '0') ?? 0,
    );
  }
}
