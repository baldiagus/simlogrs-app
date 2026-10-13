import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../anggaran/presentation/screens/pagu_realisasi_screen.dart';
import '../../../audit/presentation/screens/audit_spi_hub_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../distribusi/presentation/screens/amprah_hub_screen.dart';
import '../../../distribusi/presentation/screens/picking_distribusi_screen.dart';
import '../../../gudang/presentation/screens/inbound_po_list_screen.dart';
import '../providers/dashboard_provider.dart';
import '../views/dashboard_eksekutif_view.dart';
import '../views/dashboard_gudang_view.dart';
import '../views/dashboard_ipsrs_view.dart';
import '../views/dashboard_ruangan_view.dart';
import '../widgets/user_top_bar.dart';

class HomeScreen extends ConsumerWidget {
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback? onScanPressed;

  const HomeScreen({
    super.key,
    this.onNavigateTab,
    this.onScanPressed,
  });

  /// Membangun halaman beranda: memilih tampilan dashboard sesuai peran user dan menangani state loading/error serta tarik-untuk-segarkan.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryPurple,
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: summaryAsync.when(
              data: (summary) {
                /// Mengarahkan tombol hero ke layar tujuan sesuai `targetAksi` ringkasan.
                void onHeroInspect() {
                  final target = summary.hero.targetAksi;
                  if (target == 'audit_spi') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuditSpiHubScreen()),
                    );
                  } else if (target == 'pagu_realisasi') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaguRealisasiScreen()),
                    );
                  } else if (target == 'spk_list') {
                    onNavigateTab?.call(2);
                  } else if (target == 'amprah_hub') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AmprahHubScreen()),
                    );
                  } else if (target == 'picking') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PickingDistribusiScreen()),
                    );
                  } else if (target == 'inbound') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InboundPoListScreen()),
                    );
                  } else {
                    onNavigateTab?.call(1);
                  }
                }

                Widget currentView;
                if (user?.isTeknisi == true || user?.isKepalaTeknisi == true) {
                  currentView = DashboardIpsrsView(
                    summary: summary,
                    onNavigateTab: onNavigateTab,
                    onHeroInspect: onHeroInspect,
                  );
                } else if (user?.isGudangUser == true) {
                  currentView = DashboardGudangView(
                    summary: summary,
                    onNavigateTab: onNavigateTab,
                    onHeroInspect: onHeroInspect,
                  );
                } else if (user?.isAuditor == true ||
                    user?.isManajemen == true ||
                    user?.isPengadaan == true ||
                    user?.isSuperAdmin == true) {
                  currentView = DashboardEksekutifView(
                    summary: summary,
                    onNavigateTab: onNavigateTab,
                    onHeroInspect: onHeroInspect,
                  );
                } else {
                  currentView = DashboardRuanganView(
                    summary: summary,
                    onNavigateTab: onNavigateTab,
                    onHeroInspect: onHeroInspect,
                  );
                }

                return Column(
                  children: [
                    currentView,
                    const SizedBox(height: 90),
                  ],
                );
              },
              loading: () => const Column(
                children: [
                  UserTopBar(),
                  SizedBox(height: 32),
                  AppLoadingView(),
                ],
              ),
              error: (err, _) => Column(
                children: [
                  const UserTopBar(),
                  const SizedBox(height: 32),
                  AppErrorView(
                    title: 'Gagal Memuat Ringkasan',
                    error: err,
                    onRetry: () => ref.invalidate(dashboardSummaryProvider),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
