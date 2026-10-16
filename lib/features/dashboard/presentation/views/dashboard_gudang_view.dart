import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_action_banner_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../aset/presentation/screens/pengalihan_hub_screen.dart';
import '../../../audit/presentation/screens/temuan_capa_screen.dart';
import '../../../audit/presentation/providers/audit_provider.dart';
import '../../../aset/presentation/screens/sirkulasi_aset_hub_screen.dart';
import '../../../distribusi/presentation/screens/amprah_hub_screen.dart';
import '../../../maintenance/presentation/screens/lapor_rusak_hub_screen.dart';
import '../../../distribusi/presentation/screens/picking_distribusi_screen.dart';
import '../../../gudang/presentation/screens/daftar_rak_screen.dart';
import '../../../gudang/presentation/screens/inbound_po_list_screen.dart';
import '../../../gudang/presentation/screens/stock_opname_hub_screen.dart';
import '../../../pengadaan/presentation/screens/pengadaan_hub_screen.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../widgets/gudang_shortcut_grid.dart';
import '../widgets/hero_status_card.dart';
import '../widgets/live_activity_feed.dart';
import '../widgets/master_shortcut_section.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/user_top_bar.dart';
class DashboardGudangView extends ConsumerWidget {
  final DashboardSummaryModel summary;
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback onHeroInspect;

  const DashboardGudangView({
    super.key,
    required this.summary,
    this.onNavigateTab,
    required this.onHeroInspect,
  });

  /// Membangun dashboard gudang (kepala, petugas, admin logistik) dengan pintasan inbound, picking, rak, dan opname sesuai peran.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final isKepalaGudang = user?.isKepalaGudang ?? false;
    final isPetugasGudang = user?.isPetugasGudang ?? false;
    final isAdminLogistik = user?.isAdminLogistik ?? false;
    final showCapa = user?.hasCapaAccess == true && user?.hasAuditAccess != true;
    final capaCount = showCapa ? (ref.watch(capaMenungguCountProvider).valueOrNull ?? 0) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. User Header Top Bar
        const UserTopBar(),
        const SizedBox(height: 20),

        // 2. Hero Status Card (Antrean Picking FEFO & Inbound PO)
        HeroStatusCard(
          summary: summary,
          onInspectPressed: onHeroInspect,
        ),
        const SizedBox(height: 16),

        // Master Barang & Register Aset
        const MasterShortcutSection(),
        const SizedBox(height: 20),

        // 3. Quick Action Grid (Khusus Pergudangan & Distribusi)
        QuickActionGrid(
          pendingCount: summary.totalPendingApproval,
          isGudangUser: true,
          isKepalaGudang: isKepalaGudang,
          isPetugasGudang: isPetugasGudang,
          isAdminLogistik: isAdminLogistik,
          onApprovalTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AmprahHubScreen()),
            );
          },
          onPengadaanTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PengadaanHubScreen(initialTab: HubTab.inbound)),
            );
          },
          onAmprahTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AmprahHubScreen()),
            );
          },
          onPickingTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PickingDistribusiScreen()),
            );
          },
          onInboundTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InboundPoListScreen()),
            );
          },
          onRakGudangTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DaftarRakScreen()),
            );
          },
          onStockOpnameTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StockOpnameHubScreen()),
            );
          },
          onAsetTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SirkulasiAsetHubScreen()),
            );
          },
          onLaporRusakTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LaporRusakHubScreen()),
            );
          },
          showTemuanCapa: showCapa,
          temuanCapaCount: capaCount,
          onTemuanCapaTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TemuanCapaScreen()),
            );
          },
        ),
        const SizedBox(height: 16),

        // 4. Modul Khusus Gudang (Rak, Opname, Penyesuaian)
        const GudangShortcutGrid(),
        const SizedBox(height: 16),

        // 5. Layanan Pengalihan & Mutasi Aset / Barang (Gudang Logistik)
        AppActionBannerCard(
          title: 'Pengalihan & Mutasi Aset / Barang',
          subtitle: isKepalaGudang
              ? 'Otorisasi dan monitoring redistribusi antar fasilitas logistik'
              : 'Pengajuan dan serah terima redistribusi fisik logistik',
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

        // 6. Live Activity Feed Pergudangan
        LiveActivityFeed(
          activities: summary.recentActivities,
        ),
      ],
    );
  }
}
