import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_action_banner_card.dart';
import '../../../aset/presentation/screens/pengalihan_hub_screen.dart';
import '../../../aset/presentation/screens/sirkulasi_aset_hub_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pengadaan/presentation/screens/pengadaan_hub_screen.dart';
import '../../../distribusi/presentation/screens/amprah_hub_screen.dart';
import '../../../maintenance/presentation/screens/spk_list_screen.dart';
import '../../../maintenance/presentation/screens/lapor_rusak_hub_screen.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../widgets/hero_status_card.dart';
import '../widgets/live_activity_feed.dart';
import '../widgets/master_shortcut_section.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/gudang_shortcut_grid.dart';
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

  /// Membangun dashboard eksekutif (super admin, auditor, manajemen, pengadaan) dengan pintasan yang disesuaikan per peran.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final isAuditor = user?.isAuditor ?? false;
    final isManajemen = user?.isManajemen ?? false;
    final isPengadaan = user?.isPengadaan ?? false;

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
        const SizedBox(height: 16),

        // Master Barang & Register Aset
        const MasterShortcutSection(),
        const SizedBox(height: 20),

        // 3. Quick Action Grid (Khusus Eksekutif, Pengadaan, & Auditor)
        QuickActionGrid(
          pendingCount: summary.totalPendingApproval,
          isAuditor: isAuditor,
          isManajemen: isManajemen,
          isPengadaan: isPengadaan,
          onApprovalTap: () => onNavigateTab?.call(1),
          onPengadaanTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PengadaanHubScreen()),
            );
          },
          onAsetTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SirkulasiAsetHubScreen()),
            );
          },
          onRakGudangTap: () {},
          onAmprahTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AmprahHubScreen()),
            );
          },
          onSpkTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SpkListScreen(
                  allowedStatuses: null,
                  customTitle: 'Monitoring SPK Rumah Sakit',
                ),
              ),
            );
          },
          onLaporRusakTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LaporRusakHubScreen()),
            );
          },
        ),
        const SizedBox(height: 16),

        // 4. Modul Khusus Gudang (FEFO, Mutasi, Opname, Otorisasi Selisih untuk Super Admin)
        if (isSuperAdmin) ...[
          const GudangShortcutGrid(),
          const SizedBox(height: 16),
        ],

        // 4. Modul Khusus Pengadaan (Monitoring & Verifikasi PR)
        if (isPengadaan) ...[
          AppActionBannerCard(
            title: 'Monitoring & Verifikasi PR',
            subtitle: 'Daftar pengajuan PR dari seluruh unit rumah sakit untuk penerbitan PO',
            icon: LucideIcons.fileSpreadsheet,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PengadaanHubScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        // 5. Layanan Pengalihan & Mutasi Aset
        AppActionBannerCard(
          title: 'Pengalihan & Mutasi Aset',
          subtitle: 'Mutasi permanen kepemilikan dan penanggung jawab fisik alat',
          icon: LucideIcons.arrowRightLeft,
          iconColor: AppColors.primaryPurple,
          iconBgColor: AppColors.tintVioletBg,
          borderColor: AppColors.primaryPurple.withValues(alpha: 0.25),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PengalihanHubScreen()),
            );
          },
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 8),
        const SizedBox(height: 24),

        // 8. Live Activity Feed Eksekutif
        LiveActivityFeed(
          activities: summary.recentActivities,
        ),
      ],
    );
  }
}
