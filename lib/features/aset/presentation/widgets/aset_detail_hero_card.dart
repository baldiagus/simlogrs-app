import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/aset_detail_model.dart';

/// Kartu utama di bagian atas detail aset (nama, kode, status, tombol QR).
class AsetDetailHeroCard extends StatelessWidget {
  final AsetDetailModel aset;
  final VoidCallback onShowQr;

  /// Membuat kartu hero dengan data [aset] dan callback [onShowQr].
  const AsetDetailHeroCard(
      {super.key, required this.aset, required this.onShowQr});

  /// Membangun kartu utama bergradien berisi identitas aset, status, dan
  /// tombol untuk menampilkan QR.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryHeroGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    aset.kodeAset,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.surface, fontFamily: 'JetBrains Mono'),
                  ),
                ),
              StatusBadge(status: aset.status),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            aset.namaKomoditas,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.surface),
          ),
          const SizedBox(height: 4),
          Text(
            '${aset.kategori} • Nomor Seri: ${aset.nomorSeri}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.surface, fontFamily: 'JetBrains Mono'),
          ),
          const SizedBox(height: 14),
          // Quick Action: Lihat Stiker QR Button
          InkWell(
            onTap: onShowQr,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.qrCode, color: AppColors.surface, size: 16),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Lihat Stiker QR Inventaris',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.surface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner peringatan bahwa aset melewati batas rencana pengembalian.
class AsetDetailOverdueBanner extends StatelessWidget {
  final PeminjamanAktifInfo loan;

  /// Membuat banner keterlambatan dari data peminjaman aktif [loan].
  const AsetDetailOverdueBanner({super.key, required this.loan});

  /// Membangun banner merah peringatan keterlambatan pengembalian aset.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle,
              size: 22, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peminjaman Melebihi Batas Waktu!',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.danger),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rencana kembali: ${loan.tanggalKembaliRencana ?? '-'}. Mohon segera lakukan pengembalian fisik.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
