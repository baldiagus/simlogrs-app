import 'dart:convert';

/// Model representasi data payload notifikasi SIMLOG RS.
class NotificationPayload {
  /// Tipe notifikasi, misal APPROVAL_PR, APPROVAL_AMPRAH, atau TIKET_SPK.
  final String tipe;

  /// ID referensi transaksi atau entitas terkait.
  final String? referensiId;

  /// Judul pesan notifikasi.
  final String judul;

  /// Isi atau teks deskripsi notifikasi.
  final String pesan;

  /// Waktu pembuatan atau penerimaan notifikasi.
  final DateTime timestamp;

  /// Membuat instans payload notifikasi.
  const NotificationPayload({
    required this.tipe,
    this.referensiId,
    required this.judul,
    required this.pesan,
    required this.timestamp,
  });

  /// Menandakan apakah notifikasi bertipe persetujuan (approval).
  bool get isApproval => tipe.trim().toUpperCase().startsWith('APPROVAL');

  /// Membuat instans [NotificationPayload] dari objek map.
  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    DateTime parsedTimestamp;
    final rawTimestamp = map['timestamp'];
    if (rawTimestamp is DateTime) {
      parsedTimestamp = rawTimestamp;
    } else if (rawTimestamp is String) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else if (rawTimestamp is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else {
      parsedTimestamp = DateTime.now();
    }

    return NotificationPayload(
      tipe: map['tipe']?.toString() ?? map['type']?.toString() ?? '',
      referensiId: map['referensi_id']?.toString() ??
          map['referensiId']?.toString() ??
          map['reference_id']?.toString(),
      judul: map['judul']?.toString() ?? map['title']?.toString() ?? '',
      pesan: map['pesan']?.toString() ??
          map['body']?.toString() ??
          map['message']?.toString() ??
          '',
      timestamp: parsedTimestamp,
    );
  }

  /// Mengubah [NotificationPayload] menjadi bentuk map.
  Map<String, dynamic> toMap() {
    return {
      'tipe': tipe,
      'referensi_id': referensiId,
      'judul': judul,
      'pesan': pesan,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Mengonversi payload menjadi teks JSON.
  String toJson() => jsonEncode(toMap());

  /// Membuat [NotificationPayload] dari teks representasi JSON.
  factory NotificationPayload.fromJson(String source) =>
      NotificationPayload.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Membandingkan kesamaan atribut antardua instans [NotificationPayload].
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPayload &&
          runtimeType == other.runtimeType &&
          tipe == other.tipe &&
          referensiId == other.referensiId &&
          judul == other.judul &&
          pesan == other.pesan &&
          timestamp == other.timestamp;

  /// Menghasilkan kode hash unik untuk instans [NotificationPayload].
  @override
  int get hashCode =>
      tipe.hashCode ^
      referensiId.hashCode ^
      judul.hashCode ^
      pesan.hashCode ^
      timestamp.hashCode;

  /// Menghasilkan representasi string deskriptif [NotificationPayload].
  @override
  String toString() =>
      'NotificationPayload(tipe: $tipe, referensiId: $referensiId, judul: $judul, pesan: $pesan, timestamp: $timestamp)';
}
