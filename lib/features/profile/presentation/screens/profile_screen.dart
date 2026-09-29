import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _showAllPermissions = false;

  String _formatRoleName(String raw) {
    switch (raw.toLowerCase()) {
      case 'super_admin':
        return 'Super Administrator';
      case 'admin_logistik':
        return 'Admin Logistik';
      case 'kepala_unit':
        return 'Kepala Ruangan / Unit';
      case 'petugas_unit':
        return 'Petugas Ruangan';
      case 'kepala_gudang':
        return 'Kepala Gudang';
      case 'petugas_gudang':
        return 'Petugas Gudang';
      case 'teknisi':
        return 'Teknisi IPSRS';
      case 'pengadaan':
        return 'Bagian Pengadaan';
      case 'manajemen':
        return 'Manajemen Direksi';
      case 'auditor':
        return 'Auditor Internal';
      case 'staf_gudang':
        return 'Staf Gudang';
      case 'panel_user':
        return 'Pengguna Portal';
      default:
        return raw.replaceAll('_', ' ').toUpperCase();
    }
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Konfirmasi Keluar',
      message: 'Apakah Anda yakin ingin mengakhiri sesi dan keluar dari aplikasi SIMLOG RS?',
      confirmLabel: 'Ya, Keluar',
      confirmColor: AppColors.danger,
      icon: LucideIcons.logOut,
    );
    if (confirmed) {
      ref.read(authStateProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Pengguna tidak ditemukan')),
      );
    }

    final initial = user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, size: 20, color: AppColors.danger),
            tooltip: 'Keluar',
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. User Identity Hero Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.softCard,
                ),
                child: Column(
                  children: [
                    // Avatar Emblem
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryHeroGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(91, 80, 230, 0.25),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Name
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),

                    // Email
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.mail, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    if (user.nip != null && user.nip!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.badgeCheck, size: 13, color: AppColors.primaryPurple),
                          const SizedBox(width: 5),
                          Text(
                            'NIP: ${user.nip}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Status & Role Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        StatusBadge(status: user.status ?? 'AKTIF'),
                        ...user.roles.map(
                          (r) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.tintVioletBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatRoleName(r),
                              style: const TextStyle(
                                color: AppColors.primaryPurple,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Unit & Facility Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: LucideIcons.building,
                      label: 'Unit Pelayanan Ruangan',
                      value: user.unit?.nama ?? 'Tidak terikat unit',
                      isHighlight: user.unit != null,
                    ),
                    const Divider(color: AppColors.border, height: 18),
                    _buildInfoRow(
                      icon: LucideIcons.archive,
                      label: 'Fasilitas Gudang Sentral',
                      value: user.gudang?.nama ?? 'Tidak terikat gudang',
                      isHighlight: user.gudang != null,
                    ),
                    const Divider(color: AppColors.border, height: 18),
                    _buildInfoRow(
                      icon: LucideIcons.phone,
                      label: 'Kontak Dinas / No. Telepon',
                      value: user.noTelepon ?? 'Belum dicantumkan',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Spatie Permissions (Capability-Based RBAC)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Wewenang Sistem (Spatie RBAC)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: '${user.permissions.length} Akses'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (_showAllPermissions ? user.permissions : user.permissions.take(8))
                          .map(
                            (p) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                p,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    if (user.permissions.length > 8) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => setState(() => _showAllPermissions = !_showAllPermissions),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _showAllPermissions
                                  ? 'Sembunyikan Wewenang'
                                  : 'Lihat Semua (+${user.permissions.length - 8} wewenang)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                            Icon(
                              _showAllPermissions ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                              size: 14,
                              color: AppColors.primaryPurple,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. App Info & Architecture Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.success),
                        SizedBox(width: 8),
                        Text(
                          'SIMLOG RS Non-Medis v2',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sistem Informasi Manajemen Logistik Rumah Sakit • Zero-Hardcode & Capability-Based RBAC Architecture.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Logout Button
              CustomButton(
                text: 'Keluar dari Akun',
                backgroundColor: const Color(0xFFFEF2F2),
                textColor: AppColors.danger,
                icon: const Icon(LucideIcons.logOut, size: 18, color: AppColors.danger),
                onPressed: () => _showLogoutConfirmation(context),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isHighlight ? AppColors.primaryPurple : AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isHighlight ? AppColors.primaryPurple : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
