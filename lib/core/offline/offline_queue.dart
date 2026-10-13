import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Satu mutasi yang menunggu dikirim ke server saat perangkat kembali online.
class OfflineMutation {
  /// Jenis mutasi untuk laporan cepat kerusakan.
  static const String jenisLaporCepat = 'lapor_cepat';

  /// Jenis mutasi untuk hasil hitung fisik stock opname.
  static const String jenisHitungFisik = 'hitung_fisik';

  final String id;
  final String jenis;
  final Map<String, dynamic> payload;
  final DateTime dibuat;
  final int percobaan;

  /// Membuat mutasi offline; [percobaan] menghitung berapa kali pengiriman gagal karena jaringan.
  const OfflineMutation({
    required this.id,
    required this.jenis,
    required this.payload,
    required this.dibuat,
    this.percobaan = 0,
  });

  /// Menyalin mutasi dengan [percobaan] yang diganti.
  OfflineMutation copyWith({int? percobaan}) => OfflineMutation(
        id: id,
        jenis: jenis,
        payload: payload,
        dibuat: dibuat,
        percobaan: percobaan ?? this.percobaan,
      );

  /// Mengubah mutasi menjadi JSON untuk disimpan di shared_preferences.
  Map<String, dynamic> toJson() => {
        'id': id,
        'jenis': jenis,
        'payload': payload,
        'dibuat': dibuat.toIso8601String(),
        'percobaan': percobaan,
      };

  /// Membangun mutasi dari JSON hasil [toJson].
  factory OfflineMutation.fromJson(Map<String, dynamic> json) => OfflineMutation(
        id: json['id'] as String,
        jenis: json['jenis'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        dibuat: DateTime.parse(json['dibuat'] as String),
        percobaan: (json['percobaan'] as num?)?.toInt() ?? 0,
      );
}

/// Antrean mutasi offline yang dipersistensikan sebagai daftar JSON di [SharedPreferences].
class OfflineQueue {
  /// Kunci penyimpanan daftar antrean di shared_preferences.
  static const String kunci = 'offline_queue_v1';
  static int _counter = 0;

  final SharedPreferences _prefs;

  /// Membuat antrean di atas [prefs]; instance berbeda dengan prefs sama berbagi data.
  OfflineQueue(this._prefs);

  /// Membuat ID unik sederhana dari timestamp mikrodetik ditambah penghitung.
  static String _buatId() => '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

  /// Membaca semua mutasi tersimpan; data rusak dianggap antrean kosong.
  List<OfflineMutation> _baca() {
    final raw = _prefs.getString(kunci);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => OfflineMutation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Menulis seluruh daftar mutasi ke penyimpanan.
  Future<void> _tulis(List<OfflineMutation> items) async {
    await _prefs.setString(kunci, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  /// Menambahkan mutasi baru berjenis [jenis] dengan [payload] dan mengembalikannya.
  Future<OfflineMutation> enqueue(String jenis, Map<String, dynamic> payload) async {
    final m = OfflineMutation(
      id: _buatId(),
      jenis: jenis,
      payload: payload,
      dibuat: DateTime.now(),
    );
    await _tulis([..._baca(), m]);
    return m;
  }

  /// Daftar mutasi terurut dari yang paling awal dibuat (FIFO).
  List<OfflineMutation> daftar() {
    final items = _baca();
    // Sort stabil: urutan simpan menjadi pemutus bila waktu dibuat sama.
    final indexed = items.asMap().entries.toList()
      ..sort((a, b) {
        final c = a.value.dibuat.compareTo(b.value.dibuat);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    return indexed.map((e) => e.value).toList();
  }

  /// Menghapus mutasi dengan [id]; tidak berefek bila tidak ada.
  Future<void> remove(String id) async {
    await _tulis(_baca().where((e) => e.id != id).toList());
  }

  /// Menambah hitungan percobaan mutasi dengan [id] setelah gagal karena jaringan.
  Future<void> tambahPercobaan(String id) async {
    await _tulis(_baca()
        .map((e) => e.id == id ? e.copyWith(percobaan: e.percobaan + 1) : e)
        .toList());
  }

  /// Jumlah mutasi yang menunggu dikirim.
  int get count => _baca().length;
}
