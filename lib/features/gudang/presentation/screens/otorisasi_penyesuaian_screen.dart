import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
class OtorisasiPenyesuaianScreen extends ConsumerStatefulWidget {
  const OtorisasiPenyesuaianScreen({super.key});

  @override
  ConsumerState<OtorisasiPenyesuaianScreen> createState() => _OtorisasiPenyesuaianScreenState();
}

class _OtorisasiPenyesuaianScreenState extends ConsumerState<OtorisasiPenyesuaianScreen> {
  void _confirmApprove(PenyesuaianStokHeaderModel adj) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Otorisasi Penyesuaian Stok'),
        content: Text(
          'Apakah Anda yakin ingin mengesahkan penyesuaian stok ${adj.kode} untuk fasilitas ${adj.gudangNama} (${adj.totalItem} batch selisih)? Saldo stok fisik akan disesuaikan secara permanen.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(persediaanRepositoryProvider).approvePenyesuaian(adj.id);
                ref.invalidate(otorisasiPenyesuaianListProvider);
                ref.invalidate(dashboardSummaryProvider);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Penyesuaian stok ${adj.kode} berhasil disahkan.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                );
              }
            },
            child: const Text('Sahkan Penyesuaian'),
          ),
        ],
      ),
    );
  }

  void _showDetailModal(PenyesuaianStokHeaderModel adj, bool canAuthorize) {
    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adj.kode,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                    ),
                    Text(
                      'Sesi Opname: ${adj.kodeOpname}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                StatusBadge(status: adj.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Alasan: ${adj.alasan}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Divider(color: AppColors.border, height: 20),
            const Text(
              'Daftar Batch yang Mengalami Selisih:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: adj.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (c, i) {
                  final it = adj.items[i];
                  final isKurang = it.isKurang;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isKurang ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isKurang ? LucideIcons.trendingDown : LucideIcons.trendingUp,
                            size: 16,
                            color: isKurang ? AppColors.danger : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.namaBarang,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Batch: ${it.nomorBatch} • Rak: ${it.lokasiRak}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isKurang ? '-' : '+'}${it.jumlahPenyesuaian} ${it.satuan}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isKurang ? AppColors.danger : AppColors.success,
                              ),
                            ),
                            Text(
                              rupiah.format(it.subtotalNilai),
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (adj.isMenunggu) ...[
              const SizedBox(height: 16),
              if (canAuthorize)
                CustomButton(
                  text: 'Sahkan Penyesuaian Saldo',
                  icon: const Icon(LucideIcons.checkCheck, size: 18, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmApprove(adj);
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.info, size: 16, color: AppColors.warning),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Menunggu peninjauan dan pengesahan resmi oleh Kepala Gudang.',
                          style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
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
    final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
      body: SafeArea(
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.circleAlert, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.refresh(otorisasiPenyesuaianListProvider),
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
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
                                        rupiah.format(adj.totalNilaiSelisih),
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
