import '../../../auth/data/models/user_model.dart';

/// Apakah user boleh melihat tab Otorisasi pengalihan.
bool hasOtorisasiPengalihanAccess(UserModel? user) {
  final isApproverRole = (user?.hasRole('kepala_unit') ?? false) ||
      (user?.hasRole('kepala_gudang') ?? false) ||
      (user?.hasRole('kepala_teknisi') ?? false) ||
      (user?.hasRole('admin_logistik') ?? false) ||
      (user?.hasRole('manajemen') ?? false) ||
      (user?.hasRole('super_admin') ?? false);

  return isApproverRole ||
      (user?.can('layanan_unit::approval::peminjaman') ?? false) ||
      (user?.can('view_any_layanan_unit::approval::karu') ?? false) ||
      (user?.can('update_layanan_unit::pengalihan::aset') ?? false);
}

/// Apakah user berhak mengakses fitur pengalihan barang gudang (hanya gudang logistik / admin).
bool canAccessPengalihanBarang(UserModel? user) {
  if (user == null) return false;
  if (user.isSuperAdmin || user.isAdminLogistik) return true;
  // Peran ruangan/unit (Karu, staf ruangan, dsb) tidak berhak atas pengalihan barang gudang
  if (user.hasRole('kepala_unit') || user.hasRole('petugas_unit') || user.isKaru) {
    return false;
  }
  return user.isGudangUser ||
      user.hasRole('kepala_gudang') ||
      user.hasRole('petugas_gudang') ||
      user.can('view_any_gudang_stok::pengalihan::barang') ||
      user.can('create_gudang_stok::pengalihan::barang');
}

/// Apakah user boleh mengajukan pengalihan untuk [kategori] ('ASET'/'BARANG').
bool canCreatePengalihan(UserModel? user, String kategori) {
  final isFieldTeknisi = (user?.hasRole('teknisi') ?? false) &&
      !(user?.hasRole('kepala_teknisi') ?? false);
  final canCreateAset = !isFieldTeknisi &&
      (user?.unit != null ||
          user?.isSuperAdmin == true ||
          user?.isAdminLogistik == true ||
          user?.isGudangUser == true);
  final canCreateBarang = canAccessPengalihanBarang(user) &&
      (user?.isSuperAdmin == true ||
          user?.isAdminLogistik == true ||
          user?.isGudangUser == true ||
          (user?.can('create_gudang_stok::pengalihan::barang') ?? false));
  return kategori == 'ASET' ? canCreateAset : canCreateBarang;
}
