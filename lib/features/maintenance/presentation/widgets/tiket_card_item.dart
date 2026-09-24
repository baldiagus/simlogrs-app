import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/tiket_maintenance_model.dart';
import '../screens/detail_tiket_screen.dart';

class TiketCardItem extends StatelessWidget {
  final TiketMaintenanceModel item;
  final VoidCallback? onCancelTap;

  const TiketCardItem({
    super.key,
    required this.item,
    this.onCancelTap,
  });

  Color _getPrioritasColor(String p) {
    switch (p.toUpperCase()) {
      case 'CITO':
        return AppColors.danger;
      case 'TINGGI':
        return AppColors.warning;
      case 'SEDANG':
        return AppColors.tintBlue;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getPrioritasBg(String p) {
    switch (p.toUpperCase()) {
      case 'CITO':
        return const Color(0xFFFEF2F2);
      case 'TINGGI':
        return const Color(0xFFFFFBEB);
      case 'SEDANG':
        return AppColors.tintBlueBg;
      default:
        return AppColors.surfaceSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pColor = _getPrioritasColor(item.prioritas);
    final pBg = _getPrioritasBg(item.prioritas);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isCito ? AppColors.danger.withValues(alpha: 0.35) : AppColors.border,
          width: item.isCito ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailTiketScreen(tiketId: item.id, kodeTiket: item.kode),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Kode Tiket, Prioritas, Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Container(
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: pBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.prioritas,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: pColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: item.status),
                ],
              ),
              const SizedBox(height: 12),

              // Nama Sarana / Alat
              Text(
                item.namaAset,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Kode: ${item.kodeAset} • SN: ${item.nomorSeri}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),

              // Deskripsi Masalah
              Text(
                item.deskripsiMasalah,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer: Teknisi Disposisi / Belum Ditugaskan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            item.penugasanAktif != null ? LucideIcons.wrench : LucideIcons.clock,
                            size: 13,
                            color: item.penugasanAktif != null ? AppColors.tintTeal : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.penugasanAktif != null
                                  ? 'Teknisi: ${item.penugasanAktif!.namaTeknisi} (${item.penugasanAktif!.kodeSpk})'
                                  : 'Menunggu Disposisi Teknisi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: item.penugasanAktif != null ? FontWeight.w700 : FontWeight.w500,
                                color: item.penugasanAktif != null ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Detail',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryPurple),
                        ),
                        Icon(LucideIcons.chevronRight, size: 14, color: AppColors.primaryPurple),
                      ],
                    ),
                  ],
                ),
              ),

              // Tombol Batal jika canCancel
              if (item.canCancel && onCancelTap != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tgl: ${item.dibuatPada ?? '-'}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onCancelTap,
                      icon: const Icon(LucideIcons.x, size: 13, color: AppColors.danger),
                      label: const Text('Batalkan', style: TextStyle(color: AppColors.danger, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
