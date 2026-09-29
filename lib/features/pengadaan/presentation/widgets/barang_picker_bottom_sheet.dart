import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../data/models/master_barang_model.dart';
import '../providers/pengadaan_provider.dart';

class BarangPickerBottomSheet extends ConsumerStatefulWidget {
  final ValueChanged<MasterBarangModel> onBarangSelected;
  final String? filterTipe;

  const BarangPickerBottomSheet({
    super.key,
    required this.onBarangSelected,
    this.filterTipe,
  });
  @override
  ConsumerState<BarangPickerBottomSheet> createState() => _BarangPickerBottomSheetState();
}

class _BarangPickerBottomSheetState extends ConsumerState<BarangPickerBottomSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final katalogAsync = ref.watch(
      katalogBarangProvider(KatalogBarangParams(query: _query, tipe: widget.filterTipe)),
    );
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.filterTipe == 'SPAREPART'
                      ? 'Katalog Suku Cadang'
                      : 'Katalog Master Barang',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppSearchBar(
              hint: 'Cari nama barang, kode SKU, atau spesifikasi...',
              onChanged: (v) => setState(() => _query = v.trim()),
              onClear: () => setState(() => _query = ''),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),

          // Catalog List
          Expanded(
            child: katalogAsync.when(
              data: (list) {
                final effectiveList = widget.filterTipe != null
                    ? list.where((b) => b.tipe.toUpperCase() == widget.filterTipe!.toUpperCase()).toList()
                    : list;

                if (effectiveList.isEmpty) {
                  return EmptyStateView(
                    icon: LucideIcons.packageSearch,
                    title: widget.filterTipe == 'SPAREPART'
                        ? 'Suku Cadang Tidak Ditemukan'
                        : 'Barang Tidak Ditemukan',
                    message: widget.filterTipe == 'SPAREPART'
                        ? 'Tidak ada komoditas suku cadang (sparepart) yang cocok dengan pencarian.'
                        : 'Coba kata kunci lain atau periksa ejaan nama barang.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: effectiveList.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.border,
                    indent: 48,
                  ),
                  itemBuilder: (context, index) {
                    final b = effectiveList[index];
                    return InkWell(
                      onTap: () {
                        widget.onBarangSelected(b);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.package,
                                size: 18,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.nama,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${b.kode} • ${b.kategori} (${b.satuan})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (b.spesifikasi != null && b.spesifikasi!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      b.spesifikasi!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              LucideIcons.plusCircle,
                              size: 20,
                              color: AppColors.primaryPurple,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoadingView(),
              error: (err, _) => AppErrorView(
                title: 'Gagal Memuat Katalog',
                error: err,
                onRetry: () => ref.refresh(
                  katalogBarangProvider(KatalogBarangParams(query: _query, tipe: widget.filterTipe)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
