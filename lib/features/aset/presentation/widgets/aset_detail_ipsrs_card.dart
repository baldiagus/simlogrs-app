import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/aset_detail_model.dart';

/// Kartu ringkasan riwayat servis/pemeliharaan IPSRS pada detail aset.
class AsetDetailIpsrsCard extends StatelessWidget {
  final AsetDetailModel aset;
  final VoidCallback onTap;

  /// Membuat kartu IPSRS dengan data [aset] dan callback [onTap].
  const AsetDetailIpsrsCard(
      {super.key, required this.aset, required this.onTap});

  /// Membangun kartu ringkasan servis IPSRS (servis terakhir/jadwal) yang
  /// bisa diketuk untuk membuka detailnya.
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
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
                      Icon(LucideIcons.wrench,
                          size: 16, color: AppColors.primaryPurple),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Histori Pemeliharaan (IPSRS)',
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: aset.totalRiwayatServis > 0
                            ? AppColors.tintOrangeBg
                            : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${aset.totalRiwayatServis}x Servis',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: aset.totalRiwayatServis > 0
                              ? AppColors.tintOrange
                              : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.chevronRight,
                        size: 16, color: AppColors.primaryPurple),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (aset.servisTerakhir != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            aset.servisTerakhir!.kode,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primaryPurple, fontFamily: 'JetBrains Mono'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: aset.servisTerakhir!.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      aset.servisTerakhir!.deskripsi,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tgl: ${aset.servisTerakhir!.tanggalPengajuan}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Buka Rekam Medis & Preventif',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primaryPurple),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(LucideIcons.arrowRight,
                                  size: 12, color: AppColors.primaryPurple),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.checkCircle2,
                        size: 16, color: AppColors.success),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Belum ada catatan servis kerusakan. Buka rekam medis alat...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(LucideIcons.arrowRight,
                        size: 14, color: AppColors.primaryPurple),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
