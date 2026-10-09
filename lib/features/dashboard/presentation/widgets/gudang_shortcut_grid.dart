import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../gudang/presentation/screens/buku_mutasi_screen.dart';
import '../../../gudang/presentation/screens/fefo_monitoring_screen.dart';
import '../../../gudang/presentation/screens/otorisasi_penyesuaian_screen.dart';
import '../../../gudang/presentation/screens/stock_opname_hub_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../gudang/presentation/screens/daftar_rak_screen.dart';

class GudangShortcutGrid extends ConsumerWidget {
  const GudangShortcutGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final isPetugasGudang = user?.isPetugasGudang ?? false;
    final canOtorisasi = (user?.can('view_any_gudang_stok::otorisasi::penyesuaian') ?? false) ||
        (user?.hasRole('kepala_gudang') ?? false) ||
        (user?.hasRole('admin_logistik') ?? false) ||
        (user?.hasRole('super_admin') ?? false) ||
        (user?.hasRole('auditor') ?? false) ||
        (user?.hasRole('manajemen') ?? false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isPetugasGudang ? 'Persediaan Stok Gudang' : 'Persediaan & Opname Gudang',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isPetugasGudang ? 'Monitoring FEFO' : 'Sirkulasi Fisik',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.8)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGudangMiniCard(
                context: context,
                title: 'Monitoring FEFO',
                subtitle: 'Kedaluwarsa & ROP',
                icon: LucideIcons.hourglass,
                iconColor: AppColors.tintOrange,
                bgColor: AppColors.tintOrangeBg,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FefoMonitoringScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGudangMiniCard(
                context: context,
                title: 'Buku Mutasi',
                subtitle: 'Pergerakan stok riil',
                icon: LucideIcons.fileSpreadsheet,
                iconColor: AppColors.tintBlue,
                bgColor: AppColors.tintBlueBg,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BukuMutasiScreen()),
                ),
              ),
            ),
          ],
        ),
        if (!isPetugasGudang) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildGudangMiniCard(
                  context: context,
                  title: 'Stock Opname',
                  subtitle: 'Hitung fisik di rak',
                  icon: LucideIcons.clipboardCheck,
                  iconColor: AppColors.primaryPurple,
                  bgColor: AppColors.tintVioletBg,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StockOpnameHubScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: canOtorisasi
                    ? _buildGudangMiniCard(
                        context: context,
                        title: 'Otorisasi Selisih',
                        subtitle: 'Penyesuaian saldo',
                        icon: LucideIcons.shieldCheck,
                        iconColor: AppColors.tintTeal,
                        bgColor: AppColors.tintTealBg,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OtorisasiPenyesuaianScreen()),
                        ),
                      )
                    : _buildGudangMiniCard(
                        context: context,
                        title: 'Tata Letak Rak',
                        subtitle: 'Lokasi bin & rak fisik',
                        icon: LucideIcons.archive,
                        iconColor: AppColors.tintBlue,
                        bgColor: AppColors.tintBlueBg,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DaftarRakScreen()),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGudangMiniCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
