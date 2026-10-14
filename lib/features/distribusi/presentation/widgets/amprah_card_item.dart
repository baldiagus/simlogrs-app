import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/amprah_model.dart';
import '../screens/detail_amprah_screen.dart';

class AmprahCardItem extends StatelessWidget {
  final AmprahHeaderModel item;
  final VoidCallback? onCancelTap;
  /// Aksi setujui Meja 1/Meja 2; null bila user tidak berhak atau status tidak sesuai.
  final VoidCallback? onSetujuiTap;
  /// Aksi tolak Meja 1/Meja 2; null bila user tidak berhak atau status tidak sesuai.
  final VoidCallback? onTolakTap;

  const AmprahCardItem({
    super.key,
    required this.item,
    this.onCancelTap,
    this.onSetujuiTap,
    this.onTolakTap,
  });

  /// Membangun kartu ringkasan amprah (kode, urgensi CITO, status, unit, jumlah item)
  /// yang bisa diketuk untuk membuka detail dan menampilkan tombol batal bila diizinkan.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isCito
              ? AppColors.danger.withValues(alpha: 0.35)
              : AppColors.border,
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
        // Buka layar detail amprah berdasarkan id dan kode yang dipilih.
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailAmprahScreen(amprahId: item.id, kodeAmprah: item.kode),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Kode Amprah, Urgensi CITO, Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      if (item.isCito) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'CITO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  StatusBadge(status: item.status),
                ],
              ),
              const SizedBox(height: 12),

              // Unit Pemohon & Pengaju
              Text(
                item.unit,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tgl: ${item.tanggalPermintaan} • Oleh ${item.pengaju} (Tujuan: ${item.gudang})',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),

              // Breakdown items preview
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.boxes, size: 14, color: AppColors.primaryPurple),
                        const SizedBox(width: 6),
                        Text(
                          '${item.jumlahItem} Item Barang Diminta',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Row(
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

              // Batal action if DIAJUKAN
              if (item.canCancel && onCancelTap != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onCancelTap,
                      icon: const Icon(LucideIcons.x, size: 13, color: AppColors.danger),
                      label: const Text('Batalkan Amprah', style: TextStyle(color: AppColors.danger, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
              // Aksi keputusan Meja 1/Meja 2 (setujui/tolak) bila user berhak pada status ini.
              if (onSetujuiTap != null || onTolakTap != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onTolakTap != null)
                      OutlinedButton.icon(
                        onPressed: onTolakTap,
                        icon: const Icon(LucideIcons.x, size: 13, color: AppColors.danger),
                        label: const Text('Tolak', style: TextStyle(color: AppColors.danger, fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (onTolakTap != null && onSetujuiTap != null) const SizedBox(width: 8),
                    if (onSetujuiTap != null)
                      ElevatedButton.icon(
                        onPressed: onSetujuiTap,
                        icon: const Icon(LucideIcons.checkCheck, size: 13, color: Colors.white),
                        label: const Text('Setujui', style: TextStyle(color: Colors.white, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
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
