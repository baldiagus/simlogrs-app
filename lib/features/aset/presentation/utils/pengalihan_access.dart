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

/// Apakah user boleh mengajukan pengalihan untuk [kategori] ('ASET'/'BARANG').
bool canCreatePengalihan(UserModel? user, String kategori) {
  final isFieldTeknisi = (user?.hasRole('teknisi') ?? false) &&
      !(user?.hasRole('kepala_teknisi') ?? false);
  final canCreateAset = !isFieldTeknisi &&
      (user?.unit != null ||
          user?.isSuperAdmin == true ||
          user?.isAdminLogistik == true ||
          user?.isGudangUser == true);
  final canCreateBarang = user?.isGudangUser == true ||
      user?.isKepalaGudang == true ||
      user?.isPetugasGudang == true ||
      user?.isAdminLogistik == true ||
      user?.isSuperAdmin == true ||
      user?.gudang != null;
  return kategori == 'ASET' ? canCreateAset : canCreateBarang;
}
