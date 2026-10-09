import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_action_banner_card.dart';
import '../../../aset/presentation/screens/pengalihan_hub_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../distribusi/presentation/screens/picking_distribusi_screen.dart';
import '../../../gudang/presentation/screens/daftar_rak_screen.dart';
import '../../../gudang/presentation/screens/inbound_po_list_screen.dart';
import '../../../gudang/presentation/screens/stock_opname_hub_screen.dart';
import '../../../master/presentation/screens/master_barang_screen.dart';
import '../../../master/presentation/screens/register_aset_screen.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../widgets/gudang_shortcut_grid.dart';
import '../widgets/hero_status_card.dart';
import '../widgets/live_activity_feed.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final isKepalaGudang = user?.isKepalaGudang ?? false;
    final isPetugasGudang = user?.isPetugasGudang ?? false;
    final isAdminLogistik = user?.isAdminLogistik ?? false;

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
        const SizedBox(height: 20),

        // 3. Quick Action Grid (Khusus Pergudangan & Distribusi)
        QuickActionGrid(
          pendingCount: summary.totalPendingApproval,
          isGudangUser: true,
          isKepalaGudang: isKepalaGudang,
          isPetugasGudang: isPetugasGudang,
          isAdminLogistik: isAdminLogistik,
          onApprovalTap: () => onNavigateTab?.call(1),
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
          onAsetTap: () {},
          onLaporRusakTap: () {},
        ),
        const SizedBox(height: 16),

        // 4. Modul Khusus Gudang (Rak, Opname, Penyesuaian)
        const GudangShortcutGrid(),
        const SizedBox(height: 16),

        // 5. Layanan Khusus Admin Logistik
        if (isAdminLogistik) ...[
          AppActionBannerCard(
            title: 'Pengalihan & Mutasi Aset / Barang',
            subtitle: 'Otorisasi dan monitoring redistribusi antar fasilitas logistik',
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
          const SizedBox(height: 12),
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
                          'Katalog komoditas BHP',
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
                          'Inventaris alat fisik',
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // 6. Live Activity Feed Pergudangan
        LiveActivityFeed(
          activities: summary.recentActivities,
        ),
      ],
    );
  }
}
