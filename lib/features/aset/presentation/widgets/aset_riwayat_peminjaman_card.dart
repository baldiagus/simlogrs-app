import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/aset_detail_model.dart';

/// Kartu ringkasan riwayat peminjaman/sirkulasi aset antar unit.
class AsetRiwayatPeminjamanCard extends StatelessWidget {
  final List<RiwayatPeminjamanAsetItemModel> riwayat;
  final VoidCallback onTap;

  /// Membuat kartu riwayat peminjaman dengan daftar [riwayat] dan callback [onTap].
  const AsetRiwayatPeminjamanCard({
    super.key,
    required this.riwayat,
    required this.onTap,
  });

  /// Membangun kartu ringkasan riwayat peminjaman aset yang bisa diketuk
  /// untuk membuka histori sirkulasi lengkap.
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
                      Icon(LucideIcons.history, size: 16, color: AppColors.primaryPurple),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Histori Sirkulasi (Peminjaman)',
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
                        '${riwayat.length}x Dipinjam',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: riwayat.isNotEmpty
                              ? AppColors.primaryPurple
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
                              latest.kodePeminjaman,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primaryPurple, fontFamily: 'JetBrains Mono'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: latest.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Peminjam: ${latest.unitPeminjam} (${latest.peminjam})',
                        style: Theme.of(context).textTheme.labelMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Masa Pinjam: ${latest.tanggalPinjam} s/d ${latest.tanggalKembaliRencana}',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaksi Terakhir',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Buka Buku Sirkulasi Lengkap',
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
                );
              }(),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.success),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Belum ada riwayat peminjaman fisik. Ketuk untuk membuka sirkulasi...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(LucideIcons.arrowRight, size: 14, color: AppColors.primaryPurple),
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
