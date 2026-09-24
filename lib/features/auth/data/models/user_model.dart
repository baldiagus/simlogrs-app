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
  final String? noTelepon;
  final UnitModel? unit;
  final GudangModel? gudang;
  final List<String> roles;
  final List<String> permissions;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.noTelepon,
    this.unit,
    this.gudang,
    required this.roles,
    required this.permissions,
  });

  /// Pengecekan wewenang dinamis Spatie Capability-Based RBAC
  bool can(String permission) => permissions.contains(permission);

  /// Pengecekan apakah user memiliki role tertentu
  bool hasRole(String role) => roles.contains(role);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? json['nama']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      noTelepon: json['no_telepon']?.toString() ?? json['phone']?.toString(),
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
        if (noTelepon != null) 'no_telepon': noTelepon,
        if (unit != null) 'unit': unit!.toJson(),
        if (gudang != null) 'gudang': gudang!.toJson(),
        'roles': roles,
        'permissions': permissions,
      };
}
