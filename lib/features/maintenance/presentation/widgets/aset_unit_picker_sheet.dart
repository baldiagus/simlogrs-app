import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../data/models/tiket_maintenance_model.dart';
import '../providers/tiket_maintenance_provider.dart';

class AsetUnitPickerSheet extends ConsumerStatefulWidget {
  final ValueChanged<AsetUnitModel> onAsetSelected;

  /// Membuat AsetUnitPickerSheet.
  const AsetUnitPickerSheet({
    super.key,
    required this.onAsetSelected,
  });

  /// Membuat state mutable untuk widget ini.
  @override
  ConsumerState<AsetUnitPickerSheet> createState() => _AsetUnitPickerSheetState();
}

class _AsetUnitPickerSheetState extends ConsumerState<AsetUnitPickerSheet> {
  String _query = '';

  /// Membangun tampilan _AsetUnitPickerSheetState.
  @override
  Widget build(BuildContext context) {
    final asetUnitAsync = ref.watch(asetUnitTersediaProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Sarana / Alat Ruangan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 20),
                  tooltip: 'Tutup',
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
              hint: 'Cari kode aset, nama sarana, nomor seri...',
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              onClear: () => setState(() => _query = ''),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),

          // Content List
          Expanded(
            child: asetUnitAsync.when(
              data: (list) {
                final filtered = list.where((a) {
                  if (_query.isEmpty) return true;
                  return a.nama.toLowerCase().contains(_query) ||
                      a.kodeAset.toLowerCase().contains(_query) ||
                      a.nomorSeri.toLowerCase().contains(_query);
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyStateView(
                    icon: LucideIcons.packageSearch,
                    title: 'Sarana Tidak Ditemukan',
                    message: 'Tidak ada aset inventaris yang sesuai pada ruangan Anda.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border, indent: 48),
                  itemBuilder: (context, index) {
                    final a = filtered[index];
                    return InkWell(
                      onTap: () {
                        widget.onAsetSelected(a);
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
                                color: AppColors.tintVioletBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.wrench, size: 18, color: AppColors.primaryPurple),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.nama,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (a.isPinjaman) ...[
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.tintOrangeBg,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.tintOrange.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        a.asalPenyedia != null && a.asalPenyedia!.isNotEmpty
                                            ? 'Aset Pinjaman dari: ${a.asalPenyedia}'
                                            : 'Aset Pinjaman',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.tintOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(
                                    '${a.kodeAset} • SN: ${a.nomorSeri}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kategori: ${a.kategori} • Kondisi: ${a.kondisi}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.plusCircle, size: 20, color: AppColors.primaryPurple),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoadingView(),
              error: (err, _) => AppErrorView(
                title: 'Gagal Memuat Daftar Aset',
                error: err,
                onRetry: () => ref.refresh(asetUnitTersediaProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
