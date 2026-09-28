import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/pr_model.dart';
import '../providers/pengadaan_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import 'form_pengajuan_pr_screen.dart';

class RiwayatPrScreen extends ConsumerWidget {
  const RiwayatPrScreen({super.key});

  void _showDetailModal(BuildContext context, PrHeaderModel pr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pr.kode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryPurple,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Diajukan: ${pr.tanggalPermintaan} • ${pr.pengaju}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: pr.status),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: pr.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (ctx, i) {
                  final item = pr.items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaBarang,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.kodeBarang != null)
                                Text(
                                  item.kodeBarang!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.jumlah} ${item.satuan}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prListAsync = ref.watch(daftarPrProvider);
    final user = ref.watch(authStateProvider).user;
    final isPengadaan = user?.isPengadaan ?? false;

    final canCreate = !isPengadaan &&
        ((user?.can('create_pengadaan::permintaan::pengadaan') ?? false) ||
            (user?.hasRole('petugas_unit') ?? false) ||
            (user?.hasRole('kepala_unit') ?? false) ||
            (user?.hasRole('super_admin') ?? false));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Permintaan Pengadaan (PR)'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.invalidate(daftarPrProvider),
            tooltip: 'Segarkan',
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
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
              label: const Text(
                'Ajukan PR Baru',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: prListAsync.when(
        data: (list) {
          final displayedList = isPengadaan
              ? list.where((pr) => pr.isDisetujui).toList()
              : list;

          if (displayedList.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(daftarPrProvider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: EmptyStateView(
                    icon: LucideIcons.fileSpreadsheet,
                    title: isPengadaan ? 'Belum Ada PR Siap Diproses' : 'Belum Ada Permintaan PR',
                    message: isPengadaan
                        ? 'Belum ada permohonan pengadaan barang dari unit yang telah disetujui oleh Kepala Ruangan.'
                        : 'Unit Anda belum pernah mengajukan permohonan pengadaan barang ke logistik.',
                    action: canCreate
                        ? ElevatedButton.icon(
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
                            icon: const Icon(LucideIcons.plus, size: 18),
                            label: const Text('Buat Pengajuan Sekarang'),
                          )
                        : null,
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(daftarPrProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: displayedList.length,
              itemBuilder: (context, index) {
                final pr = displayedList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: pr.isCito
                          ? AppColors.danger.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(15, 23, 42, 0.03),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => _showDetailModal(context, pr),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.tintVioletBg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          pr.kode,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryPurple,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    if (pr.isCito) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'CITO',
                                          style: TextStyle(
                                            color: AppColors.danger,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(status: pr.status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            pr.unit,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Diajukan: ${pr.tanggalPermintaan} • Oleh ${pr.pengaju}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${pr.jumlahItem} Item Barang',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Row(
                                  children: [
                                    Text(
                                      'Detail',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryPurple,
                                      ),
                                    ),
                                    Icon(
                                      LucideIcons.chevronRight,
                                      size: 14,
                                      color: AppColors.primaryPurple,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle, size: 40, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(
                  err.toString().replaceAll('ApiException: ', ''),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => ref.invalidate(daftarPrProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
