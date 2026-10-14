import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../widgets/amprah_approval_modal.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/distribusi_provider.dart';
import '../widgets/amprah_card_item.dart';
import '../widgets/sppb_card_item.dart';
import 'form_pengajuan_amprah_screen.dart';

class AmprahHubScreen extends ConsumerStatefulWidget {
  const AmprahHubScreen({super.key});

  /// Membuat state layar hub amprah yang mengelola tab dan filter status.
  @override
  ConsumerState<AmprahHubScreen> createState() => _AmprahHubScreenState();
}

class _AmprahHubScreenState extends ConsumerState<AmprahHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _statusFilter = 'SEMUA';

  /// Menyiapkan TabController dua tab (pengajuan dan konfirmasi penerimaan) saat layar dibuat.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  /// Melepas TabController agar tidak terjadi kebocoran memori saat layar ditutup.
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Membangun hub amprah: tab daftar permintaan, filter status, dan tombol pengajuan sesuai peran pengguna.
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final isGudangRole = (user?.isPetugasGudang == true) || (user?.isKepalaGudang == true);
    final canKonfirmasiDiRuangan = !isGudangRole &&
        (user?.unit != null || user?.isSuperAdmin == true || user?.isAdminLogistik == true);
    final canAjukanAmprah = (user?.unit != null) ||
        (user?.isPengadaan == true) ||
        (user?.isAuditor == true) ||
        (user?.isManajemen == true) ||
        (user?.hasRole('super_admin') == true);
    final canApproveAmprah = (user?.can('update_layanan_unit::approval::karu') ?? false) ||
        (user?.can('update_gudang_stok::distribusi::approval') ?? false) ||
        (user?.hasRole('admin_logistik') ?? false) ||
        (user?.hasRole('kepala_gudang') ?? false) ||
        (user?.hasRole('super_admin') ?? false);
    // Meja 1 (Karu) memutuskan amprah DIAJUKAN; Meja 2 (kepala gudang / admin logistik gudang) memutuskan amprah DISETUJUI_KARU.
    // Petugas gudang tidak masuk kedua meja sehingga tidak melihat aksi.
    final canMeja1 = canApproveAmprah && (user?.isKaru ?? false);
    final canMeja2 = canApproveAmprah &&
        ((user?.isKepalaGudang ?? false) || (user?.isAdminLogistik ?? false));
    final filterParams = AmprahFilterParams(status: _statusFilter);
    final amprahListAsync = ref.watch(daftarAmprahProvider(filterParams));
    final sppbListAsync = ref.watch(sppbInboundProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Amprah & Distribusi'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Segarkan Data',
            onPressed: () {
              ref.invalidate(daftarAmprahProvider);
              ref.invalidate(sppbInboundProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            const Tab(
              icon: Icon(LucideIcons.fileSpreadsheet, size: 15),
              text: 'Permintaan Amprah',
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.truck, size: 15),
                  const SizedBox(width: 5),
                  const Text('Barang Masuk (SPPB)'),
                  const SizedBox(width: 4),
                  _buildBadge(sppbListAsync.valueOrNull?.length ?? 0),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canAjukanAmprah
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const FormPengajuanAmprahScreen()),
                );
                if (created == true && context.mounted) {
                  ref.invalidate(daftarAmprahProvider);
                  ref.invalidate(dashboardSummaryProvider);
                }
              },
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Ajukan Amprah', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Permintaan Amprah Ruangan
          Column(
            children: [
              // Horizontal status filter pills
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPill('SEMUA', 'Semua'),
                      const SizedBox(width: 6),
                      _buildPill('DIAJUKAN', 'Diajukan'),
                      const SizedBox(width: 6),
                      _buildPill('DISETUJUI_KARU', 'Acc Karu'),
                      const SizedBox(width: 6),
                      _buildPill('DISETUJUI_GUDANG', 'Acc Gudang'),
                      const SizedBox(width: 6),
                      _buildPill('SELESAI', 'Selesai'),
                      const SizedBox(width: 6),
                      _buildPill('DITOLAK', 'Ditolak'),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryPurple,
                  onRefresh: () async => ref.invalidate(daftarAmprahProvider),
                  child: amprahListAsync.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: EmptyStateView(
                              icon: LucideIcons.fileSpreadsheet,
                              title: 'Belum Ada Permintaan Amprah',
                              message: 'Unit ruangan Anda belum pernah mengajukan amprah logistik ke gudang.',
                              action: canAjukanAmprah
                                  ? ElevatedButton.icon(
                                      onPressed: () async {
                                        final created = await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(builder: (_) => const FormPengajuanAmprahScreen()),
                                        );
                                        if (created == true && context.mounted) {
                                          ref.invalidate(daftarAmprahProvider);
                                          ref.invalidate(dashboardSummaryProvider);
                                        }
                                      },
                                      icon: const Icon(LucideIcons.plus, size: 16),
                                      label: const Text('Ajukan Amprah Sekarang'),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final bisaKeputusan = (canMeja1 && item.isDiajukan) || (canMeja2 && item.isDisetujuiKaru);
                          return AmprahCardItem(
                            item: item,
                            onCancelTap: () async {
                              final notifier = ref.read(amprahActionProvider.notifier);
                              final ok = await notifier.batalkanAmprah(item.id);
                              if (!context.mounted) return;
                              final s = ref.read(amprahActionProvider);
                              if (ok) {
                                AppToast.success(context, s.successMessage ?? 'Dibatalkan');
                              } else {
                                AppToast.error(context, s.errorMessage ?? 'Gagal');
                              }
                            },
                            onSetujuiTap: bisaKeputusan
                                ? () => AmprahApprovalModal.show(context, amprah: item, isSetujui: true)
                                : null,
                            onTolakTap: bisaKeputusan
                                ? () => AmprahApprovalModal.show(context, amprah: item, isSetujui: false)
                                : null,
                          );
                        },
                      );
                    },
                    loading: () => const AppLoadingView(),
                    error: (err, _) => AppErrorView(
                      title: 'Gagal Memuat Daftar Amprah',
                      error: err,
                      onRetry: () => ref.invalidate(daftarAmprahProvider),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Tab 2: Barang Masuk (SPPB yang sedang dikirim ke unit)
          RefreshIndicator(
            color: AppColors.primaryPurple,
            onRefresh: () async => ref.invalidate(sppbInboundProvider),
            child: sppbListAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: const EmptyStateView(
                        icon: LucideIcons.truck,
                        title: 'Tidak Ada Kiriman Menuju Ruangan',
                        message: 'Saat ini belum ada pengiriman barang dari gudang sentral yang sedang dalam perjalanan.',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final sppb = list[index];
                    return SppbCardItem(
                      item: sppb,
                      onTerimaTap: canKonfirmasiDiRuangan
                          ? () async {
                              final confirmed = await AppConfirmDialog.show(
                                context,
                                title: 'Konfirmasi Terima Barang SPPB',
                                message:
                                    'Konfirmasi bahwa komoditas pada dokumen ${sppb.kode} telah diterima secara fisik di ruangan?',
                                confirmLabel: 'Ya, Terima Barang',
                                confirmColor: AppColors.success,
                                icon: LucideIcons.checkCheck,
                              );
                              if (!confirmed || !context.mounted) return;

                              final notifier = ref.read(amprahActionProvider.notifier);
                              final ok = await notifier.konfirmasiTerimaSppb(sppb.id);
                              if (!context.mounted) return;
                              final s = ref.read(amprahActionProvider);
                              if (ok) {
                                AppToast.success(context, s.successMessage ?? 'Barang berhasil diterima di ruangan.');
                              } else {
                                AppToast.error(context, s.errorMessage ?? 'Gagal memproses penerimaan.');
                              }
                            }
                          : null,
                    );
                  },
                );
              },
              loading: () => const AppLoadingView(),
              error: (err, _) => AppErrorView(
                title: 'Gagal Memuat SPPB Masuk',
                error: err,
                onRetry: () => ref.invalidate(sppbInboundProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membuat chip filter status; menandai pilihan aktif dan mengubah filter daftar saat diketuk.
  Widget _buildPill(String value, String label) {
    final isSelected = _statusFilter == value;

    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tintVioletBg : AppColors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Menampilkan lencana jumlah pada tab; disembunyikan bila jumlahnya nol.
  Widget _buildBadge(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tintBlueBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.tintBlue),
      ),
    );
  }
}
