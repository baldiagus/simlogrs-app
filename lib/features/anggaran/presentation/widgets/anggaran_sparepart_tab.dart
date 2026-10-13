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
                    const Row(
                      children: [
                        Icon(LucideIcons.wrench, size: 16, color: AppColors.tintViolet),
                        SizedBox(width: 6),
                        Text(
                          'Pos Suku Cadang IPSRS Sentral',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tintViolet,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Biaya Terpakai',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(
                              AppFormatters.rupiah(data.sparepartAnggaran!.realisasi),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.tintViolet,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            const Text(
              'Top 5 Aset Penyerap Biaya Pemeliharaan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Aset sarana rumah sakit dengan akumulasi biaya suku cadang tertinggi.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            if (data.topAset.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada pemakaian suku cadang pada aset untuk TA ini.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                    child: Row(
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                aset.nama,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${aset.kodeAset} • Lokasi: ${aset.lokasiRuangan}',
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.rupiah(aset.totalBiayaSparepart),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tintViolet,
                              ),
                            ),
                            Text(
                              '${aset.frekuensiServis}x servis',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),

            const SizedBox(height: 20),

            const Text(
              'Log Konsumsi Suku Cadang Terakhir',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Catatan suku cadang yang dipasang teknisi pada lembar kerja SPK.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            if (data.riwayatSparepart.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada log pergantian suku cadang.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.sparepartNama,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Aset: ${log.asetNama} (SPK: ${log.spkKode})',
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.textSecondary),
                              ),
                              Text(
                                'Batch: ${log.nomorBatch} • Tgl: ${log.tanggal}',
                                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.rupiah(log.subtotal),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tintTeal,
                              ),
                            ),
                            Text(
                              '${log.jumlah} unit',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
