import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../data/models/aset_tersedia_model.dart';
import '../providers/peminjaman_provider.dart';

/// Bottom sheet untuk mencari dan memilih aset tersedia dari katalog.
class AsetPickerBottomSheet extends ConsumerStatefulWidget {
  final ValueChanged<AsetTersediaModel> onAsetSelected;

  /// Membuat sheet pemilih aset dengan callback [onAsetSelected] saat aset dipilih.
  const AsetPickerBottomSheet({
    super.key,
    required this.onAsetSelected,
  });

  /// Membuat state untuk sheet pemilih aset.
  @override
  ConsumerState<AsetPickerBottomSheet> createState() => _AsetPickerBottomSheetState();
}

/// State pencarian katalog: menyimpan query dan memuat aset dari provider.
class _AsetPickerBottomSheetState extends ConsumerState<AsetPickerBottomSheet> {
  String _query = '';

  /// Membangun bottom sheet pencarian katalog aset tersedia; memilih satu
  /// aset memanggil callback lalu menutup sheet.
  @override
  Widget build(BuildContext context) {
    final katalogAsync = ref.watch(katalogAsetTersediaProvider(_query));

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
                  'Katalog Aset Siap Pinjam',
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
              onChanged: (v) => setState(() => _query = v.trim()),
              onClear: () => setState(() => _query = ''),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),

          // List Items
          Expanded(
            child: katalogAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyStateView(
                    icon: LucideIcons.packageSearch,
                    title: 'Aset Tidak Ditemukan',
                    message: 'Tidak ada aset berstatus TERSEDIA & BAIK pada ruangan lain atau gudang saat ini.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.border,
                    indent: 48,
                  ),
                  itemBuilder: (context, index) {
                    final aset = list[index];
                    return InkWell(
                      onTap: () {
                        widget.onAsetSelected(aset);
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
                                color: aset.isGudang ? AppColors.tintBlueBg : AppColors.tintOrangeBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                aset.isGudang ? LucideIcons.archive : LucideIcons.armchair,
                                size: 18,
                                color: aset.isGudang ? AppColors.tintBlue : AppColors.tintOrange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          aset.namaKomoditas,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: aset.isGudang ? AppColors.tintBlueBg : AppColors.tintOrangeBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          aset.tipePenyedia,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: aset.isGudang ? AppColors.tintBlue : AppColors.tintOrange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${aset.kodeAset} • SN: ${aset.nomorSeri}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Lokasi: ${aset.lokasiLengkap}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                title: 'Gagal Memuat Katalog Aset',
                error: err,
                onRetry: () => ref.refresh(katalogAsetTersediaProvider(_query)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
