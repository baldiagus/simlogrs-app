import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../data/models/aset_tersedia_model.dart';
import '../providers/peminjaman_provider.dart';

class AsetPickerBottomSheet extends ConsumerStatefulWidget {
  final ValueChanged<AsetTersediaModel> onAsetSelected;

  const AsetPickerBottomSheet({
    super.key,
    required this.onAsetSelected,
  });

  @override
  ConsumerState<AsetPickerBottomSheet> createState() => _AsetPickerBottomSheetState();
}

class _AsetPickerBottomSheetState extends ConsumerState<AsetPickerBottomSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Cari kode aset, nama sarana, nomor seri...',
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.xCircle, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
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
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryPurple),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    err.toString().replaceAll('ApiException: ', ''),
                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
