import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/aset_detail_model.dart';

/// Kartu ringkasan riwayat pengalihan/mutasi fisik aset antar lokasi.
class AsetHistoriPengalihanCard extends StatelessWidget {
  final List<RiwayatPengalihanAsetItemModel> riwayat;
  final VoidCallback onTap;

  /// Membuat kartu histori pengalihan dengan daftar [riwayat] dan callback [onTap].
  const AsetHistoriPengalihanCard({
    super.key,
    required this.riwayat,
    required this.onTap,
  });

  /// Membangun kartu ringkasan histori pengalihan/mutasi aset yang bisa
  /// diketuk untuk membuka histori lengkap.
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
                      Icon(LucideIcons.arrowRightLeft, size: 16, color: AppColors.primaryPurple),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Histori Pengalihan & Mutasi',
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: riwayat.isNotEmpty
                            ? AppColors.tintVioletBg
                            : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${riwayat.length}x Dimutasi',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: riwayat.isNotEmpty
                              ? AppColors.primaryPurple
                              : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primaryPurple),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (riwayat.isNotEmpty) ...[
              () {
                final latest = riwayat.first;
                return Container(
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
                          Flexible(
                            child: Text(
                              latest.kodePengalihan,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primaryPurple, fontFamily: 'JetBrains Mono'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: latest.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              latest.asalNama,
                              style: Theme.of(context).textTheme.labelMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(LucideIcons.arrowRight, size: 12, color: AppColors.primaryPurple),
                          ),
                          Expanded(
                            child: Text(
                              latest.tujuanNama,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primaryPurple),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Diserahterimakan: ${latest.tanggalSerahTerima}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mutasi Terakhir Selesai',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Buka Buku Mutasi Lengkap',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primaryPurple),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(LucideIcons.arrowUpRight, size: 12, color: AppColors.primaryPurple),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }(),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aset ini belum pernah dialihkan (masih di lokasi perolehan awal).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
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
