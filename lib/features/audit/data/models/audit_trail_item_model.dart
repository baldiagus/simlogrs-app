class AuditTrailItemModel {
  final int id;
  final String penggunaNama;
  final String penggunaNip;
  final String peran;
  final String aksi;
  final String referensiJenis;
  final int referensiId;
  final String ipAddress;
  final String device;
  final String waktu;
  final String timestamp;
  final bool hasDataSebelum;
  final bool hasDataSesudah;
  final Map<String, dynamic>? dataSebelum;
  final Map<String, dynamic>? dataSesudah;

  const AuditTrailItemModel({
    required this.id,
    required this.penggunaNama,
    required this.penggunaNip,
    required this.peran,
    required this.aksi,
    required this.referensiJenis,
    required this.referensiId,
    required this.ipAddress,
    required this.device,
    required this.waktu,
    required this.timestamp,
    required this.hasDataSebelum,
    required this.hasDataSesudah,
    this.dataSebelum,
    this.dataSesudah,
  });

  factory AuditTrailItemModel.fromJson(Map<String, dynamic> json) {
    return AuditTrailItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      penggunaNama: json['pengguna_nama']?.toString() ?? 'Sistem',
      penggunaNip: json['pengguna_nip']?.toString() ?? '-',
      peran: json['peran']?.toString() ?? '-',
      aksi: json['aksi']?.toString() ?? 'AKSI',
      referensiJenis: json['referensi_jenis']?.toString() ?? 'Data',
      referensiId: (json['referensi_id'] as num?)?.toInt() ?? 0,
      ipAddress: json['ip_address']?.toString() ?? '-',
      device: json['device']?.toString() ?? '-',
      waktu: json['waktu']?.toString() ?? '-',
      timestamp: json['timestamp']?.toString() ?? '',
      hasDataSebelum: json['has_data_sebelum'] == true,
      hasDataSesudah: json['has_data_sesudah'] == true,
      dataSebelum: json['data_sebelum'] is Map<String, dynamic>
          ? json['data_sebelum'] as Map<String, dynamic>
          : null,
      dataSesudah: json['data_sesudah'] is Map<String, dynamic>
          ? json['data_sesudah'] as Map<String, dynamic>
          : null,
    );
  }
}
