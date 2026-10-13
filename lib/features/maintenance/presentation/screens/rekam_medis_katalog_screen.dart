import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_filter_chip_bar.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../providers/ipsrs_providers.dart';
import 'rekam_medis_detail_screen.dart';

class RekamMedisKatalogScreen extends ConsumerStatefulWidget {
  /// Membuat RekamMedisKatalogScreen.
  const RekamMedisKatalogScreen({super.key});

  /// Membuat state mutable untuk widget ini.
  @override
  ConsumerState<RekamMedisKatalogScreen> createState() => _RekamMedisKatalogScreenState();
}

class _RekamMedisKatalogScreenState extends ConsumerState<RekamMedisKatalogScreen> {


  /// Membangun tampilan _RekamMedisKatalogScreenState.
  @override
  Widget build(BuildContext context) {
    final katalogAsync = ref.watch(rekamMedisKatalogProvider);
    final selectedKondisi = ref.watch(rekamMedisKondisiFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Buku Rekam Medis Sarana'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Muat ulang',
            onPressed: () => ref.refresh(rekamMedisKatalogProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Chips
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppColors.surface,
              child: Column(
                children: [
                  AppSearchBar(
                    hint: 'Cari kode AST-..., nomor seri, atau alat...',
                    onChanged: (val) {
                      ref.read(rekamMedisSearchQueryProvider.notifier).state = val;
                    },
                  ),
                  const SizedBox(height: 10),
                  AppFilterChipBar<String?>(
                    padding: EdgeInsets.zero,
                    selected: selectedKondisi,
                    onSelected: (val) {
                      ref.read(rekamMedisKondisiFilterProvider.notifier).state = val;
                    },
                    options: const [
                      AppFilterOption(label: 'Semua Kondisi', value: null),
                      AppFilterOption(label: 'Kondisi: Baik', value: 'BAIK'),
                      AppFilterOption(label: 'Rusak Ringan', value: 'RUSAK_RINGAN'),
                      AppFilterOption(label: 'Rusak Berat', value: 'RUSAK_BERAT'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // Asset List
            Expanded(
              child: katalogAsync.when(
                loading: () => const AppLoadingView(),
                error: (err, _) => AppErrorView(
                  error: err,
                  onRetry: () => ref.refresh(rekamMedisKatalogProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStateView(
                      icon: LucideIcons.stethoscope,
                      title: 'Sarana Tidak Ditemukan',
                      message: 'Tidak ada sarana medis atau non-medis yang cocok dengan kata kunci pencarian.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(rekamMedisKatalogProvider.future),
                    child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final a = items[index];

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RekamMedisDetailScreen(
                                asetId: a.id,
                                initialNama: a.namaSarana,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(LucideIcons.stethoscope, color: AppColors.primaryPurple, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            a.kodeAset,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'monospace',
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        StatusBadge(status: a.kondisi),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      a.namaSarana,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.mapPin, size: 12, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${a.lokasi} • SN: ${a.nomorSeri}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: a.totalServis > 0 ? AppColors.tintOrangeBg : AppColors.surfaceSecondary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${a.totalServis}x Servis Tercatat',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: a.totalServis > 0 ? AppColors.tintOrange : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
                            ],
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

}
