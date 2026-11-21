import '../../../../core/network/user_error_message.dart';
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
import '../../data/models/fefo_monitoring_model.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';

/// Layar monitoring FEFO: memantau batch stok berdasarkan kedekatan tanggal kedaluwarsa agar yang lebih dulu kedaluwarsa dikeluarkan lebih dulu.
class FefoMonitoringScreen extends ConsumerStatefulWidget {
  const FefoMonitoringScreen({super.key});

  /// Membuat state layar monitoring FEFO.
  @override
  ConsumerState<FefoMonitoringScreen> createState() => _FefoMonitoringScreenState();
}

/// State layar monitoring FEFO; memantau data batch serta filter kategori dan pencarian dari provider.
class _FefoMonitoringScreenState extends ConsumerState<FefoMonitoringScreen> {
  void _openDetail(FefoBatchItemModel batch, String status, Color color) {
    final days = batch.sisaHari;
    final remaining = days == null ? 'Tidak tersedia'
        : days < 0 ? 'Lewat ${days.abs()} hari'
        : days == 0 ? 'Kedaluwarsa hari ini' : '$days hari lagi';
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) => AppBottomSheetWrapper(
        title: 'Detail Stok FEFO', fixedHeader: true, maxHeightFactor: 0.9,
        trailing: IconButton(tooltip: 'Tutup detail FEFO',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(batch.namaBarang, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ...<String, String>{
            'Kode batch': batch.nomorBatch,
            'Kode barang': batch.kodeBarang,
            'Kategori': batch.kategori,
            'Gudang': batch.gudang,
            'Rak': batch.lokasiRak,
            'Kedaluwarsa': batch.tanggalKedaluwarsa ?? 'Tanpa tanggal kedaluwarsa',
            'Sisa hari': remaining,
            'Stok tersedia': '${batch.jumlah} ${batch.satuan}',
            'Harga satuan': AppFormatters.rupiah(batch.hargaSatuan),
            'Nilai persediaan': AppFormatters.rupiah(batch.nilaiTotal),
          }.entries.map((entry) => Padding(padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildDetail(entry.key, entry.value.trim().isEmpty || entry.value == '-'
              ? 'Tidak tersedia' : entry.value))),
        ]),
      ),
    );
  }


  /// Menyusun UI monitoring FEFO: ringkasan metrik, pencarian, filter kategori, dan daftar batch berwarna sesuai status kedaluwarsa.
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
            tooltip: 'Muat ulang',
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const columns = 4;
                    final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: width,
                          child: _buildMetricCard('Kritis\n≤30 hari', '${data.metrik.countKritis30}', AppColors.danger, const Color(0xFFFEF2F2)),
                        ),
                        SizedBox(
                          width: width,
                          child: _buildMetricCard('Peringatan', '${data.metrik.countPeringatan90}', AppColors.warning, const Color(0xFFFFFBEB)),
                        ),
                        SizedBox(
                          width: width,
                          child: _buildMetricCard('Kedaluwarsa', '${data.metrik.countExpired}', const Color(0xFF991B1B), const Color(0xFFFEE2E2)),
                        ),
                        SizedBox(
                          width: width,
                          child: _buildMetricCard('Batas ROP', '${data.metrik.countRop}', AppColors.tintBlue, AppColors.tintBlueBg),
                        ),
                      ],
                    );
                  },
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
                  error: userErrorMessage(err, action: 'memuat pemantauan FEFO'),
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

                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(fefoMonitoringProvider.future),
                    child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
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

                      return Material(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.border)),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _openDetail(b, statusText, fefoColor),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Wrap(spacing: 12, runSpacing: 8, children: [
                                Text(b.nomorBatch, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: fefoBg, borderRadius: BorderRadius.circular(6)),
                                  child: Text(statusText, style: TextStyle(color: fefoColor, fontWeight: FontWeight.w700))),
                              ]),
                              const SizedBox(height: 10),
                              Text(b.namaBarang, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(b.gudang, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Text('Kedaluwarsa: ${b.tanggalKedaluwarsa ?? 'Tanpa tanggal kedaluwarsa'}'),
                              const Divider(height: 24),
                              Wrap(spacing: 16, crossAxisAlignment: WrapCrossAlignment.center, children: [
                                Text('${b.jumlah} ${b.satuan}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                TextButton(onPressed: () => _openDetail(b, statusText, fefoColor),
                                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                                  child: const Text('Detail')),
                              ]),
                            ]),
                          ),
                        ),
                      );
                    },
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String value, {bool emphasize = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            color: emphasize ? AppColors.primaryPurple : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Membangun kartu ringkasan angka (metrik) dengan [label], [value], dan warna teks/latar yang diberikan.
  Widget _buildMetricCard(String label, String value, Color textColor, Color bgColor) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
    );
  }
}
