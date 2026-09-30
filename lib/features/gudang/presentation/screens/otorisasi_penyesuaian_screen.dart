import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../widgets/detail_penyesuaian_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/penyesuaian_stok_model.dart';
import '../../data/repositories/persediaan_repository.dart';
import '../providers/persediaan_providers.dart';
import '../providers/gudang_provider.dart';
class OtorisasiPenyesuaianScreen extends ConsumerStatefulWidget {
  const OtorisasiPenyesuaianScreen({super.key});

  @override
  ConsumerState<OtorisasiPenyesuaianScreen> createState() => _OtorisasiPenyesuaianScreenState();
}

class _OtorisasiPenyesuaianScreenState extends ConsumerState<OtorisasiPenyesuaianScreen> {
  Future<void> _confirmApprove(PenyesuaianStokHeaderModel adj) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Otorisasi Penyesuaian Stok',
      message:
          'Apakah Anda yakin ingin mengesahkan penyesuaian stok ${adj.kode} untuk fasilitas ${adj.gudangNama} (${adj.totalItem} batch selisih)? Saldo stok fisik akan disesuaikan secara permanen.',
      confirmLabel: 'Sahkan Penyesuaian',
      icon: LucideIcons.shieldCheck,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(persediaanRepositoryProvider).approvePenyesuaian(adj.id);
      if (!mounted) return;
      ref.invalidate(otorisasiPenyesuaianListProvider);
      ref.invalidate(bukuMutasiListProvider);
      ref.invalidate(fefoMonitoringProvider);
      ref.invalidate(daftarRakProvider);
      ref.invalidate(dashboardSummaryProvider);
      AppToast.success(context, 'Penyesuaian stok ${adj.kode} berhasil disahkan.');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }
  Future<void> _confirmReject(PenyesuaianStokHeaderModel adj) async {
    final catatanCtrl = TextEditingController();
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Penyesuaian Stok'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tolak dokumen penyesuaian ${adj.kode} (${adj.gudangNama})? Sesi opname terkait akan dibatalkan/diinvestigasi ulang.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catatanCtrl,
              decoration: const InputDecoration(
                hintText: 'Alasan penolakan (opsional)...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );

    if (shouldReject != true || !mounted) return;

    try {
      await ref.read(persediaanRepositoryProvider).rejectPenyesuaian(
            adj.id,
            alasan: catatanCtrl.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(otorisasiPenyesuaianListProvider);
      ref.invalidate(dashboardSummaryProvider);
      AppToast.success(context, 'Penyesuaian stok ${adj.kode} telah ditolak.');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  void _showDetailModal(PenyesuaianStokHeaderModel adj, bool canAuthorize) {
    DetailPenyesuaianSheet.show(
      context,
      adj: adj,
      canAuthorize: canAuthorize,
      onAuthorize: () => _confirmApprove(adj),
      onReject: () => _confirmReject(adj),
    );
  }

  @override
  Widget build(BuildContext context) {
    final penyesuaianAsync = ref.watch(otorisasiPenyesuaianListProvider);
    final selectedStatus = ref.watch(penyesuaianStatusFilterProvider);
    final user = ref.watch(authStateProvider).user;
    final canAuthorize = (user?.hasRole('kepala_gudang') ?? false) ||
        (user?.hasRole('admin_logistik') ?? false) ||
        (user?.hasRole('super_admin') ?? false) ||
        (user?.can('update_gudang_stok::otorisasi::penyesuaian') ?? false);
    final canView = canAuthorize ||
        (user?.hasRole('auditor') ?? false) ||
        (user?.hasRole('manajemen') ?? false) ||
        (user?.can('view_any_gudang_stok::otorisasi::penyesuaian') ?? false);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Otorisasi Penyesuaian Stok'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.refresh(otorisasiPenyesuaianListProvider),
          ),
        ],
      ),
      body: !canView
          ? const SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: AppErrorView(
                    title: 'Akses Dibatasi',
                    error:
                        'Hanya Kepala Gudang & Pimpinan yang berwenang mengakses otorisasi penyesuaian selisih stok opname.',
                  ),
                ),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Status Filter Tabs
            Container(
              color: AppColors.surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildTabChip('Menunggu Otorisasi', 'MENUNGGU', selectedStatus),
                    const SizedBox(width: 8),
                    _buildTabChip('Disetujui', 'DISETUJUI', selectedStatus),
                    const SizedBox(width: 8),
                    _buildTabChip('Semua', 'SEMUA', selectedStatus),
                  ],
                ),
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // List Penyesuaian
            Expanded(
              child: penyesuaianAsync.when(
                loading: () => const AppLoadingView(),
                error: (err, _) => AppErrorView(
                  error: err,
                  onRetry: () => ref.refresh(otorisasiPenyesuaianListProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStateView(
                      icon: LucideIcons.shieldCheck,
                      title: 'Tidak Ada Antrean Penyesuaian',
                      message: 'Semua selisih opname telah diselesaikan atau belum ada draf penyesuaian baru.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final adj = items[index];

                      return InkWell(
                        onTap: () => _showDetailModal(adj, canAuthorize),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
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
                                    adj.kode,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'monospace',
                                      color: AppColors.primaryPurple,
                                    ),
                                  ),
                                  StatusBadge(status: adj.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                adj.gudangNama,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sesi Opname: ${adj.kodeOpname} • Tgl: ${adj.tanggalPenyesuaian}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const Divider(color: AppColors.border, height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${adj.totalItem} Item Selisih',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        AppFormatters.rupiah(adj.totalNilaiSelisih),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.danger),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ],
                              ),
                              if (adj.isMenunggu && canAuthorize) ...[
                                const SizedBox(height: 12),
                                CustomButton(
                                  text: 'Sahkan Penyesuaian Saldo',
                                  height: 44,
                                  icon: const Icon(LucideIcons.check, size: 16, color: Colors.white),
                                  onPressed: () => _confirmApprove(adj),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, String value, String selected) {
    final isSelected = selected == value;
    return InkWell(
      onTap: () {
        ref.read(penyesuaianStatusFilterProvider.notifier).state = value;
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.canvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
