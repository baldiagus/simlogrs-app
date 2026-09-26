import '../../../distribusi/presentation/screens/amprah_hub_screen.dart';
import '../../../distribusi/presentation/screens/picking_distribusi_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../gudang/presentation/screens/inbound_po_list_screen.dart';
import '../../../aset/presentation/screens/sirkulasi_aset_hub_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../pengadaan/presentation/screens/riwayat_pr_screen.dart';
import '../../../master/presentation/screens/master_barang_screen.dart';
import '../../../master/presentation/screens/register_aset_screen.dart';
import '../../../gudang/presentation/screens/daftar_rak_screen.dart';
import '../../../maintenance/presentation/screens/spk_list_screen.dart';
import '../../../maintenance/presentation/screens/jadwal_preventif_screen.dart';
import '../../../maintenance/presentation/screens/rekam_medis_katalog_screen.dart';
import '../../../gudang/presentation/screens/fefo_monitoring_screen.dart';
import '../../../gudang/presentation/screens/buku_mutasi_screen.dart';
import '../../../gudang/presentation/screens/stock_opname_hub_screen.dart';
import '../../../gudang/presentation/screens/otorisasi_penyesuaian_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/hero_status_card.dart';
import '../widgets/live_activity_feed.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/user_top_bar.dart';

class HomeScreen extends ConsumerWidget {
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback? onScanPressed;

  const HomeScreen({
    super.key,
    this.onNavigateTab,
    this.onScanPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. User Header Top Bar
                const UserTopBar(),
                const SizedBox(height: 20),

                // 2. Hero Status Card (Live Pending Approvals)
                summaryAsync.when(
                  data: (summary) => HeroStatusCard(
                    summary: summary,
                    onInspectPressed: () {
                      final target = summary.hero.targetAksi;
                      if (target == 'spk_list') {
                        onNavigateTab?.call(2); // Navigasi ke Tab IPSRS
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
                        onNavigateTab?.call(1); // Navigasi ke Tab Approval
                      }
                    },
                  ),
                  loading: () => Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryPurple,
                        ),
                      ),
                    ),
                  ),
                  error: (_, __) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Gagal Memuat Ringkasan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tarik ke bawah untuk memuat ulang data.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Banner Pengadaan Ruangan (Hanya untuk unit pemohon, bukan teknisi)
                if (ref.watch(authStateProvider).user?.isTeknisi != true) ...[
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RiwayatPrScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.tintVioletBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.fileSpreadsheet, size: 20, color: AppColors.primaryPurple),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pengadaan Barang Unit (PR)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Ajukan permohonan PR & pantau status tindak lanjut',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Master Katalog & Register Aset (Semua Role)
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
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.tintBlueBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.package, color: AppColors.tintBlue, size: 20),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Master Barang',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Katalog komoditas & stok fisik',
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
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.tintOrangeBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.qrCode, color: AppColors.tintOrange, size: 20),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Register Aset',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Inventaris sarana & alat fisik',
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

                // 3. Quick Action Grid 2x2
                () {
                  final user = ref.watch(authStateProvider).user;
                  final isTeknisi = user?.isTeknisi ?? false;
                  final isAdminLogistik = user?.isAdminLogistik ?? false;
                  final isGudangUser = (!isTeknisi) && ((user?.gudang != null) ||
                      (user?.hasRole('petugas_gudang') ?? false) ||
                      (user?.hasRole('kepala_gudang') ?? false));

                  return QuickActionGrid(
                    pendingCount: summaryAsync.valueOrNull?.totalPendingApproval ?? 0,
                    isGudangUser: isGudangUser,
                    isTeknisi: isTeknisi,
                    isAdminLogistik: isAdminLogistik,
                    onApprovalTap: () {
                      onNavigateTab?.call(1); // Approval Tab
                    },
                    onRakGudangTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DaftarRakScreen()),
                      );
                    },
                    onAsetTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SirkulasiAsetHubScreen()),
                      );
                    },
                    onInboundTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InboundPoListScreen()),
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
                    onLaporRusakTap: () {
                      onNavigateTab?.call(2); // IPSRS Tab
                    },
                    onSpkTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SpkListScreen()),
                      );
                    },
                    onLembarKerjaTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SpkListScreen(
                            initialStatus: 'DITUGASKAN',
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
                  );
                }(),

                // Modul Persediaan & Opname Gudang (Hanya Kepala Gudang & Petugas Gudang, bukan teknisi)
                () {
                  final user = ref.watch(authStateProvider).user;
                  if (user?.isTeknisi == true) return const SizedBox.shrink();
                  final isGudangUser = (user?.gudang != null) ||
                      (user?.hasRole('petugas_gudang') ?? false) ||
                      (user?.hasRole('kepala_gudang') ?? false) ||
                      (user?.hasRole('admin_logistik') ?? false) ||
                      (user?.hasRole('super_admin') ?? false);

                  if (!isGudangUser) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Persediaan & Opname Gudang',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Sirkulasi & Stok Fisik',
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
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FefoMonitoringScreen())),
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
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BukuMutasiScreen())),
                            ),
                          ),
                        ],
                      ),
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
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOpnameHubScreen())),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildGudangMiniCard(
                              context: context,
                              title: 'Otorisasi Selisih',
                              subtitle: 'Penyesuaian saldo',
                              icon: LucideIcons.shieldCheck,
                              iconColor: AppColors.tintTeal,
                              bgColor: AppColors.tintTealBg,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OtorisasiPenyesuaianScreen())),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }(),
                const SizedBox(height: 24),

                // 4. Live Activity Feed
                LiveActivityFeed(
                  activities: summaryAsync.valueOrNull?.recentActivities ?? [],
                ),

                // Spacing to prevent floating bottom nav bar overlap
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
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
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
