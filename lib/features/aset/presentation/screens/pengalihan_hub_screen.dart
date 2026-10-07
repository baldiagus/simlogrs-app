import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/pengalihan_model.dart';
import '../providers/pengalihan_provider.dart';
import '../widgets/modal_pengalihan_aset_sheet.dart';
import '../widgets/modal_pengalihan_barang_sheet.dart';

class PengalihanHubScreen extends ConsumerStatefulWidget {
  const PengalihanHubScreen({super.key});

  @override
  ConsumerState<PengalihanHubScreen> createState() => _PengalihanHubScreenState();
}

class _PengalihanHubScreenState extends ConsumerState<PengalihanHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _canApprove = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _canApprove = (user?.can('layanan_unit::approval::peminjaman') ?? false) ||
        (user?.can('view_any_layanan_unit::approval::karu') ?? false) ||
        (user?.hasRole('kepala_unit') ?? false) ||
        (user?.hasRole('kepala_gudang') ?? false) ||
        (user?.hasRole('admin_logistik') ?? false) ||
        (user?.hasRole('manajemen') ?? false) ||
        (user?.hasRole('super_admin') ?? false);

    _tabController = TabController(length: _canApprove ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  void _openCreateAsetFlow() {
    ModalPengalihanAsetSheet.show(context).then((ok) {
      if (ok == true) {
        _refreshAll();
      }
    });
  }

  void _openCreateBarangFlow() {
    ModalPengalihanBarangSheet.show(context).then((ok) {
      if (ok == true) {
        _refreshAll();
      }
    });
  }

  void _refreshAll() {
    ref.invalidate(daftarPengalihanProvider('aktif'));
    ref.invalidate(daftarPengalihanProvider('otorisasi'));
    ref.invalidate(daftarPengalihanProvider('riwayat'));
    ref.invalidate(countOtorisasiPengalihanProvider);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final canApproveNow = (user?.can('layanan_unit::approval::peminjaman') ?? false) ||
        (user?.can('view_any_layanan_unit::approval::karu') ?? false) ||
        (user?.hasRole('kepala_unit') ?? false) ||
        (user?.hasRole('kepala_gudang') ?? false) ||
        (user?.hasRole('admin_logistik') ?? false) ||
        (user?.hasRole('manajemen') ?? false) ||
        (user?.hasRole('super_admin') ?? false);

    if (canApproveNow != _canApprove) {
      _canApprove = canApproveNow;
      _tabController.dispose();
      _tabController = TabController(length: _canApprove ? 3 : 2, vsync: this);
    }

    final countOtorisasi = ref.watch(countOtorisasiPengalihanProvider).valueOrNull ?? 0;
    final selectedKategori = ref.watch(selectedKategoriPengalihanProvider);
    final isWarehouseOrAdmin = user?.isGudangUser == true ||
        user?.isAdminLogistik == true ||
        user?.isSuperAdmin == true ||
        user?.gudang != null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(selectedKategori == 'ASET' ? 'Pengalihan Aset RS' : 'Pengalihan Barang Gudang'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Segarkan',
            onPressed: _refreshAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            const Tab(text: 'Aktif'),
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
                    if (countOtorisasi > 0) ...[
                      const SizedBox(width: 4),
                      _buildBadge(countOtorisasi),
                    ],
                  ],
                ),
              ),
            const Tab(text: 'Riwayat'),
          ],
        ),
      ),
      floatingActionButton: () {
        final canCreateAset = user?.unit != null || user?.isSuperAdmin == true || user?.isAdminLogistik == true || user?.isGudangUser == true;
        final canCreateBarang = user?.isGudangUser == true || user?.isKepalaGudang == true || user?.isPetugasGudang == true || user?.isAdminLogistik == true || user?.isSuperAdmin == true || user?.gudang != null;
        final canCreate = selectedKategori == 'ASET' ? canCreateAset : canCreateBarang;

        if (!canCreate) return null;

        return FloatingActionButton.extended(
          key: Key('fab_ajukan_pengalihan_${selectedKategori.toLowerCase()}'),
          onPressed: selectedKategori == 'ASET' ? _openCreateAsetFlow : _openCreateBarangFlow,
          backgroundColor: selectedKategori == 'ASET' ? AppColors.primaryPurple : AppColors.tintBlue,
          foregroundColor: Colors.white,
          icon: const Icon(LucideIcons.plus, size: 18),
          label: Text(
            selectedKategori == 'ASET' ? 'Ajukan Pengalihan Aset' : 'Ajukan Pengalihan Barang',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      }(),
      body: Column(
        children: [
          if (isWarehouseOrAdmin)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text('Aset Fisik', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      selected: selectedKategori == 'ASET',
                      onSelected: (val) {
                        if (val) {
                          ref.read(selectedKategoriPengalihanProvider.notifier).state = 'ASET';
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text('Barang Gudang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      selected: selectedKategori == 'BARANG',
                      onSelected: (val) {
                        if (val) {
                          ref.read(selectedKategoriPengalihanProvider.notifier).state = 'BARANG';
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent('aktif', countOtorisasi),
                if (_canApprove) _buildTabContent('otorisasi', countOtorisasi),
                _buildTabContent('riwayat', countOtorisasi),
              ],
            ),
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

  Widget _buildTabContent(String tab, int countOtorisasi) {
    final user = ref.watch(authStateProvider).user;
    final asyncData = ref.watch(daftarPengalihanProvider(tab));
    final selectedKategori = ref.watch(selectedKategoriPengalihanProvider);
    final tipeLabel = selectedKategori == 'ASET' ? 'aset' : 'barang persediaan';
    return asyncData.when(
      data: (list) {
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(daftarPengalihanProvider(tab)),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (tab == 'aktif' && countOtorisasi > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertCircle, color: AppColors.warning, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Terdapat $countOtorisasi permohonan pengalihan $tipeLabel menunggu persetujuan Anda di tab Otorisasi.',
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _tabController.animateTo(1),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryPurple,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Buka', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    child: EmptyStateView(
                      icon: LucideIcons.arrowRightLeft,
                      title: 'Belum Ada Pengalihan',
                      message: tab == 'aktif'
                          ? (countOtorisasi > 0
                              ? 'Tidak ada permohonan aktif keluar/masuk. Periksa tab Otorisasi untuk permohonan dari fasilitas lain.'
                              : 'Tidak ada pengalihan $tipeLabel yang sedang berjalan.')
                          : (tab == 'otorisasi'
                              ? 'Tidak ada dokumen pengalihan yang menunggu otorisasi Anda.'
                              : 'Belum ada riwayat mutasi yang diselesaikan.'),
                      action: () {
                        final canCreateAset = user?.unit != null || user?.isSuperAdmin == true || user?.isAdminLogistik == true || user?.isGudangUser == true;
                        final canCreateBarang = user?.isGudangUser == true || user?.isKepalaGudang == true || user?.isPetugasGudang == true || user?.isAdminLogistik == true || user?.isSuperAdmin == true || user?.gudang != null;
                        final canCreate = selectedKategori == 'ASET' ? canCreateAset : canCreateBarang;

                        if (tab != 'aktif' || !canCreate) return null;

                        return ElevatedButton.icon(
                          onPressed: selectedKategori == 'ASET' ? _openCreateAsetFlow : _openCreateBarangFlow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedKategori == 'ASET' ? AppColors.primaryPurple : AppColors.tintBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: Text(
                            selectedKategori == 'ASET' ? 'Ajukan Pengalihan Aset' : 'Ajukan Pengalihan Barang',
                          ),
                        );
                      }(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(daftarPengalihanProvider(tab)),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return _buildPengalihanCard(item, tab);
            },
          ),
        );
      },
      loading: () => const AppLoadingView(message: 'Memuat data pengalihan aset...'),
      error: (err, _) => AppErrorView(
        error: err.toString().replaceAll('ApiException: ', ''),
        onRetry: () => ref.invalidate(daftarPengalihanProvider(tab)),
      ),
    );
  }

  Widget _buildPengalihanCard(PengalihanItemModel item, String tab) {
    final showApproveActions = tab == 'otorisasi' && item.canApprove;
    final showCancelAction = tab == 'aktif' && item.canCancel;
    final showReceiveAction = tab == 'aktif' && item.canReceive;
    final hasActions = showApproveActions || showCancelAction || showReceiveAction;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.kode,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryPurple),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: item.tipe == 'ASET' ? AppColors.tintOrangeBg : AppColors.tintBlueBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.tipe,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: item.tipe == 'ASET' ? AppColors.tintOrange : AppColors.tintBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.namaItem,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.arrowRightLeft, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${item.asalNama} ➔ ${item.tujuanNama}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tgl: ${item.tanggalPengalihan} • ${item.alasan ?? '-'}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          if (hasActions) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showCancelAction)
                  TextButton(
                    onPressed: () async {
                      final ok = await ref.read(pengalihanActionProvider.notifier).batalPengalihan(id: item.id, tipe: item.tipe);
                      if (ok && mounted) {
                        AppToast.success(context, 'Pengalihan berhasil dibatalkan');
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    child: const Text('Batalkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                if (showApproveActions) ...[
                  OutlinedButton(
                    onPressed: () async {
                      final ok = await ref.read(pengalihanActionProvider.notifier).otorisasiPengalihan(id: item.id, aksi: 'REJECT', tipe: item.tipe);
                      if (ok && mounted) {
                        AppToast.success(context, 'Pengalihan berhasil ditolak');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Tolak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final ok = await ref.read(pengalihanActionProvider.notifier).otorisasiPengalihan(id: item.id, aksi: 'APPROVE', tipe: item.tipe);
                      if (ok && mounted) {
                        AppToast.success(context, 'Pengalihan berhasil disetujui');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Setujui', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
                if (showReceiveAction)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await ref.read(pengalihanActionProvider.notifier).serahTerimaPengalihan(id: item.id, tipe: item.tipe);
                      if (ok && mounted) {
                        AppToast.success(context, 'Serah terima fisik selesai. Mutasi resmi dibukukan.');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(LucideIcons.checkCheck, size: 14),
                    label: const Text('Konfirmasi BAST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
