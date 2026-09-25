class BukuMutasiItemModel {
  final int id;
  final String tanggal;
  final String jenis; // MASUK, KELUAR, PENYESUAIAN, TRANSFER
  final int barangId;
  final String kodeBarang;
  final String namaBarang;
  final String satuan;
  final String nomorBatch;
  final String gudang;
  final String lokasiRak;
  final int jumlah;
  final int saldoSebelum;
  final int saldoSesudah;
  final String? referensiJenis;
  final int? referensiId;
  final String keterangan;
  final String petugas;

  const BukuMutasiItemModel({
    required this.id,
    required this.tanggal,
    required this.jenis,
    required this.barangId,
    required this.kodeBarang,
    required this.namaBarang,
    required this.satuan,
    required this.nomorBatch,
    required this.gudang,
    required this.lokasiRak,
    required this.jumlah,
    required this.saldoSebelum,
    required this.saldoSesudah,
    this.referensiJenis,
    this.referensiId,
    required this.keterangan,
    required this.petugas,
  });

  bool get isMasuk => jenis == 'MASUK' || (jenis == 'PENYESUAIAN' && saldoSesudah > saldoSebelum);

  factory BukuMutasiItemModel.fromJson(Map<String, dynamic> json) {
    return BukuMutasiItemModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      tanggal: json['tanggal']?.toString() ?? '-',
      jenis: json['jenis']?.toString() ?? 'MUTASI',
      barangId: json['barang_id'] is int ? json['barang_id'] as int : int.parse(json['barang_id'].toString()),
      kodeBarang: json['kode_barang']?.toString() ?? '-',
      namaBarang: json['nama_barang']?.toString() ?? 'Komoditas',
      satuan: json['satuan']?.toString() ?? 'Pcs',
      nomorBatch: json['nomor_batch']?.toString() ?? '-',
      gudang: json['gudang']?.toString() ?? 'Gudang',
      lokasiRak: json['lokasi_rak']?.toString() ?? 'Tanpa Rak',
      jumlah: int.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
      saldoSebelum: int.tryParse(json['saldo_sebelum']?.toString() ?? '0') ?? 0,
      saldoSesudah: int.tryParse(json['saldo_sesudah']?.toString() ?? '0') ?? 0,
      referensiJenis: json['referensi_jenis']?.toString(),
      referensiId: json['referensi_id'] != null ? int.tryParse(json['referensi_id'].toString()) : null,
      keterangan: json['keterangan']?.toString() ?? '-',
      petugas: json['petugas']?.toString() ?? 'Sistem',
    );
  }
}
