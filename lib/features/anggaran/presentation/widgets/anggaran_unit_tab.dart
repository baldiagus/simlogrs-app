import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/core/theme/app_shadows.dart';
import 'package:simlog_mobile/core/utils/app_formatters.dart';
import 'package:simlog_mobile/features/anggaran/data/models/anggaran_models.dart';
import 'package:simlog_mobile/features/anggaran/presentation/providers/anggaran_provider.dart';
import 'package:simlog_mobile/shared/widgets/app_search_bar.dart';

/// Tab daftar anggaran per unit/ruangan dengan pencarian; ketuk kartu untuk membuka detail.
class AnggaranUnitTab extends ConsumerStatefulWidget {
  final List<UnitAnggaranModel> units;
  final String tahun;
  final ValueChanged<UnitAnggaranModel> onUnitTap;

  const AnggaranUnitTab({
    super.key,
    required this.units,
    required this.tahun,
    required this.onUnitTap,
  });

  /// Membuat state tab anggaran unit.
  @override
  ConsumerState<AnggaranUnitTab> createState() => _AnggaranUnitTabState();
}

/// State tab; menyimpan kata kunci pencarian untuk menyaring daftar unit.
class _AnggaranUnitTabState extends ConsumerState<AnggaranUnitTab> {
  String _searchQuery = '';

  /// Membangun kolom pencarian dan daftar kartu unit yang sudah disaring.
  @override
  Widget build(BuildContext context) {
    final filteredUnits = widget.units.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.unitNama.toLowerCase().contains(q) ||
          u.unitKode.toLowerCase().contains(q) ||
          u.posAnggaran.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AppSearchBar(
            hint: 'Cari ruangan atau unit kerja...',
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            onClear: () => setState(() => _searchQuery = ''),
          ),
        ),
        Expanded(
          child: filteredUnits.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Tidak ada data unit kerja yang sesuai kriteria.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.refresh(screeningAnggaranProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filteredUnits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final item = filteredUnits[index];
                      return _buildUnitCard(item, widget.tahun);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  /// Membangun kartu satu unit: pagu, realisasi, sisa, serapan, dan status anggaran.
  Widget _buildUnitCard(UnitAnggaranModel item, String tahun) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.tintBlueBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.unitKode.isNotEmpty ? item.unitKode : item.kode,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tintBlue, fontFamily: 'JetBrains Mono'),
                ),
              ),
                Text(item.unitNama, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amprah Logistik',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    Text(AppFormatters.rupiah(item.bebanDistribusi),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tintTeal)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sparepart Servis',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    Text(AppFormatters.rupiah(item.bebanSparepart),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tintViolet)),
                  ],
                ),
              ),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Beban Unit',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    Text(AppFormatters.rupiah(item.realisasi),
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => widget.onUnitTap(item),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.eye, size: 14, color: AppColors.primaryPurple),
                    SizedBox(width: 4),
                    Flexible(child: Text('Rincian Bukti Fisik',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primaryPurple))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
