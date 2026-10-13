import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_quantity_stepper.dart';
import '../../data/models/aset_tersedia_model.dart';

/// Tahap 2 form pengalihan aset: kuantitas, alasan, dan catatan.
class ModalPengalihanAsetTahap2Card extends StatelessWidget {
  final AsetTersediaModel? chosenAset;
  final AsyncValue<List<AsetTersediaModel>> katalogAsync;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final TextEditingController alasanController;
  final TextEditingController catatanController;

  /// Membuat kartu tahap 2 dengan state kuantitas dan controller teks dari sheet induk.
  const ModalPengalihanAsetTahap2Card({
    super.key,
    required this.chosenAset,
    required this.katalogAsync,
    required this.quantity,
    required this.onQuantityChanged,
    required this.alasanController,
    required this.catatanController,
  });

  /// Menghitung jumlah maksimal aset sejenis (komoditas + penyedia sama) yang boleh dialihkan, minimal 1.
  int get _maxAvailable {
    final list = katalogAsync.valueOrNull ?? [];
    final count = chosenAset != null
        ? list
            .where((a) =>
                a.namaKomoditas.trim().toLowerCase() ==
                    chosenAset!.namaKomoditas.trim().toLowerCase() &&
                a.tipePenyedia == chosenAset!.tipePenyedia &&
                a.penyediaId == chosenAset!.penyediaId)
            .length
        : 1;
    return count > 0 ? count : 1;
  }

  /// Membangun kartu tahap 2: stepper jumlah (dibatasi stok aset sejenis), alasan, dan catatan pengalihan.
  @override
  Widget build(BuildContext context) {
    final maxAvailable = _maxAvailable;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tahap 2: Kuantitas & Alasan',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          // Stepper Kuantitas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jumlah Unit Dialihkan *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chosenAset != null && maxAvailable > 1
                            ? 'Tersedia: $maxAvailable unit di ${chosenAset!.namaPenyedia}'
                            : '1 unit per nomor inventaris fisik',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AppQuantityStepper(
                  key: const Key('stepper_jumlah_aset'),
                  value: quantity.clamp(1, maxAvailable),
                  min: 1,
                  max: maxAvailable,
                  onChanged: onQuantityChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Alasan
          TextFormField(
            key: const Key('field_alasan_pengalihan'),
            controller: alasanController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Alasan / Dasar Pengalihan (Wajib) *',
              hintText:
                  'Jelaskan kebutuhan mutasi permanen ke unit kerja Anda...',
              prefixIcon: Icon(LucideIcons.fileText, size: 18),
            ),
            validator: (v) {
              if (v == null || v.trim().length < 5) {
                return 'Alasan pengalihan wajib diisi minimal 5 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          // Catatan
          TextFormField(
            controller: catatanController,
            decoration: const InputDecoration(
              labelText: 'Catatan Tambahan (Opsional)',
              hintText: 'Kondisi fisik awal, kelengkapan kabel, aksesoris...',
              prefixIcon: Icon(LucideIcons.messageSquare, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
