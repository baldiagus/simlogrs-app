/// Satu entri notifikasi inbox sesuai kontrak `docs/NOTIFICATION_CONTRACT.md` bagian 2.
class NotifikasiModel {
  /// ID baris notifikasi di backend.
  final int id;

  /// Judul singkat notifikasi.
  final String judul;

  /// Isi pesan notifikasi.
  final String pesan;

  /// Kode tipe notifikasi (mis. `APPROVAL_PR`); baris lama tanpa tipe menjadi `UMUM`.
  final String tipe;

  /// ID dokumen yang dimaksud (string), bila ada.
  final String? referensiId;

  /// Tautan web terkait, bila ada.
  final String? tautan;

  /// True bila notifikasi sudah dibaca.
  final bool dibaca;

  /// Waktu notifikasi dibuat.
  final DateTime dibuatPada;

  /// Membuat instance [NotifikasiModel].
  const NotifikasiModel({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.tipe,
    required this.dibuatPada,
    this.referensiId,
    this.tautan,
    this.dibaca = false,
  });

  /// Membuat [NotifikasiModel] dari JSON; toleran terhadap field null, tipe angka/string, dan tanggal rusak.
  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    final tipe = json['tipe']?.toString().trim();
    final referensi = json['referensi_id']?.toString();
    final tautan = json['tautan']?.toString();
    return NotifikasiModel(
      id: _keInt(json['id']),
      judul: json['judul']?.toString() ?? '',
      pesan: json['pesan']?.toString() ?? '',
      tipe: (tipe == null || tipe.isEmpty) ? 'UMUM' : tipe,
      referensiId: (referensi == null || referensi.isEmpty) ? null : referensi,
      tautan: (tautan == null || tautan.isEmpty) ? null : tautan,
      dibaca: _keBool(json['dibaca']),
      dibuatPada: DateTime.tryParse(json['dibuat_pada']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Menyalin model dengan status [dibaca] baru.
  NotifikasiModel copyWith({bool? dibaca}) {
    return NotifikasiModel(
      id: id,
      judul: judul,
      pesan: pesan,
      tipe: tipe,
      referensiId: referensiId,
      tautan: tautan,
      dibaca: dibaca ?? this.dibaca,
      dibuatPada: dibuatPada,
    );
  }

  /// Mengubah nilai dinamis (angka/string) menjadi int, default 0.
  static int _keInt(Object? v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Mengubah nilai dinamis (bool/angka/string) menjadi bool, default false.
  static bool _keBool(Object? v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == '1' || s == 'true';
  }
}
