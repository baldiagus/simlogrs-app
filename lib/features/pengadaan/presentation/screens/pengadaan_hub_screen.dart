import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../gudang/presentation/providers/inbound_provider.dart';
import '../providers/pengadaan_provider.dart';
import '../widgets/pengadaan_hub_actions.dart';
import '../widgets/pengadaan_hub_inbound_tab.dart';
import '../widgets/pengadaan_hub_po_tab.dart';
import '../widgets/pengadaan_hub_pr_tab.dart';
import 'form_pengajuan_pr_screen.dart';

/// Kunci tab hub pengadaan; urutan tab di TabBar dan TabBarView mengikuti urutan daftar kunci yang berlaku.
enum HubTab { pr, po, inbound }

/// Membangun daftar kunci tab yang berlaku untuk [user]: PR selalu; PO bila pengelola PO, manajemen, atau auditor; Inbound bila berhak melihat penerimaan.
List<HubTab> _resolveTabKeys(UserModel? user) {
  final isPengadaan = user?.isPengadaan ?? false;
  final isSuperAdmin = user?.hasRole('super_admin') ?? false;
  final isAdminLogistik = user?.isAdminLogistik ?? false;
  final canManagePo = isPengadaan || isAdminLogistik || isSuperAdmin;
  final canViewPo = canManagePo ||
      (user?.isManajemen ?? false) ||
      (user?.isAuditor ?? false);
  final canViewInbound =
      (user?.can('view_any_gudang_stok::penerimaan::po') == true) ||
          (user?.isGudangUser == true) ||
          (user?.isManajemen == true) ||
          (user?.isAuditor == true) ||
          (user?.isSuperAdmin == true) ||
          (user?.isAdminLogistik == true);
  return [
    HubTab.pr,
    if (canViewPo) HubTab.po,
    if (canViewInbound) HubTab.inbound,
  ];
}

/// Layar hub pengadaan: tab PR, PO, dan penerimaan inbound sesuai hak akses pengguna.
class PengadaanHubScreen extends ConsumerStatefulWidget {
  /// Tab awal; bila tidak tersedia untuk pengguna, jatuh ke tab PR.
  final HubTab? initialTab;

  const PengadaanHubScreen({
    super.key,
    this.initialTab = HubTab.pr,
  });

  /// Membuat state hub pengadaan (tab PR, PO, riwayat).
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

  /// Menyiapkan TabController sesuai hak akses pengguna dan tab awal yang diminta.
  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    final tabKeys = _resolveTabKeys(user);
    _tabController = TabController(
      length: tabKeys.length,
      vsync: this,
      initialIndex: _indeksAwal(tabKeys),
    );
    _tabController.addListener(_onTabChanged);
  }

  /// Mencari indeks tab awal dari [HubTab] yang diminta; kunci yang tidak tersedia jatuh ke tab PR.
  int _indeksAwal(List<HubTab> tabKeys) {
    final indeks = tabKeys.indexOf(widget.initialTab ?? HubTab.pr);
    return indeks < 0 ? 0 : indeks;
  }

  /// Membangun ulang UI saat tab berganti agar elemen yang bergantung tab (mis. FAB) ikut berubah.
  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  /// Melepas listener dan TabController saat layar ditutup.
  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Membangun hub pengadaan berisi tab PR, PO, dan penerimaan barang sesuai peran pengguna.
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final isPengadaan = user?.isPengadaan ?? false;
    final isSuperAdmin = user?.hasRole('super_admin') ?? false;
    final isAdminLogistik = user?.isAdminLogistik ?? false;
    final isKaru = user?.isKaru ?? false;
    final isKepalaGudang = user?.isKepalaGudang ?? false;

    /// Manajemen dan auditor hanya melihat data (read-only), tanpa aksi approval PR.
    final isReadOnly = (user?.isManajemen ?? false) || (user?.isAuditor ?? false);
    final canApproveKaru = !isPengadaan &&
        !isReadOnly &&
        (isKaru ||
            isKepalaGudang ||
            isAdminLogistik ||
            isSuperAdmin ||
            (user?.can('update_pengadaan::permintaan::pengadaan') ?? false));

    final canManagePo = isPengadaan || isAdminLogistik || isSuperAdmin;

    final canCreatePr = !isPengadaan &&
        ((user?.can('create_pengadaan::permintaan::pengadaan') ?? false) ||
            (user?.hasRole('petugas_unit') ?? false) ||
            (user?.hasRole('kepala_unit') ?? false) ||
            isSuperAdmin);
    final actionablePoCount =
        ref.watch(poActionableCountProvider).valueOrNull ?? 0;
    final actions = PengadaanHubActions(ref);

    final tabKeys = _resolveTabKeys(user);
    if (_tabController.length != tabKeys.length) {
      final oldIndex = _tabController.index.clamp(0, tabKeys.length - 1);
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
      _tabController = TabController(
        length: tabKeys.length,
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
            /// Menyegarkan data PR, PO, dan penerimaan barang dari server.
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
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            for (final key in tabKeys)
              switch (key) {
                HubTab.pr => const Tab(text: 'Permintaan (PR)'),
                HubTab.po => Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Pesanan (PO)'),
                        if (actionablePoCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$actionablePoCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                HubTab.inbound => const Tab(text: 'Penerimaan Inbound'),
              },
          ],
        ),
      ),
      floatingActionButton: (canCreatePr && tabKeys[_tabController.index] == HubTab.pr)
          ? FloatingActionButton.extended(
              heroTag: null,
              /// Membuka form pengajuan PR dan menyegarkan daftar PR bila PR berhasil dibuat.
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FormPengajuanPrScreen()),
                );
                if (created == true && context.mounted) {
                  ref.invalidate(daftarPrProvider);
                  ref.invalidate(dashboardSummaryProvider);
                }
              },
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Ajukan PR Baru',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
            for (final key in tabKeys)
              switch (key) {
              HubTab.pr => PengadaanHubPrTab(
                  prListAsync: ref.watch(daftarPrProvider),
                  query: _prQuery,
                  filter: _prFilter,
                  onQueryChanged: (val) =>
                      setState(() => _prQuery = val.trim().toLowerCase()),
                  onFilterSelected: (val) => setState(() => _prFilter = val),
                  isPengadaan: isPengadaan,
                  canApproveKaru: canApproveKaru,
                  canManagePo: canManagePo,
                  onSetujui: (pr) => actions.setujuiPr(context, pr),
                  onTolak: (pr, isPengadaan) =>
                      actions.tolakPr(context, pr, isPengadaan: isPengadaan),
                  onTeruskan: (pr) => actions.teruskanPr(context, pr),
                ),
              HubTab.po => PengadaanHubPoTab(
                  poListAsync: ref.watch(poListProvider),
                  query: _poQuery,
                  onQueryChanged: (val) =>
                      setState(() => _poQuery = val.trim().toLowerCase()),
                  canManagePo: canManagePo,
                  onUpdateKirim: (po) => actions.confirmUpdateKirimPo(context, po),
                ),
              HubTab.inbound => PengadaanHubInboundTab(
                  inboundAsync: ref.watch(daftarPoInboundProvider),
                  query: _inboundQuery,
                  onQueryChanged: (val) =>
                      setState(() => _inboundQuery = val.trim().toLowerCase()),
                  canReceiveInbound: user?.canReceiveInbound ?? false,
                  onTerima: (item) => actions.terimaInbound(context, item),
                ),
            },
        ],
      ),
    );
  }
}
