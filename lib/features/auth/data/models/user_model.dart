class UnitModel {
  final int id;
  final String nama;
  final String? kode;

  const UnitModel({
    required this.id,
    required this.nama,
    this.kode,
  });

  /// Membangun data unit kerja dari JSON API; id diparse aman baik int maupun string.
  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      nama: json['nama']?.toString() ?? '',
      kode: json['kode']?.toString(),
    );
  }

  /// Serialisasi unit ke JSON untuk cache lokal; `kode` hanya disertakan jika ada.
  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        if (kode != null) 'kode': kode,
      };
}

class GudangModel {
  final int id;
  final String nama;
  final String? kode;
  final int? activeBatchesCount;

  const GudangModel({
    required this.id,
    required this.nama,
    this.kode,
    this.activeBatchesCount,
  });

  /// Membangun data gudang dari JSON API beserta jumlah batch aktif bila tersedia.
  factory GudangModel.fromJson(Map<String, dynamic> json) {
    return GudangModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      nama: json['nama']?.toString() ?? '',
      kode: json['kode']?.toString(),
      activeBatchesCount: (json['active_batches_count'] as num?)?.toInt(),
    );
  }

  /// Serialisasi gudang ke JSON untuk cache lokal.
  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        if (kode != null) 'kode': kode,
      };
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? nip;
  final String? username;
  final String? noTelepon;
  final String? status;
  final UnitModel? unit;
  final GudangModel? gudang;
  final List<String> roles;
  final List<String> permissions;
  final bool wajibGantiPassword;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.nip,
    this.username,
    this.noTelepon,
    this.status,
    this.unit,
    this.gudang,
    required this.roles,
    required this.permissions,
    this.wajibGantiPassword = false,
  });
  /// Pengecekan wewenang dinamis Spatie Capability-Based RBAC
  bool can(String permission) => permissions.contains(permission);

  /// Pengecekan apakah user memiliki role tertentu
  bool hasRole(String role) => roles.contains(role);

  /// True jika user adalah super admin (akses penuh ke semua fitur).
  bool get isSuperAdmin => hasRole('super_admin');
  /// True jika user kepala teknisi dan bukan super admin.
  bool get isKepalaTeknisi => hasRole('kepala_teknisi') && !isSuperAdmin;
  /// True jika user teknisi biasa (bukan kepala teknisi/super admin).
  bool get isTeknisi => hasRole('teknisi') && !isKepalaTeknisi && !isSuperAdmin;
  /// True jika user bagian gudang (petugas, kepala gudang, admin logistik) dan bukan super admin.
  bool get isGudangUser => (hasRole('petugas_gudang') || hasRole('kepala_gudang') || hasRole('admin_logistik')) && !isSuperAdmin;
  /// True jika user berhak menerima barang masuk (inbound) dari PO.
  bool get canReceiveInbound =>
      isSuperAdmin ||
      isAdminLogistik ||
      hasRole('kepala_gudang') ||
      hasRole('petugas_gudang') ||
      can('create_gudang_stok::penerimaan::po');
  /// True jika user kepala gudang atau punya akses dashboard kepala gudang.
  bool get isKepalaGudang => (hasRole('kepala_gudang') || can('page_KepalaGudangDashboard')) && !isSuperAdmin;
  /// True jika user petugas gudang dan bukan super admin.
  bool get isPetugasGudang => hasRole('petugas_gudang') && !isSuperAdmin;
  /// True jika user kepala unit (karu) atau kepala teknisi atau punya akses dashboard kepala unit.
  bool get isKaru => (hasRole('kepala_unit') || isKepalaTeknisi || can('page_KepalaUnitDashboard')) && !isSuperAdmin;
  /// True jika user admin logistik atau punya akses dashboard admin logistik.
  bool get isAdminLogistik => (hasRole('admin_logistik') || can('page_AdminLogistikDashboard')) && !isSuperAdmin;
  /// True jika auditor (role `auditor`) atau berhak menerbitkan temuan audit; permission view saja (mis. auditee) tidak cukup.
  bool get isAuditor => (hasRole('auditor') || can('create_audit_manajemen::temuan::capa')) && !isSuperAdmin;
  /// True jika user manajemen atau punya akses dashboard manajemen.
  bool get isManajemen => (hasRole('manajemen') || can('page_ManajemenDashboard')) && !isSuperAdmin;
  /// True jika user bagian pengadaan atau punya akses dashboard pengadaan.
  bool get isPengadaan => (hasRole('pengadaan') || can('page_PengadaanDashboard')) && !isSuperAdmin;
  /// True jika user boleh mengakses fitur audit (super admin, auditor, manajemen, atau permission audit trail).
  bool get hasAuditAccess => isSuperAdmin || isAuditor || isManajemen || can('view_any_audit_manajemen::audit::trail');
  /// True jika user boleh melihat register Temuan CAPA (akses audit penuh atau auditee dengan permission view CAPA).
  bool get hasCapaAccess => hasAuditAccess || can('view_audit_manajemen::temuan::capa');
  /// True jika user boleh mengakses fitur persediaan/stok (gudang, auditor, manajemen, atau permission monitoring FEFO).
  bool get hasPersediaanAccess => isSuperAdmin || isGudangUser || isAuditor || isManajemen || can('view_any_gudang_stok::monitoring::fefo');
  /// True jika user boleh menyetujui/menolak PR di Meja 1 (Karu/Kepala Gudang/Admin Logistik/Super Admin); pengadaan, manajemen, dan auditor tidak.
  bool get canApprovePrMeja1 =>
      !isPengadaan &&
      !(isManajemen || isAuditor) &&
      (isKaru || isKepalaGudang || isAdminLogistik || isSuperAdmin || can('update_pengadaan::permintaan::pengadaan'));
  /// True jika user boleh mengelola PO di Meja 2 (Pengadaan/Admin Logistik/Super Admin).
  bool get canManagePo => isPengadaan || isAdminLogistik || isSuperAdmin;
  /// True jika user boleh membuat PR baru (petugas/kepala unit, super admin, atau permission create); tim pengadaan tidak.
  bool get canCreatePr =>
      !isPengadaan &&
      (can('create_pengadaan::permintaan::pengadaan') || hasRole('petugas_unit') || hasRole('kepala_unit') || isSuperAdmin);
  /// True jika user berhak mengonfirmasi penerimaan SPPB di ruangan.
  bool get canKonfirmasiPenerimaanSppb =>
      isSuperAdmin ||
      isAdminLogistik ||
      hasRole('petugas_unit') ||
      isKepalaTeknisi ||
      can('update_layanan_unit::penerimaan::barang');
  /// True jika user berhak melakukan eksekusi picking distribusi FEFO.
  bool get canPickingDistribusi =>
      isSuperAdmin ||
      isAdminLogistik ||
      isKepalaGudang ||
      isPetugasGudang ||
      can('create_gudang_stok::picking::distribusi');
  /// True jika user berhak menyetujui/menolak amprah di Meja 1 (Karu / Super Admin / Admin Logistik).
  bool get canApproveAmprahMeja1 =>
      can('update_layanan_unit::approval::karu') &&
      (isSuperAdmin || isAdminLogistik || hasRole('kepala_unit'));
  /// True jika user berhak menyetujui/menolak amprah di Meja 2 (Kepala Gudang / Super Admin / Admin Logistik).
  bool get canApproveAmprahMeja2 =>
      can('update_gudang_stok::distribusi::approval') &&
      (isSuperAdmin || isAdminLogistik || hasRole('kepala_gudang'));
  /// True jika user berhak mengajukan permintaan amprah ruangan ke gudang.
  bool get canAjukanAmprah {
    final hasScope = unit != null || gudang != null;
    if (!hasScope) return false;
    return isSuperAdmin ||
        isAdminLogistik ||
        isPengadaan ||
        hasRole('kepala_unit') ||
        hasRole('petugas_unit') ||
        isKepalaTeknisi ||
        can('create_layanan_unit::permintaan::barang');
  }
  /// Membangun data user dari JSON API (profil, unit, gudang, role, permission).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? json['nama']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      nip: json['nip']?.toString(),
      username: json['username']?.toString(),
      noTelepon: json['no_telepon']?.toString() ?? json['phone']?.toString(),
      status: json['status']?.toString() ?? 'AKTIF',
      unit: json['unit'] is Map<String, dynamic>
          ? UnitModel.fromJson(json['unit'] as Map<String, dynamic>)
          : null,
      gudang: json['gudang'] is Map<String, dynamic>
          ? GudangModel.fromJson(json['gudang'] as Map<String, dynamic>)
          : null,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      wajibGantiPassword: json['wajib_ganti_password'] == true,
    );
  }

  /// Serialisasi user ke JSON untuk disimpan sebagai cache lokal.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (nip != null) 'nip': nip,
        if (username != null) 'username': username,
        if (noTelepon != null) 'no_telepon': noTelepon,
        if (status != null) 'status': status,
        if (unit != null) 'unit': unit!.toJson(),
        if (gudang != null) 'gudang': gudang!.toJson(),
        'roles': roles,
        'permissions': permissions,
        'wajib_ganti_password': wajibGantiPassword,
      };
}
