import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../shared/widgets/app_quantity_stepper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/pr_model.dart';

class PrCartItemTile extends StatelessWidget {
  final PrCartItemModel item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final ValueChanged<String>? onCatatanChanged;

  const PrCartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    this.onCatatanChanged,
  });

  /// Membangun tile item keranjang PR berisi info barang dan pengatur jumlah
  /// agar pengguna dapat mengubah atau menghapus item.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.tintBlueBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.package, size: 20, color: AppColors.tintBlue),
              ),
              const SizedBox(width: 12),

              // Title & Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.barang.nama,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.barang.kode} • ${item.barang.kategori} (${item.barang.satuan})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Remove button
              IconButton(
                onPressed: onRemove,
                icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                tooltip: 'Hapus Item',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stepper & Satuan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Satuan: ${item.barang.satuan}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              AppQuantityStepper(
                value: item.jumlah,
                min: 1,
                // Jumlah di bawah 1 menghapus item; selain itu memperbarui jumlah.
                onChanged: (val) {
                  if (val < 1) {
                    onRemove();
                  } else {
                    onQuantityChanged(val);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

}
