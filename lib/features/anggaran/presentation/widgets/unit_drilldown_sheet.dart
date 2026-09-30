import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../providers/anggaran_provider.dart';

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
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryPurple)),
                    Text(unitNama,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
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
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.tintTealBg,
                                borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Amprah',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.tintTeal,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(AppFormatters.rupiah(detail.bebanDistribusi),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.tintVioletBg,
                                borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sparepart',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.tintViolet,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(AppFormatters.rupiah(detail.bebanSparepart),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.tintBlueBg,
                                borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.tintBlue,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(AppFormatters.rupiah(detail.totalPengeluaran),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Section 1: Riwayat Distribusi Amprah
                    const Text('Riwayat Penyerahan Barang (SPPB)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (detail.riwayatSppb.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                            'Belum ada penerimaan logistik amprah untuk unit ini pada TA $tahun.',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                      )
                    else
                      ...detail.riwayatSppb.map((sppb) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sppb.kode,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${sppb.gudangNama} • Tgl: ${sppb.tanggalKirim} • ${sppb.totalItem} item',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppFormatters.rupiah(sppb.totalNilai),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.tintTeal,
                                  ),
                                ),
                              ],
                            ),
                          )),

                    const SizedBox(height: 18),

                    // Section 2: Riwayat Servis Sarana & Sparepart
                    const Text('Riwayat Penggantian Sparepart Sarana',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (detail.riwayatServis.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                            'Belum ada suku cadang terpasang untuk unit ini pada TA $tahun.',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                      )
                    else
                      ...detail.riwayatServis.map((servis) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        servis.sparepartNama,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Aset: ${servis.asetNama} (SPK: ${servis.spkKode}) • ${servis.tanggal}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(AppFormatters.rupiah(servis.subtotal),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.tintViolet)),
                                    Text('${servis.jumlah} unit',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary)),
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
