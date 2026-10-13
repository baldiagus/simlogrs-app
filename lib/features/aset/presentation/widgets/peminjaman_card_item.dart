import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/peminjaman_aset_model.dart';

/// Kartu ringkasan satu peminjaman aset di daftar sirkulasi.
class PeminjamanCardItem extends StatelessWidget {
  final PeminjamanAsetModel item;
  final VoidCallback? onCancelTap;
  final VoidCallback? onReturnTap;
  final VoidCallback? onExtendTap;
  final VoidCallback? onDetailTap;
  final bool isPenyediaPerspective;

  /// Membuat kartu peminjaman; callback aksi opsional ditampilkan bila diberikan.
  const PeminjamanCardItem({
    super.key,
    required this.item,
    this.onCancelTap,
    this.onReturnTap,
    this.onExtendTap,
    this.onDetailTap,
    this.isPenyediaPerspective = false,
  });

  /// Membangun kartu peminjaman: info aset, periode, status, dan tombol aksi sesuai perspektif.
  @override
  Widget build(BuildContext context) {
    final firstItem = item.items.isNotEmpty ? item.items.first : null;
    final asetName = firstItem?.namaKomoditas ?? 'Aset Fisik';
    final asetCode = firstItem?.kodeAset ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isOverdue
              ? AppColors.danger.withValues(alpha: 0.35)
              : AppColors.border,
          width: item.isOverdue ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tintVioletBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.kode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                    StatusBadge(status: item.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Asset Name
                Text(
                  asetName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPenyediaPerspective
                      ? 'Kode: $asetCode • Dipinjam oleh: ${item.unitPeminjam}'
                      : 'Kode: $asetCode • Asal: ${item.namaPenyedia}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                // Overdue Warning
                if (item.isOverdue) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.alertTriangle, size: 14, color: AppColors.danger),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Peminjaman telah melewati batas waktu kembali!',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Dates Row
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${item.tanggalPinjam} s/d ${item.tanggalKembaliRencana}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (item.keperluan.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Keperluan: ${item.keperluan}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Action Row
          if (item.isDiajukan && onCancelTap != null) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onCancelTap,
                    icon: const Icon(LucideIcons.x, size: 14, color: AppColors.danger),
                    label: const Text('Batalkan Pengajuan', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (item.isDipinjam) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (!isPenyediaPerspective && onExtendTap != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onExtendTap,
                        icon: const Icon(LucideIcons.calendarPlus, size: 15, color: AppColors.primaryPurple),
                        label: const Text('Perpanjang', style: TextStyle(color: AppColors.primaryPurple, fontSize: 12, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryPurple),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  if (!isPenyediaPerspective && onExtendTap != null && onReturnTap != null)
                    const SizedBox(width: 10),
                  if (onReturnTap != null)
                    Expanded(
                      child: CustomButton(
                        text: isPenyediaPerspective ? 'Inspeksi & Terima Kembali' : 'Kembalikan Fisik',
                        height: 38,
                        backgroundColor: isPenyediaPerspective ? const Color(0xFF047857) : AppColors.primaryPurple,
                        icon: Icon(
                          isPenyediaPerspective ? LucideIcons.clipboardCheck : LucideIcons.packageCheck,
                          size: 15,
                          color: Colors.white,
                        ),
                        onPressed: onReturnTap,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
