import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/core/theme/app_shadows.dart';
import 'package:simlog_mobile/core/utils/app_formatters.dart';
import 'package:simlog_mobile/features/anggaran/data/models/anggaran_models.dart';
import 'package:simlog_mobile/features/anggaran/presentation/providers/anggaran_provider.dart';
import 'package:simlog_mobile/shared/widgets/app_search_bar.dart';

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

  @override
  ConsumerState<AnggaranUnitTab> createState() => _AnggaranUnitTabState();
}

class _AnggaranUnitTabState extends ConsumerState<AnggaranUnitTab> {
  String _searchQuery = '';

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
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Tidak ada data unit kerja yang sesuai kriteria.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

  Widget _buildUnitCard(UnitAnggaranModel item, String tahun) {
    final statusColor = item.status == 'Over-Budget'
        ? AppColors.danger
        : (item.status == 'Waspada' ? AppColors.warning : AppColors.success);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.tintBlueBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.unitKode.isNotEmpty ? item.unitKode : item.kode,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.tintBlue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.unitNama,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 10, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amprah Logistik',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text(AppFormatters.rupiah(item.bebanDistribusi),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.tintTeal)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sparepart Servis',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text(AppFormatters.rupiah(item.bebanSparepart),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.tintViolet)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Beban Unit',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text(AppFormatters.rupiah(item.realisasi),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pagu: ${AppFormatters.rupiah(item.pagu)}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('Serapan: ${item.serapan.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (item.serapan / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => widget.onUnitTap(item),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.eye, size: 14, color: AppColors.primaryPurple),
                    SizedBox(width: 4),
                    Text('Rincian Bukti Fisik',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryPurple)),
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
