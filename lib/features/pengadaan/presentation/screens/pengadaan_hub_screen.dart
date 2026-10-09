import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_filter_chip_bar.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../approval/presentation/providers/approval_provider.dart';
import '../../../approval/presentation/widgets/approval_po_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../gudang/data/models/po_inbound_model.dart';
import '../../../gudang/presentation/providers/inbound_provider.dart';
import '../../../gudang/presentation/screens/form_penerimaan_po_screen.dart';
import '../../data/models/po_model.dart';
import '../../data/models/pr_model.dart';
import '../providers/pengadaan_provider.dart';
import '../widgets/pr_detail_sheet.dart';
import '../widgets/riwayat_pr_card_item.dart';
import '../widgets/terbitkan_po_sheet.dart';
import 'form_pengajuan_pr_screen.dart';

class PengadaanHubScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const PengadaanHubScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<PengadaanHubScreen> createState() => _PengadaanHubScreenState();
}

class _PengadaanHubScreenState extends ConsumerState<PengadaanHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _prQuery = '';
  String _prFilter = 'SEMUA';
  String _poQuery = '';
  String _inboundQuery = '';

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    final canViewInbound = (user?.can('view_any_gudang_stok::penerimaan::po') == true) ||
        (user?.isGudangUser == true) ||
        (user?.isManajemen == true) ||
        (user?.isAuditor == true) ||
        (user?.isSuperAdmin == true) ||
        (user?.isAdminLogistik == true);
    final count = canViewInbound ? 3 : 2;
    _tabController = TabController(
      length: count,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, count - 1),
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showSetujuiPrDialog(BuildContext context, PrHeaderModel pr) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Konfirmasi Persetujuan PR',
      message:
          'Setujui permohonan pengadaan ${pr.kode} dari ${pr.unit}?\n\nDokumen akan berstatus DISETUJUI dan siap diteruskan ke Bagian Pengadaan.',
      confirmLabel: 'Ya, Setujui PR',
      confirmColor: AppColors.success,
      icon: LucideIcons.checkCheck,
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref.read(approvalActionProvider.notifier).approvePr(
          id: pr.id,
          aksi: 'setujui',
        );
    if (!context.mounted) return;
    final state = ref.read(approvalActionProvider);
    if (ok) {
      AppToast.success(context, state.successMessage ?? 'PR berhasil disetujui.');
      ref.invalidate(daftarPrProvider);
      ref.invalidate(approvalPendingProvider);
      ref.invalidate(dashboardSummaryProvider);
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal menyetujui PR.');
    }
  }

  Future<void> _showTeruskanPrDialog(BuildContext context, PrHeaderModel pr) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Teruskan PR ke Pengadaan',
      message: 'Teruskan PR ${pr.kode} ke Bagian Pengadaan untuk proses penerbitan PO?',
      confirmLabel: 'Ya, Teruskan',
      confirmColor: AppColors.primaryPurple,
      icon: LucideIcons.send,
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref.read(approvalActionProvider.notifier).approvePr(
          id: pr.id,
          aksi: 'teruskan',
        );
    if (!context.mounted) return;
    final state = ref.read(approvalActionProvider);
    if (ok) {
      AppToast.success(context, state.successMessage ?? 'PR diteruskan ke Bagian Pengadaan.');
      ref.invalidate(daftarPrProvider);
      ref.invalidate(approvalPendingProvider);
      ref.invalidate(dashboardSummaryProvider);
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal meneruskan PR.');
    }
  }

  void _showTolakPrDialog(BuildContext context, PrHeaderModel pr, {bool isPengadaan = false}) {
    final catatanCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPengadaan ? 'Tolak oleh Tim Pengadaan' : 'Tolak Permohonan PR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPengadaan
                  ? 'Masukkan alasan penolakan belanja untuk PR ${pr.kode}:'
                  : 'Masukkan catatan penolakan untuk PR ${pr.kode}:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: catatanCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Misal: Melebihi plafon pagu atau barang tidak tersedia...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final catatan = catatanCtrl.text.trim();
              if (catatan.isEmpty) {
                AppToast.error(context, 'Alasan penolakan wajib dicantumkan.');
                return;
              }
              Navigator.pop(ctx);
              final ok = await ref.read(approvalActionProvider.notifier).approvePr(
                    id: pr.id,
                    aksi: 'tolak',
                    catatan: catatan,
                  );
              if (!context.mounted) return;
              final state = ref.read(approvalActionProvider);
              if (ok) {
                AppToast.success(context, state.successMessage ?? 'PR telah ditolak.');
                ref.invalidate(daftarPrProvider);
                ref.invalidate(approvalPendingProvider);
                ref.invalidate(dashboardSummaryProvider);
              } else {
                AppToast.error(context, state.errorMessage ?? 'Gagal menolak PR.');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Ya, Tolak PR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUpdateKirimPo(BuildContext context, PesananPembelianModel po) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Konfirmasi Pengiriman Vendor',
      message:
          'Ubah status pesanan ${po.kode} (Vendor: ${po.namaPemasok}) menjadi DIKIRIM_VENDOR? Menandakan barang pesanan sedang dalam perjalanan ekspedisi ke gudang.',
      confirmLabel: 'Ya, Tandai Dikirim',
      confirmColor: AppColors.tintBlue,
      icon: LucideIcons.truck,
    );
    if (!confirmed || !context.mounted) return;

    final notifier = ref.read(poActionProvider.notifier);
    final ok = await notifier.updateStatusKirim(po.id);
    if (!context.mounted) return;

    final state = ref.read(poActionProvider);
    if (ok) {
      AppToast.success(context, state.successMessage ?? 'Status pesanan berhasil ditandai dikirim vendor.');
      ref.invalidate(poListProvider);
      ref.invalidate(daftarPoInboundProvider);
      ref.invalidate(dashboardSummaryProvider);
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal memperbarui status pengiriman PO.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final isPengadaan = user?.isPengadaan ?? false;
    final isSuperAdmin = user?.hasRole('super_admin') ?? false;
    final isAdminLogistik = user?.isAdminLogistik ?? false;
    final isKaru = user?.isKaru ?? false;
    final isGudangUser = user?.isGudangUser ?? false;

    final canApproveKaru = !isPengadaan &&
        (isKaru ||
            isGudangUser ||
            isAdminLogistik ||
            isSuperAdmin ||
            (user?.can('update_pengadaan::permintaan::pengadaan') ?? false));

    final canManagePo = isPengadaan || isAdminLogistik || isSuperAdmin;

    final canCreatePr = !isPengadaan &&
        ((user?.can('create_pengadaan::permintaan::pengadaan') ?? false) ||
            (user?.hasRole('petugas_unit') ?? false) ||
            (user?.hasRole('kepala_unit') ?? false) ||
            isSuperAdmin);
    final actionablePoCount = ref.watch(poActionableCountProvider).valueOrNull ?? 0;

    final canViewInbound = (user?.can('view_any_gudang_stok::penerimaan::po') == true) ||
        (user?.isGudangUser == true) ||
        (user?.isManajemen == true) ||
        (user?.isAuditor == true) ||
        (user?.isSuperAdmin == true) ||
        (user?.isAdminLogistik == true);
    final expectedLength = canViewInbound ? 3 : 2;
    if (_tabController.length != expectedLength) {
      final oldIndex = _tabController.index.clamp(0, expectedLength - 1);
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
      _tabController = TabController(
        length: expectedLength,
        vsync: this,
        initialIndex: oldIndex,
      );
      _tabController.addListener(_onTabChanged);
    }
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Hub Pengadaan & PO'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Segarkan Data',
            onPressed: () {
              ref.invalidate(daftarPrProvider);
              ref.invalidate(poListProvider);
              ref.invalidate(daftarPoInboundProvider);
              ref.invalidate(dashboardSummaryProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            const Tab(text: 'Permintaan (PR)'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pesanan (PO)'),
                  if (actionablePoCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$actionablePoCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canViewInbound)
              const Tab(text: 'Penerimaan Inbound'),
          ],
        ),
      ),
      floatingActionButton: (canCreatePr && _tabController.index == 0)
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const FormPengajuanPrScreen()),
                );
                if (created == true && context.mounted) {
                  ref.invalidate(daftarPrProvider);
                  ref.invalidate(dashboardSummaryProvider);
                }
              },
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Ajukan PR Baru', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPrTab(
            isPengadaan: isPengadaan,
            canApproveKaru: canApproveKaru,
            canManagePo: canManagePo,
          ),
          _buildPoTab(canManagePo: canManagePo),
          if (canViewInbound)
            _buildInboundTab(isGudangUser: isGudangUser || isAdminLogistik || isSuperAdmin),
        ],
      ),
    );
  }

  Widget _buildPrTab({
    required bool isPengadaan,
    required bool canApproveKaru,
    required bool canManagePo,
  }) {
    final prListAsync = ref.watch(daftarPrProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.surface,
          child: Column(
            children: [
              AppSearchBar(
                hint: 'Cari kode PR, nama pengaju, atau unit...',
                onChanged: (val) => setState(() => _prQuery = val.trim().toLowerCase()),
                onClear: () => setState(() => _prQuery = ''),
              ),
              const SizedBox(height: 8),
              AppFilterChipBar<String>(
                padding: EdgeInsets.zero,
                selected: _prFilter,
                onSelected: (val) => setState(() => _prFilter = val),
                options: const [
                  AppFilterOption(label: 'Semua Status', value: 'SEMUA'),
                  AppFilterOption(label: 'Menunggu Otorisasi', value: PrStatus.diajukan),
                  AppFilterOption(label: 'Siap Terbitkan PO', value: PrStatus.diteruskanKePengadaan),
                  AppFilterOption(label: 'Disetujui', value: PrStatus.disetujui),
                  AppFilterOption(label: 'Ditolak', value: PrStatus.ditolak),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryPurple,
            onRefresh: () async => ref.invalidate(daftarPrProvider),
            child: prListAsync.when(
              data: (list) {
                var filtered = list;
                if (_prFilter != 'SEMUA') {
                  filtered = filtered.where((pr) => pr.status == _prFilter).toList();
                }
                if (_prQuery.isNotEmpty) {
                  filtered = filtered.where((pr) {
                    final matchKode = pr.kode.toLowerCase().contains(_prQuery);
                    final matchUnit = pr.unit.toLowerCase().contains(_prQuery);
                    final matchPengaju = pr.pengaju.toLowerCase().contains(_prQuery);
                    return matchKode || matchUnit || matchPengaju;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: EmptyStateView(
                        title: 'Tidak Ada Data PR',
                        message: 'Belum ada dokumen permohonan pengadaan yang sesuai dengan filter.',
                        icon: LucideIcons.fileSpreadsheet,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final pr = filtered[idx];
                    return RiwayatPrCardItem(
                      pr: pr,
                      canApproveKaru: canApproveKaru,
                      canManagePo: canManagePo,
                      onDetailTap: () => PrDetailSheet.show(
                        context,
                        pr: pr,
                        canApproveKaru: canApproveKaru,
                        canManagePo: canManagePo,
                        onSetujui: () => _showSetujuiPrDialog(context, pr),
                        onTolak: () => _showTolakPrDialog(context, pr, isPengadaan: isPengadaan),
                        onTeruskan: () => _showTeruskanPrDialog(context, pr),
                        onTerbitkanPo: () => TerbitkanPoSheet.show(context, pr.toApprovalItem()),
                      ),
                      onSetujuiTap: () => _showSetujuiPrDialog(context, pr),
                      onTolakTap: () => _showTolakPrDialog(context, pr, isPengadaan: false),
                      onTeruskanTap: () => _showTeruskanPrDialog(context, pr),
                      onTerbitkanPoTap: () => TerbitkanPoSheet.show(context, pr.toApprovalItem()),
                    );
                  },
                );
              },
              loading: () => const AppLoadingView(),
              error: (err, _) => AppErrorView(
                title: 'Gagal Memuat Daftar PR',
                error: err,
                onRetry: () => ref.invalidate(daftarPrProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPoTab({required bool canManagePo}) {
    final poListAsync = ref.watch(poListProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surface,
          child: AppSearchBar(
            hint: 'Cari kode PO, rekanan vendor, atau kode PR...',
            onChanged: (val) => setState(() => _poQuery = val.trim().toLowerCase()),
            onClear: () => setState(() => _poQuery = ''),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryPurple,
            onRefresh: () async => ref.invalidate(poListProvider),
            child: poListAsync.when(
              data: (list) {
                var filtered = list;
                if (_poQuery.isNotEmpty) {
                  filtered = filtered.where((po) {
                    final matchNomor = po.kode.toLowerCase().contains(_poQuery);
                    final matchVendor = po.namaPemasok.toLowerCase().contains(_poQuery);
                    final matchPr = (po.prKode ?? '').toLowerCase().contains(_poQuery);
                    return matchNomor || matchVendor || matchPr;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: EmptyStateView(
                        title: 'Tidak Ada Dokumen PO',
                        message: 'Belum ada Purchase Order yang aktif atau sesuai dengan kriteria pencarian.',
                        icon: LucideIcons.shoppingBag,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final po = filtered[idx];
                    return ApprovalPoCard(
                      po: po,
                      canManagePo: canManagePo,
                      isReadOnly: !canManagePo,
                      onUpdateKirim: () => _confirmUpdateKirimPo(context, po),
                    );
                  },
                );
              },
              loading: () => const AppLoadingView(),
              error: (err, _) => AppErrorView(
                title: 'Gagal Memuat Daftar PO',
                error: err,
                onRetry: () => ref.invalidate(poListProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInboundTab({required bool isGudangUser}) {
    final inboundAsync = ref.watch(daftarPoInboundProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surface,
          child: AppSearchBar(
            hint: 'Cari kode PO atau nama rekanan pemasok...',
            onChanged: (val) => setState(() => _inboundQuery = val.trim().toLowerCase()),
            onClear: () => setState(() => _inboundQuery = ''),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryPurple,
            onRefresh: () async => ref.invalidate(daftarPoInboundProvider),
            child: inboundAsync.when(
              data: (list) {
                var filtered = list;
                if (_inboundQuery.isNotEmpty) {
                  filtered = filtered.where((po) {
                    final matchKode = po.kodePo.toLowerCase().contains(_inboundQuery);
                    final matchPemasok = po.pemasok.toLowerCase().contains(_inboundQuery);
                    return matchKode || matchPemasok;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: EmptyStateView(
                        title: 'Tidak Ada Antrean Inbound',
                        message: 'Semua barang pesanan PO telah diterima atau belum ada pengiriman aktif.',
                        icon: LucideIcons.packageCheck,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final item = filtered[idx];
                    return _buildInboundCard(context, item, isGudangUser);
                  },
                );
              },
              loading: () => const AppLoadingView(),
              error: (err, _) => AppErrorView(
                title: 'Gagal Memuat Antrean Inbound',
                error: err,
                onRetry: () => ref.invalidate(daftarPoInboundProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInboundCard(BuildContext context, PoInboundHeaderModel item, bool isGudangUser) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                item.kodePo,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryPurple),
              ),
              StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.pemasok,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.totalItem} Item Barang • Tanggal PO: ${item.tanggalPo}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          if (isGudangUser && item.canReceive) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final ok = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormPenerimaanPoScreen(po: item),
                    ),
                  );
                  if (ok == true && context.mounted) {
                    ref.invalidate(daftarPoInboundProvider);
                    ref.invalidate(dashboardSummaryProvider);
                  }
                },
                icon: const Icon(LucideIcons.packageCheck, size: 16),
                label: const Text('Periksa & Terima Barang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
