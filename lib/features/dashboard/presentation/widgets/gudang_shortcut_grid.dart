import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../gudang/presentation/screens/buku_mutasi_screen.dart';
import '../../../gudang/presentation/screens/fefo_monitoring_screen.dart';
import '../../../gudang/presentation/screens/otorisasi_penyesuaian_screen.dart';
import '../../../gudang/presentation/screens/stock_opname_hub_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'dashboard_shortcut_layout.dart';

class GudangShortcutGrid extends ConsumerWidget {
  const GudangShortcutGrid({super.key});

  /// Membangun grid pintasan gudang; menu yang tampil disesuaikan dengan peran petugas gudang.
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                isPetugasGudang ? 'Persediaan Stok Gudang' : 'Persediaan & Opname Gudang',
                style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              isPetugasGudang ? 'Monitoring FEFO' : 'Sirkulasi Fisik',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.8)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DashboardShortcutLayout(
          children: [
            _buildGudangMiniCard(
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
            _buildGudangMiniCard(
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
            if (!isPetugasGudang)
              _buildGudangMiniCard(
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
            if (!isPetugasGudang && canOtorisasi)
              _buildGudangMiniCard(
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
              ),
          ],
        ),
      ],
    );
  }

  /// Membangun satu kartu mini pintasan gudang berisi ikon, judul, dan subjudul yang dapat diketuk.
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
