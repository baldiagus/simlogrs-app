import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../providers/gudang_provider.dart';
import '../widgets/barang_rak_list_tab.dart';
import '../widgets/aset_rak_list_tab.dart';

/// Layar detail satu rak gudang: informasi rak beserta isi stok yang tersimpan di dalamnya.
class DetailRakScreen extends ConsumerWidget {
  final int rakId;
  final String kodeRak;
  final String namaRak;

  /// Membuat layar detail untuk rak dengan [rakId], [kodeRak], dan [namaRak] yang diberikan.
  const DetailRakScreen({
    super.key,
    required this.rakId,
    required this.kodeRak,
    required this.namaRak,
  });

  /// Menyusun UI detail rak dari data [detailRakProvider] dengan status loading/error.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(detailRakProvider(rakId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kodeRak,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              namaRak,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(detailRakProvider(rakId)),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(
          title: 'Gagal Memuat Detail Rak',
          error: error,
          onRetry: () => ref.invalidate(detailRakProvider(rakId)),
        ),
        data: (detail) {
          final rak = detail.rak;

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Info Summary Card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.softCard,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.warehouse, size: 15, color: AppColors.primaryPurple),
                              const SizedBox(width: 6),
                              Text(
                                rak.namaGudang,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: rak.status == 'AKTIF'
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rak.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: rak.status == 'AKTIF' ? AppColors.success : AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Posisi Ruang: ${[
                          if (rak.baris != null && rak.baris!.isNotEmpty) 'Baris ${rak.baris}',
                          if (rak.kolom != null && rak.kolom!.isNotEmpty) 'Kolom ${rak.kolom}',
                          if (rak.level != null && rak.level!.isNotEmpty) 'Level ${rak.level}',
                        ].join(' • ')}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 10),

                      // Agregat Count Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.tintBlueBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.boxes, size: 16, color: AppColors.tintBlue),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${detail.barang.length}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.tintBlue,
                                        ),
                                      ),
                                      const Text(
                                        'Stok Barang',
                                        style: TextStyle(fontSize: 10, color: AppColors.tintBlue),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.tintOrangeBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.package, size: 16, color: AppColors.tintOrange),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${detail.aset.length}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.tintOrange,
                                        ),
                                      ),
                                      const Text(
                                        'Unit Aset Fisik',
                                        style: TextStyle(fontSize: 10, color: AppColors.tintOrange),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab Header
                Container(
                  color: AppColors.surface,
                  child: TabBar(
                    indicatorColor: AppColors.primaryPurple,
                    indicatorWeight: 3,
                    labelColor: AppColors.primaryPurple,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    unselectedLabelStyle:
                        const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.boxes, size: 16),
                            const SizedBox(width: 8),
                            Text('Barang & Batch (${detail.barang.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.package, size: 16),
                            const SizedBox(width: 8),
                            Text('Aset Fisik (${detail.aset.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    children: [
                      BarangRakListTab(items: detail.barang),
                      AsetRakListTab(items: detail.aset),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
