import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/aset_detail_model.dart';

class AsetDetailHeroCard extends StatelessWidget {
  final AsetDetailModel aset;
  final VoidCallback onShowQr;

  const AsetDetailHeroCard(
      {super.key, required this.aset, required this.onShowQr});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    aset.kodeAset,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: aset.status),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            aset.namaKomoditas,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${aset.kategori} • Nomor Seri: ${aset.nomorSeri}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          // Quick Action: Lihat Stiker QR Button
          InkWell(
            onTap: onShowQr,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.qrCode, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Lihat Stiker QR Inventaris',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
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

class AsetDetailOverdueBanner extends StatelessWidget {
  final PeminjamanAktifInfo loan;

  const AsetDetailOverdueBanner({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
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
                const Text(
                  'Peminjaman Melebihi Batas Waktu!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rencana kembali: ${loan.tanggalKembaliRencana ?? '-'}. Mohon segera lakukan pengembalian fisik.',
                  style: const TextStyle(fontSize: 11, color: AppColors.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
