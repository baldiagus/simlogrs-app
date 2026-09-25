import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/distribusi_provider.dart';

class PickingDistribusiScreen extends ConsumerWidget {
  const PickingDistribusiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickingListAsync = ref.watch(antreanPickingProvider);
    final actionState = ref.watch(amprahActionProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Picking Distribusi (FEFO)'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.invalidate(antreanPickingProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryPurple,
          onRefresh: () async => ref.invalidate(antreanPickingProvider),
          child: pickingListAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const EmptyStateView(
                      icon: LucideIcons.packageCheck,
                      title: 'Tidak Ada Antrean Picking',
                      message: 'Semua permohonan amprah yang disetujui telah selesai dipicking ke SPPB.',
                    ),
                  ),
                );
              }

              return ListView.builder(
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
                      border: Border.all(
                        color: item.isCito
                            ? AppColors.danger.withValues(alpha: 0.35)
                            : AppColors.border,
                        width: item.isCito ? 1.5 : 1.0,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(15, 23, 42, 0.03),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.tintVioletBg, borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    item.kode,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                                  ),
                                ),
                                if (item.isCito) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                                    child: const Text(
                                      'CITO',
                                      style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            StatusBadge(status: item.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.unit,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tgl: ${item.tanggalPermintaan ?? '-'} • Pemohon: ${item.pengaju}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),

                        // Item Preview
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.totalItem} Jenis Barang Siap Diambil (FEFO):',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              ...item.items.map((d) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '• ${d['nama_barang']}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        'x${d['jumlah_disetujui']} ${d['satuan']}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),

                        CustomButton(
                          text: 'Eksekusi Picking FEFO & Terbitkan SPPB',
                          height: 42,
                          isLoading: actionState.isLoading,
                          icon: const Icon(LucideIcons.arrowRightCircle, size: 16, color: Colors.white),
                          onPressed: () async {
                            final notifier = ref.read(amprahActionProvider.notifier);
                            final ok = await notifier.eksekusiPicking(item.id);
                            if (!context.mounted) return;
                            final s = ref.read(amprahActionProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? (s.successMessage ?? 'Berhasil picking') : (s.errorMessage ?? 'Gagal')),
                                backgroundColor: ok ? AppColors.success : AppColors.danger,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 40, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text(err.toString().replaceAll('ApiException: ', ''), textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(antreanPickingProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
