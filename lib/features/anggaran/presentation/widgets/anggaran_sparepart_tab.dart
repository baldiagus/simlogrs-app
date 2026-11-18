import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/core/theme/app_shadows.dart';
import 'package:simlog_mobile/core/utils/app_formatters.dart';
import 'package:simlog_mobile/features/anggaran/data/models/anggaran_models.dart';
import 'package:simlog_mobile/features/anggaran/presentation/providers/anggaran_provider.dart';

/// Tab anggaran sparepart IPSRS: ringkasan pagu/realisasi, top aset, dan riwayat pemakaian sparepart.
class AnggaranSparepartTab extends ConsumerWidget {
  final AnggaranScreeningModel data;
  final String tahun;

  const AnggaranSparepartTab({
    super.key,
    required this.data,
    required this.tahun,
  });

  /// Membangun konten tab dengan pull-to-refresh yang memuat ulang [screeningAnggaranProvider].
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(screeningAnggaranProvider),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.sparepartAnggaran != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.softCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.wrench, size: 16, color: AppColors.tintViolet),
                        SizedBox(width: 6),
                        Expanded(child: Text(
                          'Pos Suku Cadang IPSRS Sentral',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tintViolet),
                        )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Total Biaya Terpakai',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    Text(
                      AppFormatters.rupiah(data.sparepartAnggaran!.realisasi),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.tintViolet),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            Text(
              'Top 5 Aset Penyerap Biaya Pemeliharaan',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              'Aset sarana rumah sakit dengan akumulasi biaya suku cadang tertinggi.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            if (data.topAset.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada pemakaian suku cadang pada aset untuk TA ini.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              )
            else
              ...data.topAset.map((aset) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.tintOrangeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.armchair,
                              size: 16, color: AppColors.tintOrange),
                        ),
                        const SizedBox(height: 8),
                        Text(aset.nama, style: Theme.of(context).textTheme.labelMedium),
                        Text('${aset.kodeAset} • Lokasi: ${aset.lokasiRuangan}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontFamily: 'JetBrains Mono')),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.rupiah(aset.totalBiayaSparepart),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tintViolet),
                            ),
                            Text(
                              '${aset.frekuensiServis}x servis',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),

            const SizedBox(height: 20),

            Text(
              'Log Konsumsi Suku Cadang Terakhir',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              'Catatan suku cadang yang dipasang teknisi pada lembar kerja SPK.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            if (data.riwayatSparepart.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada log pergantian suku cadang.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              )
            else
              ...data.riwayatSparepart.map((log) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.sparepartNama,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(
                                'Aset: ${log.asetNama} (SPK: ${log.spkKode})',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontFamily: 'JetBrains Mono'),
                              ),
                              Text(
                                'Batch: ${log.nomorBatch} • Tgl: ${log.tanggal}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontFamily: 'JetBrains Mono'),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.rupiah(log.subtotal),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tintTeal),
                            ),
                            Text(
                              '${log.jumlah} unit',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
