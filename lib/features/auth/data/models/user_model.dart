class UnitModel {
  final int id;
  final String nama;
  final String? kode;

  const UnitModel({
    required this.id,
    required this.nama,
    this.kode,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      nama: json['nama']?.toString() ?? '',
      kode: json['kode']?.toString(),
    );
  }

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

  const GudangModel({
    required this.id,
    required this.nama,
    this.kode,
  });

  factory GudangModel.fromJson(Map<String, dynamic> json) {
    return GudangModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      nama: json['nama']?.toString() ?? '',
      kode: json['kode']?.toString(),
    );
  }

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
  });
  /// Pengecekan wewenang dinamis Spatie Capability-Based RBAC
  bool can(String permission) => permissions.contains(permission);

  /// Pengecekan apakah user memiliki role tertentu
  bool hasRole(String role) => roles.contains(role);

  bool get isSuperAdmin => hasRole('super_admin');
  bool get isTeknisi => hasRole('teknisi') && !isSuperAdmin;
  bool get isGudangUser => (hasRole('petugas_gudang') || hasRole('kepala_gudang') || hasRole('admin_logistik') || gudang != null) && !isSuperAdmin;
  bool get isKaru => (hasRole('kepala_unit') || can('page_KepalaUnitDashboard')) && !isSuperAdmin;
  bool get isAdminLogistik => (hasRole('admin_logistik') || can('page_AdminLogistikDashboard')) && !isSuperAdmin;
  bool get isAuditor => (hasRole('auditor') || permissions.any((p) => p.contains('audit_manajemen'))) && !isSuperAdmin;
  bool get isManajemen => (hasRole('manajemen') || can('page_ManajemenDashboard')) && !isSuperAdmin;
  bool get isPengadaan => (hasRole('pengadaan') || can('page_PengadaanDashboard')) && !isSuperAdmin;
  bool get hasAuditAccess => isSuperAdmin || isAuditor || isManajemen || can('view_any_audit_manajemen::audit::trail');
  bool get hasPersediaanAccess => isSuperAdmin || isGudangUser || isAuditor || isManajemen || can('view_any_gudang_stok::monitoring::fefo');
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
    );
  }

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
      };
}
