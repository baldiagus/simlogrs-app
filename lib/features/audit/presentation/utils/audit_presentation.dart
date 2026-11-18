/// Presentation-only labels. Unknown codes stay available in technical details;
/// they are never converted into an assumed business meaning.
class AuditPresentation {
  AuditPresentation._();

  static const _actions = {
    'TAMBAH': 'Ditambahkan',
    'UBAH': 'Diubah',
    'HAPUS': 'Dihapus',
    'APPROVE': 'Disetujui',
    'REJECT': 'Ditolak',
    'ADJUSTMENT': 'Penyesuaian Stok',
  };
  static const _entities = {
    'PermintaanPeminjaman': 'Peminjaman aset',
    'Barang': 'Barang',
    'Aset': 'Aset',
    'PermintaanPengadaan': 'Permintaan pengadaan',
    'PurchaseOrder': 'Pesanan pembelian',
    'StockOpname': 'Opname stok',
    'PenyesuaianStok': 'Penyesuaian stok',
    'TemuanCapa': 'Temuan CAPA',
  };
  static const _roles = {
    'super_admin': 'Super Admin',
    'admin_logistik': 'Admin Logistik',
    'kepala_gudang': 'Kepala Gudang',
    'petugas_gudang': 'Petugas Gudang',
    'kepala_unit': 'Kepala Unit',
    'kepala_teknisi': 'Kepala Teknisi',
    'teknisi': 'Teknisi',
    'auditor': 'Auditor',
    'manajemen': 'Manajemen',
    'pengadaan': 'Pengadaan',
  };
  static const _fields = {
    'id': 'Nomor referensi',
    'status': 'Status',
    'nama': 'Nama',
    'nama_barang': 'Nama barang',
    'nama_aset': 'Nama aset',
    'jumlah': 'Jumlah',
    'qty': 'Jumlah',
    'stok': 'Stok',
    'satuan': 'Satuan',
    'catatan': 'Catatan',
    'keterangan': 'Keterangan',
    'alasan': 'Alasan',
    'aktif': 'Aktif',
    'is_active': 'Aktif',
    'tanggal': 'Tanggal',
    'tanggal_pinjam': 'Tanggal pinjam',
    'tanggal_kembali': 'Tanggal kembali',
    'tanggal_pengembalian': 'Tanggal pengembalian',
    'lokasi': 'Lokasi',
    'lokasi_id': 'Nomor referensi lokasi',
    'barang_id': 'Nomor referensi barang',
    'aset_id': 'Nomor referensi aset',
    'pengguna_id': 'Nomor referensi pengguna',
    'unit_id': 'Nomor referensi unit',
    'no_batch': 'Nomor batch',
    'nomor_batch': 'Nomor batch',
    'created_at': 'Waktu dibuat',
    'updated_at': 'Waktu diperbarui',
    'deleted_at': 'Waktu dihapus',
    'details': 'Rincian',
    'detail': 'Rincian',
    'items': 'Daftar',
  };
  static const _loanStatuses = {
    'DIAJUKAN': 'Diajukan',
    'DISETUJUI': 'Disetujui',
    'DIPINJAM': 'Dipinjam',
    'SELESAI': 'Selesai',
    'DITOLAK': 'Ditolak',
  };
  static const _assetStatuses = {
    'TERSEDIA': 'Tersedia',
    'DIPINJAM': 'Dipinjam',
    'DALAM_MAINTENANCE': 'Dalam pemeliharaan',
    'RUSAK': 'Rusak',
  };

  static String action(String code) => _actions[code] ?? 'Aktivitas lainnya';
  static String entity(String code) => _entities[code] ?? 'Objek lainnya';
  static String role(String code) => _roles[code] ?? 'Peran lainnya';
  static String field(String code) => _fields[code] ?? 'Bidang tambahan';
  static bool knownField(String code) => _fields.containsKey(code);

  /// Formats scalars only. Containers are rendered recursively by the sheet.
  static String value(
    Object? value, {
    String? entity,
    String? field,
    bool technical = false,
  }) {
    if (value == null) return 'Tidak diisi (null)';
    if (value is String && value.isEmpty) return 'Teks kosong';
    if (value is Map) return value.isEmpty ? 'Objek kosong' : 'Objek';
    if (value is List) return value.isEmpty ? 'Daftar kosong' : 'Daftar';
    if (technical) return value.toString();
    if (field != null && !knownField(field)) {
      return 'Nilai tersedia di informasi teknis';
    }
    if (field == 'status' && value is String) {
      final labels = switch (entity) {
        'PermintaanPeminjaman' => _loanStatuses,
        'Aset' => _assetStatuses,
        _ => const <String, String>{},
      };
      return labels[value] ?? 'Nilai lain (lihat informasi teknis)';
    }
    if (value is bool) return value ? 'Ya (true)' : 'Tidak (false)';
    return value.toString();
  }

  /// Missing keys are distinct from present nulls. Maps compare by key, lists
  /// by recorded position (not guessed IDs); only changed leaves are returned.
  static List<AuditFieldChange> changes(
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  ) {
    final result = <AuditFieldChange>[];
    _compare(
      const [],
      AuditRecordedValue(before != null, before),
      AuditRecordedValue(after != null, after),
      result,
    );
    return result;
  }

  static void _compare(
    List<Object> path,
    AuditRecordedValue before,
    AuditRecordedValue after,
    List<AuditFieldChange> result,
  ) {
    if (before.present == after.present && _equal(before.value, after.value)) {
      return;
    }
    final oldValue = before.value;
    final newValue = after.value;
    if ((oldValue is Map && newValue is Map) ||
        (!before.present && newValue is Map && newValue.isNotEmpty) ||
        (!after.present && oldValue is Map && oldValue.isNotEmpty)) {
      final oldMap = oldValue is Map ? oldValue : const {};
      final newMap = newValue is Map ? newValue : const {};
      for (final key in {...oldMap.keys, ...newMap.keys}) {
        _compare(
          [...path, key as String],
          AuditRecordedValue(oldMap.containsKey(key), oldMap[key]),
          AuditRecordedValue(newMap.containsKey(key), newMap[key]),
          result,
        );
      }
      return;
    }
    if ((oldValue is List && newValue is List) ||
        (!before.present && newValue is List && newValue.isNotEmpty) ||
        (!after.present && oldValue is List && oldValue.isNotEmpty)) {
      final oldList = oldValue is List ? oldValue : const [];
      final newList = newValue is List ? newValue : const [];
      final length = oldList.length > newList.length ? oldList.length : newList.length;
      for (var index = 0; index < length; index++) {
        _compare(
          [...path, index],
          AuditRecordedValue(index < oldList.length, index < oldList.length ? oldList[index] : null),
          AuditRecordedValue(index < newList.length, index < newList.length ? newList[index] : null),
          result,
        );
      }
      return;
    }
    result.add(AuditFieldChange(path, before, after));
  }

  static bool _equal(Object? before, Object? after) {
    if (before is Map && after is Map) {
      return before.length == after.length && before.keys.every(
        (key) => after.containsKey(key) && _equal(before[key], after[key]),
      );
    }
    if (before is List && after is List) {
      if (before.length != after.length) return false;
      for (var index = 0; index < before.length; index++) {
        if (!_equal(before[index], after[index])) return false;
      }
      return true;
    }
    return before == after;
  }
}

class AuditRecordedValue {
  const AuditRecordedValue(this.present, this.value);
  final bool present;
  final Object? value;
}

class AuditFieldChange {
  const AuditFieldChange(this.path, this.before, this.after);
  final List<Object> path;
  final AuditRecordedValue before;
  final AuditRecordedValue after;
}
