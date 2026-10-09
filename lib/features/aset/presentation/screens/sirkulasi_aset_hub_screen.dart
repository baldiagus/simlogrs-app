import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../widgets/modal_pengembalian_aset_sheet.dart';
import '../widgets/modal_otorisasi_peminjaman_sheet.dart';
import '../widgets/modal_perpanjang_peminjaman_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/peminjaman_aset_model.dart';
import '../../../master/presentation/providers/register_aset_provider.dart';
import '../providers/peminjaman_provider.dart';
import '../widgets/peminjaman_card_item.dart';
import 'form_peminjaman_aset_screen.dart';
import 'qr_scanner_screen.dart';

class SirkulasiAsetHubScreen extends ConsumerStatefulWidget {
  const SirkulasiAsetHubScreen({super.key});

  @override
  ConsumerState<SirkulasiAsetHubScreen> createState() => _SirkulasiAsetHubScreenState();
}

class _SirkulasiAsetHubScreenState extends ConsumerState<SirkulasiAsetHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _canApprove = false;
  String _subPerspektifSiapKembali = 'dipinjam'; // 'dipinjam' (peminjam) atau 'dipinjamkan' (penyedia)

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _canApprove = (user?.can('update_layanan_unit::approval::peminjaman') ?? false) ||
        (user?.can('layanan_unit::approval::peminjaman') ?? false) ||
        (user?.can('view_any_layanan_unit::approval::karu') ?? false) ||
        (user?.hasRole('kepala_unit') ?? false) ||
        (user?.hasRole('kepala_gudang') ?? false) ||
        (user?.hasRole('kepala_teknisi') ?? false) ||
        (user?.hasRole('admin_logistik') ?? false) ||
        (user?.hasRole('super_admin') ?? false);

    _tabController = TabController(length: _canApprove ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showReturnModal(BuildContext context, PeminjamanAsetModel item) {
    if (item.items.isEmpty) return;
    final firstItem = item.items.first;
    ModalPengembalianAsetSheet.show(
      context,
      peminjamanId: item.id,
      detailId: firstItem.id,
      asetId: firstItem.asetId,
      kodeDokumen: item.kode,
      namaBarang: firstItem.namaKomoditas,
      onSuccess: () {
        ref.invalidate(daftarPeminjamanSayaProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider);
        ref.invalidate(registerAsetListProvider);
        ref.invalidate(dashboardSummaryProvider);
      },
    );
  }


  void _showOtorisasiModal(BuildContext context, ApprovalPeminjamanModel item, String aksi) {
    ModalOtorisasiPeminjamanSheet.show(
      context,
      item: item,
      aksi: aksi,
      onSuccess: () {
        ref.invalidate(daftarApprovalPeminjamanProvider);
        ref.invalidate(daftarPeminjamanSayaProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider);
        ref.invalidate(registerAsetListProvider);
        ref.invalidate(dashboardSummaryProvider);
      },
    );
  }

  void _showPerpanjangModal(BuildContext context, PeminjamanAsetModel item) {
    ModalPerpanjangPeminjamanSheet.show(
      context,
      peminjamanId: item.id,
      kodeDokumen: item.kode,
      tanggalKembaliSaatIni: item.tanggalKembaliRencana,
      onSuccess: () {
        ref.invalidate(daftarPeminjamanSayaProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamProvider);
        ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider);
        ref.invalidate(dashboardSummaryProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final canApproveNow = (user?.can('update_layanan_unit::approval::peminjaman') ?? false) ||
        (user?.can('layanan_unit::approval::peminjaman') ?? false) ||
        (user?.can('view_any_layanan_unit::approval::karu') ?? false) ||
        (user?.hasRole('kepala_unit') ?? false) ||
        (user?.hasRole('kepala_gudang') ?? false) ||
        (user?.hasRole('kepala_teknisi') ?? false) ||
        (user?.hasRole('admin_logistik') ?? false) ||
        (user?.hasRole('super_admin') ?? false);

    if (canApproveNow != _canApprove) {
      _canApprove = canApproveNow;
      _tabController.dispose();
      _tabController = TabController(length: _canApprove ? 3 : 2, vsync: this);
    }

    final peminjamanSayaAsync = ref.watch(daftarPeminjamanSayaProvider);
    final approvalPeminjamanAsync = ref.watch(daftarApprovalPeminjamanProvider);
    final peminjamanAktifDipinjamAsync = ref.watch(daftarPeminjamanAktifDipinjamProvider);
    final peminjamanAktifDipinjamkanAsync = ref.watch(daftarPeminjamanAktifDipinjamkanProvider);
    final totalSiapKembali = (peminjamanAktifDipinjamAsync.valueOrNull?.length ?? 0) +
        (peminjamanAktifDipinjamkanAsync.valueOrNull?.length ?? 0);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Sirkulasi Aset RS'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.qrCode, size: 20),
            tooltip: 'Buka Kamera Scanner',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Segarkan Data',
            onPressed: () {
              ref.invalidate(daftarPeminjamanSayaProvider);
              ref.invalidate(daftarApprovalPeminjamanProvider);
              ref.invalidate(daftarPeminjamanAktifDipinjamProvider);
              ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: [
            Tab(
              child: Text(
                (user?.isKepalaGudang == true || user?.isAdminLogistik == true || (user?.gudang != null && user?.isManajemen != true && user?.isAuditor != true))
                    ? 'Peminjaman Gudang'
                    : 'Pinjaman Saya',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_canApprove)
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Flexible(
                      child: Text(
                        'Otorisasi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildBadge(approvalPeminjamanAsync.valueOrNull?.length ?? 0),
                  ],
                ),
              ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Text(
                      'Siap Kembali',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildBadge(totalSiapKembali),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: (user?.unit != null)
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const FormPeminjamanAsetScreen()),
                );
                if (created == true && context.mounted) {
                  ref.invalidate(daftarPeminjamanSayaProvider);
                  ref.invalidate(daftarApprovalPeminjamanProvider);
                  ref.invalidate(dashboardSummaryProvider);
                }
              },
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Pinjam Aset Baru', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Peminjaman Saya
          peminjamanSayaAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(daftarPeminjamanSayaProvider),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: EmptyStateView(
                        icon: LucideIcons.armchair,
                        title: 'Belum Ada Peminjaman',
                        message: (user?.isKepalaGudang == true || user?.isAdminLogistik == true || user?.gudang != null)
                            ? 'Belum ada unit fasilitas gudang yang sedang atau pernah dipinjam oleh ruangan lain.'
                            : 'Unit Anda belum pernah meminjam sarana dari ruangan lain atau gudang.',
                        action: (user?.unit != null)
                            ? ElevatedButton.icon(
                                onPressed: () async {
                                  final created = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(builder: (_) => const FormPeminjamanAsetScreen()),
                                  );
                                  if (created == true && context.mounted) {
                                    ref.invalidate(daftarPeminjamanSayaProvider);
                                    ref.invalidate(daftarApprovalPeminjamanProvider);
                                    ref.invalidate(dashboardSummaryProvider);
                                  }
                                },
                                icon: const Icon(LucideIcons.plus, size: 16),
                                label: const Text('Ajukan Peminjaman'),
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(daftarPeminjamanSayaProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return PeminjamanCardItem(
                      item: item,
                      onExtendTap: item.isDipinjam ? () => _showPerpanjangModal(context, item) : null,
                      onReturnTap: null,
                      onCancelTap: item.isDiajukan
                          ? () async {
                              final notifier = ref.read(peminjamanActionProvider.notifier);
                              final ok = await notifier.batalkanPeminjaman(item.id);
                              if (!context.mounted) return;
                              final state = ref.read(peminjamanActionProvider);
                              if (ok) {
                                AppToast.success(context, state.successMessage ?? 'Dibatalkan');
                              } else {
                                AppToast.error(context, state.errorMessage ?? 'Gagal');
                              }
                            }
                          : null,
                    );
                  },
                ),
              );
            },
            loading: () => const AppLoadingView(),
            error: (err, _) => AppErrorView(error: err, onRetry: () => ref.invalidate(daftarPeminjamanSayaProvider)),
          ),

          // Tab 2: Otorisasi Masuk (Karu & Kagud)
          if (_canApprove)
            approvalPeminjamanAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(daftarApprovalPeminjamanProvider),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.65,
                        child: const EmptyStateView(
                          icon: LucideIcons.shieldCheck,
                          title: 'Tidak Ada Antrean Otorisasi',
                          message: 'Tidak ada permohonan peminjaman aset masuk yang memerlukan persetujuan saat ini.',
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(daftarApprovalPeminjamanProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.tintVioletBg, borderRadius: BorderRadius.circular(8)),
                                  child: Text(item.kode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                                ),
                                StatusBadge(status: item.status),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(item.namaAset, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text('Kode: ${item.kodeAset} • Pemohon: ${item.unitPeminjam} (${item.pengaju})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Jadwal: ${item.tanggalPinjam} s/d ${item.tanggalKembaliRencana}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            if (item.keperluan.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Keperluan: ${item.keperluan}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                            ],
                            const SizedBox(height: 14),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 10),

                            // Action buttons
                            if (item.isDiajukan)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _showOtorisasiModal(context, item, 'tolak'),
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFCA5A5))),
                                      child: const Text('Tolak', style: TextStyle(color: AppColors.danger)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _showOtorisasiModal(context, item, 'setujui'),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                                      child: const Text('Setujui Pinjam'),
                                    ),
                                  ),
                                ],
                              )
                            else if (item.isDisetujui)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showOtorisasiModal(context, item, 'serah_terima'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white),
                                  icon: const Icon(LucideIcons.arrowRightLeft, size: 16),
                                  label: const Text('Serah Terima Fisik ke Peminjam'),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const AppLoadingView(),
              error: (err, _) => AppErrorView(error: err, onRetry: () => ref.invalidate(daftarApprovalPeminjamanProvider)),
            ),

          // Tab 3: Siap Pengembalian (Perspektif: Dipinjam vs Dipinjamkan)
          Column(
            children: [
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSubTabPill(
                        title: 'Aset Dipinjam',
                        count: peminjamanAktifDipinjamAsync.valueOrNull?.length ?? 0,
                        isActive: _subPerspektifSiapKembali == 'dipinjam',
                        onTap: () => setState(() => _subPerspektifSiapKembali = 'dipinjam'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSubTabPill(
                        title: 'Aset Dipinjamkan',
                        count: peminjamanAktifDipinjamkanAsync.valueOrNull?.length ?? 0,
                        isActive: _subPerspektifSiapKembali == 'dipinjamkan',
                        onTap: () => setState(() => _subPerspektifSiapKembali = 'dipinjamkan'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: _subPerspektifSiapKembali == 'dipinjam'
                    ? _buildListDipinjam(peminjamanAktifDipinjamAsync)
                    : _buildListDipinjamkan(peminjamanAktifDipinjamkanAsync),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tintVioletBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
      ),
    );
  }
  Widget _buildListDipinjam(AsyncValue<List<PeminjamanAsetModel>> asyncData) {
    return asyncData.when(
      data: (list) {
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(daftarPeminjamanAktifDipinjamProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: const EmptyStateView(
                  icon: LucideIcons.packageCheck,
                  title: 'Tidak Ada Aset Dipinjam',
                  message: 'Unit Anda saat ini tidak memiliki tanggungan peminjaman aset dari unit lain atau gudang.',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(daftarPeminjamanAktifDipinjamProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return PeminjamanCardItem(
                item: item,
                isPenyediaPerspective: false,
                onExtendTap: () => _showPerpanjangModal(context, item),
                onReturnTap: null,
              );
            },
          ),
        );
      },
      loading: () => const AppLoadingView(),
      error: (err, _) => AppErrorView(error: err, onRetry: () => ref.invalidate(daftarPeminjamanAktifDipinjamProvider)),
    );
  }

  Widget _buildListDipinjamkan(AsyncValue<List<PeminjamanAsetModel>> asyncData) {
    final user = ref.watch(authStateProvider).user;
    final isGudang = user?.isKepalaGudang == true || user?.isAdminLogistik == true || user?.gudang != null;

    return asyncData.when(
      data: (list) {
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: EmptyStateView(
                  icon: LucideIcons.armchair,
                  title: 'Tidak Ada Aset Dipinjamkan',
                  message: isGudang
                      ? 'Seluruh aset inventaris fasilitas gudang saat ini berada di tempat (tidak ada yang sedang dipinjam unit luar).'
                      : 'Seluruh aset inventaris unit Anda saat ini berada di tempat (tidak ada yang sedang dipinjam unit lain).',
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return PeminjamanCardItem(
                item: item,
                isPenyediaPerspective: true,
                onReturnTap: () => _showReturnModal(context, item),
              );
            },
          ),
        );
      },
      loading: () => const AppLoadingView(),
      error: (err, _) => AppErrorView(error: err, onRetry: () => ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider)),
    );
  }

  Widget _buildSubTabPill({
    required String title,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.tintVioletBg : AppColors.canvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.primaryPurple : AppColors.border,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? AppColors.primaryPurple : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryPurple : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
