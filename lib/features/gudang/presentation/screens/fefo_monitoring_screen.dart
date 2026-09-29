import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_filter_chip_bar.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../providers/persediaan_providers.dart';

class FefoMonitoringScreen extends ConsumerStatefulWidget {
  const FefoMonitoringScreen({super.key});

  @override
  ConsumerState<FefoMonitoringScreen> createState() => _FefoMonitoringScreenState();
}

class _FefoMonitoringScreenState extends ConsumerState<FefoMonitoringScreen> {


  @override
  Widget build(BuildContext context) {
    final fefoAsync = ref.watch(fefoMonitoringProvider);
    final selectedFilter = ref.watch(fefoKategoriFilterProvider);


    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Monitoring Stok FEFO'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.refresh(fefoMonitoringProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Metric Counter Cards
            fefoAsync.maybeWhen(
              data: (data) => Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: AppColors.surface,
                child: Row(
                  children: [
                    _buildMetricCard(
                      'Kritis <=30h',
                      '${data.metrik.countKritis30}',
                      AppColors.danger,
                      const Color(0xFFFEF2F2),
                    ),
                    const SizedBox(width: 8),
                    _buildMetricCard(
                      'Peringatan',
                      '${data.metrik.countPeringatan90}',
                      AppColors.warning,
                      const Color(0xFFFFFBEB),
                    ),
                    const SizedBox(width: 8),
                    _buildMetricCard(
                      'Expired',
                      '${data.metrik.countExpired}',
                      const Color(0xFF991B1B),
                      const Color(0xFFFEE2E2),
                    ),
                    const SizedBox(width: 8),
                    _buildMetricCard(
                      'Batas ROP',
                      '${data.metrik.countRop}',
                      AppColors.tintBlue,
                      AppColors.tintBlueBg,
                    ),
                  ],
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),

            // Search Bar & Filter Chips
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: AppColors.surface,
              child: Column(
                children: [
                  AppSearchBar(
                    hint: 'Cari nomor batch, barang, atau rak...',
                    onChanged: (val) {
                      ref.read(fefoSearchQueryProvider.notifier).state = val;
                    },
                  ),
                  const SizedBox(height: 10),
                  AppFilterChipBar<String>(
                    padding: EdgeInsets.zero,
                    selected: selectedFilter,
                    onSelected: (val) {
                      ref.read(fefoKategoriFilterProvider.notifier).state = val;
                    },
                    options: const [
                      AppFilterOption(label: 'Semua Batch', value: 'SEMUA'),
                      AppFilterOption(label: 'Kritis (<= 30 Hari)', value: 'KRITIS'),
                      AppFilterOption(label: 'Peringatan (31-90 Hari)', value: 'PERINGATAN'),
                      AppFilterOption(label: 'Sudah Kedaluwarsa', value: 'KEDALUWARSA'),
                      AppFilterOption(label: 'Bawah ROP', value: 'ROP'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // Batch List
            Expanded(
              child: fefoAsync.when(
                loading: () => const AppLoadingView(),
                error: (err, _) => AppErrorView(
                  error: err,
                  onRetry: () => ref.refresh(fefoMonitoringProvider),
                ),
                data: (data) {
                  if (data.items.isEmpty) {
                    return const EmptyStateView(
                      icon: LucideIcons.packageCheck,
                      title: 'Tidak Ada Batch Terdeteksi',
                      message: 'Tidak ada stok batch aktif yang memenuhi kriteria filter FEFO saat ini.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final b = data.items[index];

                      Color fefoColor = AppColors.success;
                      Color fefoBg = const Color(0xFFECFDF5);
                      String statusText = 'Aman';

                      if (b.statusFefo == 'KEDALUWARSA') {
                        fefoColor = const Color(0xFF991B1B);
                        fefoBg = const Color(0xFFFEE2E2);
                        statusText = 'Kedaluwarsa';
                      } else if (b.statusFefo == 'KRITIS') {
                        fefoColor = AppColors.danger;
                        fefoBg = const Color(0xFFFEF2F2);
                        statusText = 'Kritis (${b.sisaHari}h)';
                      } else if (b.statusFefo == 'PERINGATAN') {
                        fefoColor = AppColors.warning;
                        fefoBg = const Color(0xFFFFFBEB);
                        statusText = 'Perhatian (${b.sisaHari}h)';
                      } else if (b.statusFefo == 'TANPA_ED') {
                        fefoColor = AppColors.textSecondary;
                        fefoBg = AppColors.surfaceSecondary;
                        statusText = 'Non-Expiring';
                      }

                      return Container(
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
                                      const Icon(LucideIcons.barcode, size: 16, color: AppColors.tintBlue),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Batch: ${b.nomorBatch}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'monospace',
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: fefoBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: fefoColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b.namaBarang,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${b.kategori} • ${b.gudang} (Rak: ${b.lokasiRak})',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const Divider(color: AppColors.border, height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.calendar, size: 13, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          b.tanggalKedaluwarsa != null ? 'Exp: ${b.tanggalKedaluwarsa}' : 'Tanpa Expired Date',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${b.jumlah} ${b.satuan} (${AppFormatters.rupiah(b.nilaiTotal)})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryPurple),
                                ),
                              ],
                            ),
                          ],
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

  Widget _buildMetricCard(String label, String value, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: textColor.withValues(alpha: 0.8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
