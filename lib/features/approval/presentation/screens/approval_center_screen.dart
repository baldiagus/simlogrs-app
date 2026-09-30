import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_filter_chip_bar.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../widgets/approval_action_modal.dart';
import '../widgets/approval_po_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pengadaan/data/models/po_model.dart';
import '../../../pengadaan/presentation/providers/pengadaan_provider.dart';
import '../../data/models/approval_item_model.dart';
import '../providers/approval_provider.dart';
import '../widgets/approval_card.dart';
import '../../../pengadaan/presentation/widgets/terbitkan_po_sheet.dart';
class ApprovalCenterScreen extends ConsumerStatefulWidget {
  const ApprovalCenterScreen({super.key});

  @override
  ConsumerState<ApprovalCenterScreen> createState() => _ApprovalCenterScreenState();
}

class _ApprovalCenterScreenState extends ConsumerState<ApprovalCenterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _poSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _poSearchCtrl.dispose();
    super.dispose();
  }

  void _showActionModal({
    required ApprovalItemModel item,
    required String aksi,
  }) {
    ApprovalActionModal.show(context, item: item, aksi: aksi);
  }

  // -------------------------------------------------------------
  // MODAL TERBITKAN PO DARI PR DISETUJUI
  // -------------------------------------------------------------
  void _showTerbitkanPoModal(BuildContext context, ApprovalItemModel item) {
    TerbitkanPoSheet.show(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(approvalPendingProvider);
    final user = ref.watch(authStateProvider).user;
    final isPengadaanFlow = (user?.isPengadaan == true) ||
        (user?.isAdminLogistik == true) ||
        (user?.isManajemen == true) ||
        (user?.isAuditor == true) ||
        (user?.hasRole('super_admin') == true);
    final poListAsync = isPengadaanFlow ? ref.watch(poListProvider) : null;

    final isPengadaanUser = (user?.isPengadaan == true) &&
        !(user?.hasRole('super_admin') == true) &&
        !(user?.isAdminLogistik == true);
    final canManagePo = (user?.isPengadaan == true) ||
        (user?.isAdminLogistik == true) ||
        (user?.hasRole('super_admin') == true);
    final isReadOnly = (user?.isManajemen == true) || (user?.isAuditor == true);
    final canApprovePr = isPengadaanUser
        ? false
        : (user?.can('update_pengadaan::permintaan::pengadaan') ?? false);
    final isKaru = user?.isKaru ?? false;
    final isGudangUser = (user?.isGudangUser ?? false) || (user?.isKepalaGudang ?? false);
    final canApproveAmprah = (user?.can('update_layanan_unit::approval::karu') ?? false) ||
        (user?.can('update_gudang_stok::distribusi::approval') ?? false) ||
        (user?.hasRole('admin_logistik') ?? false) ||
        (user?.hasRole('kepala_gudang') ?? false) ||
        (user?.hasRole('super_admin') ?? false);

    final totalPrBadge = isPengadaanUser
        ? (pendingAsync.valueOrNull?.prList.where((pr) => pr.status == 'DISETUJUI' || pr.status == 'DITERUSKAN_KE_PENGADAAN').length ?? 0)
        : (pendingAsync.valueOrNull?.totalPr ?? 0);

    final totalAmprahBadge = isGudangUser
        ? (pendingAsync.valueOrNull?.amprahList.where((a) => a.status == 'DISETUJUI_KARU').length ?? 0)
        : (isKaru
            ? (pendingAsync.valueOrNull?.amprahList.where((a) => a.status == 'DIAJUKAN').length ?? 0)
            : (pendingAsync.valueOrNull?.totalAmprah ?? 0));
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Approval Center'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pengadaan (PR)'),
                  const SizedBox(width: 6),
                  _buildCountBadge(totalPrBadge),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isPengadaanFlow ? 'Pesanan (PO)' : 'Amprah Ruangan'),
                  const SizedBox(width: 6),
                  _buildCountBadge(
                    isPengadaanFlow
                        ? (poListAsync?.valueOrNull?.length ?? 0)
                        : totalAmprahBadge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: pendingAsync.when(
        data: (pending) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: PR List
              _buildList(
                items: isPengadaanUser
                    ? pending.prList.where((pr) => pr.status == 'DISETUJUI' || pr.status == 'DITERUSKAN_KE_PENGADAAN').toList()
                    : pending.prList,
                emptyTitle: 'Tidak Ada Antrean PR',
                emptyMessage: isPengadaanUser
                    ? 'Belum ada dokumen Permintaan Pengadaan yang disetujui untuk diterbitkan PO.'
                    : 'Semua dokumen Permintaan Pengadaan telah disetujui atau belum ada pengajuan baru.',
                canApprove: isReadOnly ? false : canApprovePr,
                onTerbitkanPoTap: canManagePo ? (item) => _showTerbitkanPoModal(context, item) : null,
              ),

              // Tab 2: Pesanan PO (untuk Pengadaan/Admin/Manajemen/Auditor) atau Amprah Ruangan
              if (isPengadaanFlow)
                _buildPoListTab(canManagePo: canManagePo, isReadOnly: isReadOnly)
              else
                _buildList(
                  items: isGudangUser
                      ? pending.amprahList.where((a) => a.status == 'DISETUJUI_KARU').toList()
                      : (isKaru
                          ? pending.amprahList.where((a) => a.status == 'DIAJUKAN').toList()
                          : pending.amprahList),
                  emptyTitle: 'Tidak Ada Antrean Amprah',
                  emptyMessage: isGudangUser
                      ? 'Tidak ada permohonan amprah yang menunggu otorisasi pengeluaran barang gudang.'
                      : 'Semua permintaan distribusi ruangan telah diproses.',
                  canApprove: isReadOnly ? false : canApproveAmprah,
                ),
            ],
          );
        },
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          title: 'Gagal Memuat Antrean',
          error: err,
          onRetry: () => ref.invalidate(approvalPendingProvider),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: PESANAN PEMBELIAN (PO)
  // -------------------------------------------------------------
  Widget _buildPoListTab({required bool canManagePo, required bool isReadOnly}) {
    final filterStatus = ref.watch(poStatusFilterProvider);
    final poListAsync = ref.watch(poListProvider);

    return Column(
      children: [
        // Status filter pills & Search bar
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _poSearchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari kode PO atau nama rekanan vendor...',
                  prefixIcon: const Icon(LucideIcons.search, size: 16),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.canvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (val) {
                  ref.read(poSearchQueryProvider.notifier).state = val.trim();
                },
              ),
              const SizedBox(height: 8),
              AppFilterChipBar<String>(
                padding: EdgeInsets.zero,
                selected: filterStatus,
                onSelected: (val) {
                  ref.read(poStatusFilterProvider.notifier).state = val;
                },
                options: const [
                  AppFilterOption(label: 'Semua PO', value: 'SEMUA'),
                  AppFilterOption(label: 'Diterbitkan', value: 'DITERBITKAN'),
                  AppFilterOption(label: 'Dikirim Vendor', value: 'DIKIRIM_VENDOR'),
                  AppFilterOption(label: 'Diterima Sebagian', value: 'DITERIMA_SEBAGIAN'),
                  AppFilterOption(label: 'Selesai', value: 'DITERIMA_LENGKAP'),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // List PO
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.refresh(poListProvider),
            child: poListAsync.when(
              data: (pos) {
                if (pos.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: const EmptyStateView(
                        icon: LucideIcons.truck,
                        title: 'Tidak Ada Pesanan PO',
                        message: 'Belum ada dokumen PO yang diterbitkan atau cocok dengan filter.',
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: pos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => ApprovalPoCard(
                    po: pos[i],
                    canManagePo: canManagePo,
                    isReadOnly: isReadOnly,
                    onUpdateKirim: () => _confirmUpdateKirim(context, pos[i]),
                  ),
                );
              },
              loading: () => const AppLoadingView(),
              error: (err, _) => AppErrorView(
                title: 'Gagal Memuat PO',
                error: err,
                onRetry: () => ref.refresh(poListProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Future<void> _confirmUpdateKirim(BuildContext context, PesananPembelianModel po) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Konfirmasi Pengiriman Vendor',
      message:
          'Ubah status pesanan ${po.kode} (Vendor: ${po.namaPemasok}) menjadi DIKIRIM_VENDOR? Menandakan barang pesanan sedang dalam proses ekspedisi.',
      confirmLabel: 'Ya, Tandai Dikirim',
      confirmColor: AppColors.tintBlue,
      icon: LucideIcons.truck,
    );
    if (!confirmed || !context.mounted) return;
    final notifier = ref.read(poActionProvider.notifier);
    final ok = await notifier.updateStatusKirim(po.id);
    if (!context.mounted) return;
    final s = ref.read(poActionProvider);
    if (ok) {
      AppToast.success(context, s.successMessage ?? 'Status berhasil diperbarui');
    } else {
      AppToast.error(context, s.errorMessage ?? 'Gagal');
    }
  }

  Widget _buildList({
    required List<ApprovalItemModel> items,
    required String emptyTitle,
    required String emptyMessage,
    required bool canApprove,
    void Function(ApprovalItemModel item)? onTerbitkanPoTap,
  }) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => ref.invalidate(approvalPendingProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: EmptyStateView(
              icon: LucideIcons.checkCheck,
              title: emptyTitle,
              message: emptyMessage,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(approvalPendingProvider),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ApprovalCard(
            item: item,
            canApprove: canApprove,
            onApproveTap: () => _showActionModal(item: item, aksi: 'setujui'),
            onRejectTap: () => _showActionModal(item: item, aksi: 'tolak'),
            onSerahkanTap: () => _showActionModal(item: item, aksi: 'serahkan'),
            onTerbitkanPoTap: onTerbitkanPoTap != null ? () => onTerbitkanPoTap(item) : null,
          );
        },
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: count > 0 ? AppColors.tintVioletBg : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: count > 0 ? AppColors.primaryPurple : AppColors.textMuted,
        ),
      ),
    );
  }
}

