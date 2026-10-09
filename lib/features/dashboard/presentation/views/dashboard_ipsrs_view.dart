import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../maintenance/presentation/screens/jadwal_preventif_screen.dart';
import '../../../maintenance/presentation/screens/rekam_medis_katalog_screen.dart';
import '../../../maintenance/presentation/screens/spk_list_screen.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../widgets/hero_status_card.dart';
import '../widgets/live_activity_feed.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/user_top_bar.dart';

class DashboardIpsrsView extends ConsumerWidget {
  final DashboardSummaryModel summary;
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback onHeroInspect;

  const DashboardIpsrsView({
    super.key,
    required this.summary,
    this.onNavigateTab,
    required this.onHeroInspect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final isKepalaTeknisi = user?.isKepalaTeknisi ?? false;
    final isTeknisi = user?.isTeknisi ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. User Header Top Bar
        const UserTopBar(),
        const SizedBox(height: 20),

        // 2. Hero Status Card (Pusat Komando / Tiket Servis Masuk)
        HeroStatusCard(
          summary: summary,
          onInspectPressed: onHeroInspect,
        ),
        const SizedBox(height: 20),

        // 3. Quick Action Grid (Khusus Komando & Lapangan IPSRS)
        QuickActionGrid(
          pendingCount: summary.totalPendingApproval,
          isTeknisi: isTeknisi,
          isKepalaTeknisi: isKepalaTeknisi,
          onApprovalTap: () => onNavigateTab?.call(1),
          onLaporRusakTap: () => onNavigateTab?.call(2), // Tab IPSRS
          onSpkTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SpkListScreen(
                  allowedStatuses: ['DITUGASKAN'],
                  customTitle: 'Surat Perintah Kerja (SPK)',
                ),
              ),
            );
          },
          onLembarKerjaTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SpkListScreen(
                  allowedStatuses: ['DITERIMA', 'SELESAI'],
                  initialStatus: 'DITERIMA',
                  customTitle: 'Lembar Kerja (SPK Aktif)',
                ),
              ),
            );
          },
          onRekamMedisTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RekamMedisKatalogScreen()),
            );
          },
          onPreventifTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JadwalPreventifScreen()),
            );
          },
          onRakGudangTap: () {},
          onAsetTap: () {},
        ),
        const SizedBox(height: 24),

        // 4. Live Activity Feed (Panggilan Darurat & Servis IPSRS)
        LiveActivityFeed(
          activities: summary.recentActivities,
        ),
      ],
    );
  }
}
