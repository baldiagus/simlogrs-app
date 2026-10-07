import '../../../audit/presentation/screens/audit_spi_hub_screen.dart';
import '../../../anggaran/presentation/screens/pagu_realisasi_screen.dart';
import '../../../distribusi/presentation/screens/amprah_hub_screen.dart';
import '../../../distribusi/presentation/screens/picking_distribusi_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../gudang/presentation/screens/inbound_po_list_screen.dart';
import '../../../aset/presentation/screens/sirkulasi_aset_hub_screen.dart';
import '../../../aset/presentation/screens/pengalihan_hub_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../pengadaan/presentation/screens/riwayat_pr_screen.dart';
import '../../../master/presentation/screens/master_barang_screen.dart';
import '../../../master/presentation/screens/register_aset_screen.dart';
import '../../../gudang/presentation/screens/daftar_rak_screen.dart';
import '../../../gudang/presentation/screens/stock_opname_hub_screen.dart';
import '../../../maintenance/presentation/screens/spk_list_screen.dart';
import '../../../maintenance/presentation/screens/jadwal_preventif_screen.dart';
import '../../../maintenance/presentation/screens/rekam_medis_katalog_screen.dart';
import '../../../approval/presentation/providers/approval_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/hero_status_card.dart';
import '../widgets/live_activity_feed.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/user_top_bar.dart';
import '../widgets/gudang_shortcut_grid.dart';
import '../../../../shared/widgets/app_action_banner_card.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';

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
                  loading: () => const AppLoadingView(),
                  error: (err, _) => AppErrorView(
                    title: 'Gagal Memuat Ringkasan',
                    error: err,
                    onRetry: () => ref.invalidate(dashboardSummaryProvider),
                  ),
                ),
                const SizedBox(height: 20),

                // Banner Pengadaan Ruangan (Hanya untuk unit pemohon, bukan teknisi)
                if (ref.watch(authStateProvider).user?.isTeknisi != true) ...[
                  AppActionBannerCard(
                    title: ref.watch(authStateProvider).user?.isPengadaan == true
                        ? 'Monitoring & Verifikasi PR'
                        : 'Pengadaan Barang Unit (PR)',
                    subtitle: ref.watch(authStateProvider).user?.isPengadaan == true
                        ? 'Daftar pengajuan PR dari seluruh unit rumah sakit'
                        : 'Ajukan permohonan PR & pantau status tindak lanjut',
                    icon: LucideIcons.fileSpreadsheet,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RiwayatPrScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // Banner Pengalihan & Mutasi Aset (Semua unit, bukan teknisi murni)
                if (ref.watch(authStateProvider).user?.isTeknisi != true) ...[
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
                  final approvalAsync = ref.watch(approvalPendingProvider);
                  final isTeknisi = user?.isTeknisi ?? false;
                  final isKepalaTeknisi = user?.isKepalaTeknisi ?? false;
                  final isAdminLogistik = user?.isAdminLogistik ?? false;
                  final isAuditor = user?.isAuditor ?? false;
                  final isManajemen = user?.isManajemen ?? false;
                  final isPengadaan = user?.isPengadaan ?? false;
                  final isKaru = user?.isKaru ?? false;
                  final isKepalaGudang = user?.isKepalaGudang ?? false;
                  final isGudangUser = (!isTeknisi) && ((user?.gudang != null) ||
                      (user?.hasRole('petugas_gudang') ?? false) ||
                      (user?.hasRole('kepala_gudang') ?? false));
                  final effectivePending = approvalAsync.valueOrNull?.total ??
                      summaryAsync.valueOrNull?.totalPendingApproval ??
                      0;

                  return QuickActionGrid(
                    pendingCount: effectivePending,
                    isKaru: isKaru,
                    isKepalaGudang: isKepalaGudang,
                    isPetugasGudang: user?.isPetugasGudang ?? false,
                    isGudangUser: isGudangUser,
                    isTeknisi: isTeknisi,
                    isKepalaTeknisi: isKepalaTeknisi,
                    isAdminLogistik: isAdminLogistik,
                    isAuditor: isAuditor,
                    isManajemen: isManajemen,
                    isPengadaan: isPengadaan,
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
                    onApprovalTap: () {
                      onNavigateTab?.call(1); // Approval Tab
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
                  );
                }(),

                // Banner Pusat Audit SPI & CAPA (Khusus Auditor & Manajemen)
                if (ref.watch(authStateProvider).user?.hasAuditAccess == true) ...[
                  const SizedBox(height: 16),
                  AppActionBannerCard(
                    title: 'Pusat Audit Internal SPI & CAPA',
                    subtitle: 'Audit trail, kepatuhan PO, selisih opname, register temuan',
                    icon: LucideIcons.shieldAlert,
                    borderColor: AppColors.primaryPurple.withValues(alpha: 0.3),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuditSpiHubScreen()),
                      );
                    },
                  ),
                ],

                // Banner Pagu & Realisasi Anggaran (Auditor, Manajemen, Pengadaan, Admin Logistik)
                if (ref.watch(authStateProvider).user?.isAuditor == true ||
                    ref.watch(authStateProvider).user?.isManajemen == true ||
                    ref.watch(authStateProvider).user?.isPengadaan == true ||
                    ref.watch(authStateProvider).user?.isAdminLogistik == true) ...[
                  const SizedBox(height: 12),
                  AppActionBannerCard(
                    title: 'Pagu & Realisasi Anggaran RS',
                    subtitle: 'Screening pengeluaran logistik ruangan & suku cadang IPSRS',
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
                ],
                // Modul Persediaan & Opname Gudang (Hanya Kepala Gudang & Petugas Gudang, bukan teknisi)
                () {
                  final user = ref.watch(authStateProvider).user;
                  if (user?.isTeknisi == true) return const SizedBox.shrink();
                  final isGudangUser = (user?.gudang != null) ||
                      (user?.hasRole('petugas_gudang') ?? false) ||
                      (user?.hasRole('kepala_gudang') ?? false) ||
                      (user?.hasRole('admin_logistik') ?? false) ||
                      (user?.hasRole('super_admin') ?? false) ||
                      (user?.hasPersediaanAccess ?? false);
                  if (!isGudangUser) return const SizedBox.shrink();

                  return const GudangShortcutGrid();
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

}
