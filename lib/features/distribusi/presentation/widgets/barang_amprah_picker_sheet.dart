import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../data/models/amprah_model.dart';
import '../providers/distribusi_provider.dart';

/// Bottom sheet pemilih barang dari katalog amprah dengan pencarian dan indikator stok.
class BarangAmprahPickerSheet extends ConsumerStatefulWidget {
  final ValueChanged<BarangAmprahKatalogModel> onBarangSelected;
  final int? gudangId;
  final String? namaGudang;

  const BarangAmprahPickerSheet({
    super.key,
    required this.onBarangSelected,
    this.gudangId,
    this.namaGudang,
  });

  /// Membuat state untuk sheet pemilih barang amprah.
  @override
  ConsumerState<BarangAmprahPickerSheet> createState() => _BarangAmprahPickerSheetState();
}

class _BarangAmprahPickerSheetState extends ConsumerState<BarangAmprahPickerSheet> {
  String _query = '';

  /// Membangun sheet katalog: header, kolom pencarian, dan daftar barang dari provider
  /// sesuai kata kunci (loading, error, kosong, data).
  @override
  Widget build(BuildContext context) {
    final params = KatalogAmprahFilterParams(query: _query, gudangId: widget.gudangId);
    final katalogAsync = ref.watch(katalogAmprahProvider(params));

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Katalog Barang Amprah',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.namaGudang != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Gudang Tujuan: ${widget.namaGudang}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
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
              hint: 'Cari nama barang, kode SKU, atau kategori...',
              // Simpan kata kunci pencarian (dipangkas) agar katalog difilter ulang.
              onChanged: (v) => setState(() => _query = v.trim()),
              // Kosongkan kata kunci agar seluruh katalog tampil kembali.
              onClear: () => setState(() => _query = ''),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),

          // Catalog List
          Expanded(
            child: katalogAsync.when(
              // Tampilkan daftar katalog, atau tampilan kosong bila tidak ada hasil.
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyStateView(
                    icon: LucideIcons.packageSearch,
                    title: 'Barang Tidak Ditemukan',
                    message: 'Tidak ada komoditas logistik yang sesuai dengan pencarian Anda.',
                  );
                }
                final sortedList = List<BarangAmprahKatalogModel>.from(list)
                  ..sort((a, b) => (b.stokTersedia > 0 ? 1 : 0).compareTo(a.stokTersedia > 0 ? 1 : 0));

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: sortedList.length,
                  // Pemisah tipis antarbarang di daftar.
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border, indent: 48),
                  // Bangun satu baris barang: nama, kode, kategori, dan status stok/backorder.
                  itemBuilder: (context, index) {
                    final b = sortedList[index];
                    final hasStok = b.stokTersedia > 0;
                    return InkWell(
                      // Kirim barang terpilih ke pemanggil lalu tutup sheet.
                      onTap: () {
                        Navigator.pop(context);
                        widget.onBarangSelected(b);
                      },
                      borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: hasStok ? AppColors.tintBlueBg : AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  LucideIcons.package,
                                  size: 18,
                                  color: hasStok ? AppColors.tintBlue : AppColors.textMuted,
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
                                            b.nama,
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
                                            color: AppColors.surfaceSecondary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            b.tipeLabel,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${b.kode} • ${b.kategori} (${b.satuan})',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 2),
                                    if (b.stokTersedia > 0)
                                      Text(
                                        'Stok Tersedia: ${b.stokTersedia} ${b.satuan}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success,
                                        ),
                                      )
                                    else if (b.stokTersedia == 0 &&
                                        b.bestGudangNama != null &&
                                        b.bestGudangStok != null &&
                                        b.bestGudangStok! > 0)
                                      Text(
                                        'Tersedia ${b.bestGudangStok} ${b.satuan} di ${b.bestGudangNama}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.tintBlue,
                                        ),
                                      )
                                    else
                                      const Text(
                                        'Stok Kosong (Dicatat sebagai Backorder)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.tintOrange,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (hasStok)
                                const Icon(
                                  LucideIcons.plusCircle,
                                  size: 20,
                                  color: AppColors.primaryPurple,
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFDBA74).withValues(alpha: 0.5)),
                                  ),
                                  child: const Text(
                                    'Backorder',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
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
                // Muat ulang katalog dengan kata kunci saat ini setelah gagal.
                onRetry: () => ref.refresh(katalogAmprahProvider(params)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
