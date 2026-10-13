import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/models/aset_detail_model.dart';

/// Tombol perpanjang & pengembalian fisik untuk aset yang sedang dipinjam.
class AsetDetailLoanActions extends StatelessWidget {
  final AsetDetailModel aset;
  final bool isProviderOwner;
  final bool isActionLoading;
  final VoidCallback onPerpanjang;
  final VoidCallback onPengembalian;

  /// Membuat tombol aksi peminjaman dengan data aset dan callback aksi.
  const AsetDetailLoanActions({
    super.key,
    required this.aset,
    required this.isProviderOwner,
    required this.isActionLoading,
    required this.onPerpanjang,
    required this.onPengembalian,
  });

  /// Membangun tombol perpanjang dan pengembalian sesuai hak akses dan
  /// status loading aksi.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: isProviderOwner ? 2 : 1,
              child: OutlinedButton.icon(
                onPressed: onPerpanjang,
                icon: const Icon(LucideIcons.calendarPlus,
                    size: 16, color: AppColors.primaryPurple),
                label: const Text(
                  'Perpanjang',
                  style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: AppColors.primaryPurple, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            if (isProviderOwner) ...[
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: CustomButton(
                  text: 'Kembalikan Fisik',
                  icon: const Icon(LucideIcons.packageCheck,
                      size: 18, color: Colors.white),
                  isLoading: isActionLoading,
                  onPressed: onPengembalian,
                ),
              ),
            ],
          ],
        ),
        if (!isProviderOwner) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.info,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Peminjam menyerahkan fisik aset ke unit ${aset.namaPenyedia} untuk proses inspeksi pengembalian resmi.',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Banner informasi bahwa aset sedang dalam antrean peminjaman unit lain.
class AsetDetailProsesPinjamNotice extends StatelessWidget {
  final AsetDetailModel aset;

  /// Membuat banner proses pinjam dari data [aset].
  const AsetDetailProsesPinjamNotice({super.key, required this.aset});

  /// Membangun banner oranye pemberitahuan aset sedang diproses peminjaman.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tintOrangeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.tintOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.clockAlert,
              size: 20, color: AppColors.tintOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sedang Dalam Proses Peminjaman',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tintOrange,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  aset.antreanPeminjaman != null
                      ? 'Aset ini sedang diajukan peminjaman oleh ${aset.antreanPeminjaman!['unit_peminjam']} (${aset.antreanPeminjaman!['kode_pinjam']}) dengan status ${aset.antreanPeminjaman!['status']}.'
                      : 'Aset ini sedang dalam antrean proses peminjaman unit lain dan belum dapat dipinjam.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
