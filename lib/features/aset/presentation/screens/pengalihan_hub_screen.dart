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
import '../widgets/aset_picker_bottom_sheet.dart';
import '../widgets/modal_pengalihan_aset_sheet.dart';

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

  void _openCreateFlow() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AsetPickerBottomSheet(
        onAsetSelected: (aset) {
          Navigator.pop(ctx);
          ModalPengalihanAsetSheet.show(context, aset: aset).then((ok) {
            if (ok == true) {
              ref.invalidate(daftarPengalihanProvider('aktif'));
              ref.invalidate(daftarPengalihanProvider('otorisasi'));
              ref.invalidate(daftarPengalihanProvider('riwayat'));
            }
          });
        },
      ),
    );
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

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Pengalihan Aset RS'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Segarkan',
            onPressed: () {
              ref.invalidate(daftarPengalihanProvider('aktif'));
              ref.invalidate(daftarPengalihanProvider('otorisasi'));
              ref.invalidate(daftarPengalihanProvider('riwayat'));
            },
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
            if (_canApprove) const Tab(text: 'Otorisasi'),
            const Tab(text: 'Riwayat'),
          ],
        ),
      ),
      floatingActionButton: (user?.unit != null || user?.isSuperAdmin == true || user?.isAdminLogistik == true)
          ? FloatingActionButton.extended(
              onPressed: _openCreateFlow,
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Ajukan Pengalihan', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent('aktif'),
          if (_canApprove) _buildTabContent('otorisasi'),
          _buildTabContent('riwayat'),
        ],
      ),
    );
  }

  Widget _buildTabContent(String tab) {
    final asyncData = ref.watch(daftarPengalihanProvider(tab));

    return asyncData.when(
      data: (list) {
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(daftarPengalihanProvider(tab)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: EmptyStateView(
                  icon: LucideIcons.arrowRightLeft,
                  title: 'Belum Ada Pengalihan',
                  message: tab == 'aktif'
                      ? 'Tidak ada pengalihan aset yang sedang berjalan.'
                      : (tab == 'otorisasi'
                          ? 'Tidak ada dokumen pengalihan yang menunggu otorisasi Anda.'
                          : 'Belum ada riwayat mutasi aset yang diselesaikan.'),
                  action: tab == 'aktif'
                      ? ElevatedButton.icon(
                          onPressed: _openCreateFlow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Ajukan Sekarang'),
                        )
                      : null,
                ),
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
              return _buildPengalihanCard(item);
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

  Widget _buildPengalihanCard(PengalihanItemModel item) {
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
              Text(
                item.kode,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryPurple),
              ),
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
          if (item.canApprove || item.canReceive || item.canCancel) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.canCancel)
                  TextButton(
                    onPressed: () async {
                      final ok = await ref.read(pengalihanActionProvider.notifier).batalPengalihan(id: item.id);
                      if (ok && mounted) {
                        AppToast.success(context, 'Pengalihan berhasil dibatalkan');
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    child: const Text('Batalkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                if (item.canApprove) ...[
                  OutlinedButton(
                    onPressed: () async {
                      final ok = await ref.read(pengalihanActionProvider.notifier).otorisasiPengalihan(id: item.id, aksi: 'REJECT');
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
                      final ok = await ref.read(pengalihanActionProvider.notifier).otorisasiPengalihan(id: item.id, aksi: 'APPROVE');
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
                if (item.canReceive)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await ref.read(pengalihanActionProvider.notifier).serahTerimaPengalihan(id: item.id);
                      if (ok && mounted) {
                        AppToast.success(context, 'Serah terima fisik selesai. Aset resmi dimutasi.');
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
