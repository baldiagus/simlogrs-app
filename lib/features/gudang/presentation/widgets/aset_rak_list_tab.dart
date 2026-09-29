import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../data/models/aset_rak_model.dart';

class AsetRakListTab extends StatefulWidget {
  final List<AsetRakModel> items;

  const AsetRakListTab({
    super.key,
    required this.items,
  });

  @override
  State<AsetRakListTab> createState() => _AsetRakListTabState();
}

class _AsetRakListTabState extends State<AsetRakListTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((a) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return a.namaAset.toLowerCase().contains(q) ||
          a.kodeAset.toLowerCase().contains(q) ||
          (a.merk?.toLowerCase().contains(q) ?? false) ||
          (a.nomorSeri?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Column(
      children: [
        // In-Shelf Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AppSearchBar(
            hint: 'Cari aset, nomor seri, atau kode...',
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            onClear: () => setState(() => _searchQuery = ''),
          ),
        ),

        // List
        Expanded(
          child: filtered.isEmpty
              ? EmptyStateView(
                  icon: LucideIcons.package,
                  title: _searchQuery.isEmpty
                      ? 'Tidak Ada Aset Fisik'
                      : 'Aset Tidak Ditemukan',
                  message: _searchQuery.isEmpty
                      ? 'Rak ini saat ini belum menyimpan unit fisik sarana atau aset peralatan.'
                      : 'Tidak ada unit aset yang cocok dengan kata kunci "$_searchQuery".',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildAsetCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAsetCard(AsetRakModel item) {
    Color statusBg = AppColors.success.withValues(alpha: 0.1);
    Color statusText = AppColors.success;
    if (item.statusKetersediaan == 'DIPINJAM') {
      statusBg = AppColors.warning.withValues(alpha: 0.1);
      statusText = AppColors.warning;
    } else if (item.statusKetersediaan == 'DALAM_MAINTENANCE' || item.statusKetersediaan == 'RUSAK') {
      statusBg = AppColors.danger.withValues(alpha: 0.1);
      statusText = AppColors.danger;
    }

    Color kondisiBg = AppColors.success.withValues(alpha: 0.1);
    Color kondisiText = AppColors.success;
    if (item.kondisiFisik == 'RUSAK_RINGAN') {
      kondisiBg = AppColors.warning.withValues(alpha: 0.1);
      kondisiText = AppColors.warning;
    } else if (item.kondisiFisik == 'RUSAK_BERAT') {
      kondisiBg = AppColors.danger.withValues(alpha: 0.1);
      kondisiText = AppColors.danger;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.tintOrangeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.package, size: 20, color: AppColors.tintOrange),
              ),
              const SizedBox(width: 12),

              // Title & Serial
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaAset,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.kodeAset} • SN: ${item.nomorSeri ?? '-'}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.statusKetersediaan,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),

          // Detail Merk, Model, Kondisi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Merk/Model: ${item.merk ?? '-'} / ${item.model ?? '-'}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kondisiBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Kondisi: ${item.kondisiFisik}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: kondisiText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
