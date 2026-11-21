import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../providers/anggaran_provider.dart';

/// Bottom sheet rincian pengeluaran satu unit: beban distribusi, sparepart, serta riwayat SPPB dan servis.
class UnitDrilldownSheet extends ConsumerWidget {
  final int unitId;
  final String tahun;
  final String unitNama;

  const UnitDrilldownSheet({
    super.key,
    required this.unitId,
    required this.tahun,
    required this.unitNama,
  });

  /// Membangun sheet drilldown dari [unitDrilldownProvider] dengan state loading, error (retry), dan data.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(unitDrilldownProvider((unitId: unitId, tahun: tahun)));

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Screening Pengeluaran TA $tahun',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primaryPurple)),
                    Text(unitNama,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: detailAsync.when(
              data: (detail) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3 Metric Stat Boxes
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.tintTealBg,
                                borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Amprah',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tintTeal)),
                                const SizedBox(height: 2),
                                Text(AppFormatters.rupiah(detail.bebanDistribusi),
                                    style: Theme.of(context).textTheme.labelMedium),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.tintVioletBg,
                                borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sparepart',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tintViolet)),
                                const SizedBox(height: 2),
                                Text(AppFormatters.rupiah(detail.bebanSparepart),
                                    style: Theme.of(context).textTheme.labelMedium),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.tintBlueBg,
                                borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tintBlue)),
                                const SizedBox(height: 2),
                                Text(AppFormatters.rupiah(detail.totalPengeluaran),
                                    style: Theme.of(context).textTheme.labelMedium),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Section 1: Riwayat Distribusi Amprah
                    Text('Riwayat Penyerahan Barang (SPPB)',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    if (detail.riwayatSppb.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                            'Belum ada penerimaan logistik amprah untuk unit ini pada TA $tahun.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      )
                    else
                      ...detail.riwayatSppb.map((sppb) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sppb.kode,
                                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontFamily: 'JetBrains Mono'),
                                      ),
                                      Text(
                                        '${sppb.gudangNama} • Tgl: ${sppb.tanggalKirim} • ${sppb.totalItem} item',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  AppFormatters.rupiah(sppb.totalNilai),
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tintTeal),
                                ),
                              ],
                            ),
                          )),

                    const SizedBox(height: 18),

                    // Section 2: Riwayat Servis Sarana & Sparepart
                    Text('Riwayat Penggantian Sparepart Sarana',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    if (detail.riwayatServis.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                            'Belum ada suku cadang terpasang untuk unit ini pada TA $tahun.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      )
                    else
                      ...detail.riwayatServis.map((servis) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        servis.sparepartNama,
                                        style: Theme.of(context).textTheme.labelMedium,
                                      ),
                                      Text(
                                        'Aset: ${servis.asetNama} (SPK: ${servis.spkKode}) • ${servis.tanggal}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontFamily: 'JetBrains Mono'),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(AppFormatters.rupiah(servis.subtotal),
                                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tintViolet)),
                                    Text('${servis.jumlah} unit',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
              loading: () => const AppLoadingView(),
              error: (err, _) => AppErrorView(
                title: 'Gagal Memuat Detail Screening',
                error: err,
                onRetry: () => ref.refresh(
                    unitDrilldownProvider((unitId: unitId, tahun: tahun))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
