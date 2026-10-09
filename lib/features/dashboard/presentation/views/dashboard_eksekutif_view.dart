import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_action_banner_card.dart';
import '../../../anggaran/presentation/screens/pagu_realisasi_screen.dart';
import '../../../aset/presentation/screens/sirkulasi_aset_hub_screen.dart';
import '../../../audit/presentation/screens/audit_spi_hub_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../master/presentation/screens/master_barang_screen.dart';
import '../../../master/presentation/screens/register_aset_screen.dart';
import '../../../pengadaan/presentation/screens/riwayat_pr_screen.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../widgets/hero_status_card.dart';
import '../widgets/live_activity_feed.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/user_top_bar.dart';

class DashboardEksekutifView extends ConsumerWidget {
  final DashboardSummaryModel summary;
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback onHeroInspect;

  const DashboardEksekutifView({
    super.key,
    required this.summary,
    this.onNavigateTab,
    required this.onHeroInspect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final isAuditor = user?.isAuditor ?? false;
    final isManajemen = user?.isManajemen ?? false;
    final isPengadaan = user?.isPengadaan ?? false;
    final hasAuditAccess = user?.hasAuditAccess ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. User Header Top Bar
        const UserTopBar(),
        const SizedBox(height: 20),

        // 2. Hero Status Card (Realisasi Pagu & Pending Approvals)
        HeroStatusCard(
          summary: summary,
          onInspectPressed: onHeroInspect,
        ),
        const SizedBox(height: 20),

        // 3. Quick Action Grid (Khusus Eksekutif, Pengadaan, & Auditor)
        QuickActionGrid(
          pendingCount: summary.totalPendingApproval,
          isAuditor: isAuditor,
          isManajemen: isManajemen,
          isPengadaan: isPengadaan,
          onApprovalTap: () => onNavigateTab?.call(1),
          onAuditSpiTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuditSpiHubScreen()),
            );
          },
          onPaguRealisasiTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaguRealisasiScreen()),
            );
          },
          onAsetTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SirkulasiAsetHubScreen()),
            );
          },
          onRakGudangTap: () {},
          onLaporRusakTap: () {},
        ),
        const SizedBox(height: 16),

        // 4. Modul Khusus Pengadaan (Monitoring & Verifikasi PR)
        if (isPengadaan) ...[
          AppActionBannerCard(
            title: 'Monitoring & Verifikasi PR',
            subtitle: 'Daftar pengajuan PR dari seluruh unit rumah sakit untuk penerbitan PO',
            icon: LucideIcons.fileSpreadsheet,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RiwayatPrScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        // 5. Modul Pusat Audit SPI & CAPA
        if (hasAuditAccess) ...[
          AppActionBannerCard(
            title: 'Pusat Audit Internal SPI & CAPA',
            subtitle: 'Audit trail transaksi, kepatuhan PO, selisih opname, dan register CAPA',
            icon: LucideIcons.shieldAlert,
            borderColor: AppColors.primaryPurple.withValues(alpha: 0.3),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuditSpiHubScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        // 6. Modul Pagu & Realisasi Anggaran RS
        AppActionBannerCard(
          title: 'Pagu & Realisasi Anggaran RS',
          subtitle: 'Screening pengeluaran logistik ruangan & penyerapan anggaran suku cadang',
          icon: LucideIcons.banknote,
          iconColor: AppColors.tintTeal,
          iconBgColor: AppColors.tintTealBg,
          borderColor: AppColors.tintTeal.withValues(alpha: 0.3),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaguRealisasiScreen()),
            );
          },
        ),
        const SizedBox(height: 16),

        // 7. Master Komoditas & Register Aset
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MasterBarangScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.tintBlueBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.package, color: AppColors.tintBlue, size: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Master Barang',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Katalog & harga beli',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterAsetScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.tintOrangeBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.qrCode, color: AppColors.tintOrange, size: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Register Aset',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Inventaris seluruh RS',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 8. Live Activity Feed Eksekutif
        LiveActivityFeed(
          activities: summary.recentActivities,
        ),
      ],
    );
  }
}
