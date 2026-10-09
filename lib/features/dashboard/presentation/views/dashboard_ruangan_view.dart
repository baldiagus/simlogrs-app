import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_action_banner_card.dart';
import '../../../aset/presentation/screens/pengalihan_hub_screen.dart';
import '../../../aset/presentation/screens/sirkulasi_aset_hub_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../distribusi/presentation/screens/amprah_hub_screen.dart';
import '../../../pengadaan/presentation/screens/pengadaan_hub_screen.dart';
import '../../../maintenance/presentation/screens/lapor_rusak_hub_screen.dart';
import '../../../approval/presentation/screens/approval_center_screen.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../widgets/hero_status_card.dart';
import '../widgets/live_activity_feed.dart';
import '../widgets/master_shortcut_section.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/user_top_bar.dart';

class DashboardRuanganView extends ConsumerWidget {
  final DashboardSummaryModel summary;
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback onHeroInspect;

  const DashboardRuanganView({
    super.key,
    required this.summary,
    this.onNavigateTab,
    required this.onHeroInspect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final isKaru = user?.isKaru ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. User Header Top Bar
        const UserTopBar(),
        const SizedBox(height: 20),

        // 2. Hero Status Card (Amprah & Pinjaman Ruangan)
        HeroStatusCard(
          summary: summary,
          onInspectPressed: onHeroInspect,
        ),
        const SizedBox(height: 16),

        // Master Barang & Register Aset
        const MasterShortcutSection(),
        const SizedBox(height: 20),

        // 3. Quick Action Grid (Khusus Alur Kerja Ruangan Pelayanan)
        QuickActionGrid(
          pendingCount: summary.totalPendingApproval,
          isKaru: isKaru,
          onApprovalTap: () {
            if (isKaru) {
              onNavigateTab?.call(1);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApprovalCenterScreen()),
              );
            }
          },
          onPengadaanTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PengadaanHubScreen()),
            );
          },
          onAmprahTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AmprahHubScreen()),
            );
          },
          onLaporRusakTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LaporRusakHubScreen()),
            );
          },
          onAsetTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SirkulasiAsetHubScreen()),
            );
          },
          onRakGudangTap: () {},
        ),
        const SizedBox(height: 16),
        // 4. Layanan Pengalihan & Mutasi Ruangan
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
        const SizedBox(height: 24),

        // 5. Live Activity Feed Ruangan
        LiveActivityFeed(
          activities: summary.recentActivities,
        ),
      ],
    );
  }
}
