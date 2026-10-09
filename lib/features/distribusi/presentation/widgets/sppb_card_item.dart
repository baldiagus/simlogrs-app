import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/sppb_model.dart';

class SppbCardItem extends StatelessWidget {
  final SppbHeaderModel item;
  final VoidCallback? onTerimaTap;

  const SppbCardItem({
    super.key,
    required this.item,
    this.onTerimaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tintBlueBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.truck, size: 14, color: AppColors.tintBlue),
                          const SizedBox(width: 4),
                          Text(
                            item.kode,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tintBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: item.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Asal Gudang & Tujuan
                Text(
                  'Dikirim ke ${item.unit}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Asal: ${item.gudang} • Tgl Kirim: ${item.tanggalKirim ?? '-'} • Ekspedisi: ${item.pengirim}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                // Detail Items list
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            '${item.totalItem} Item Barang Dikirim:',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          const Text(
                            'Status: Menuju Ruangan',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.tintBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...item.items.map((d) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '• ${d.namaBarang} (Batch: ${d.nomorBatch})',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${d.jumlahDikirim} ${d.satuan}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action button konfirmasi terima
          if (item.isDikirim && onTerimaTap != null) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: CustomButton(
                text: 'Konfirmasi Terima Barang di Ruangan',
                height: 42,
                backgroundColor: AppColors.success,
                icon: const Icon(LucideIcons.checkCheck, size: 16, color: Colors.white),
                onPressed: onTerimaTap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
