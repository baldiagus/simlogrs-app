import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/models/aset_detail_model.dart';

/// Bottom sheet berisi stiker QR code inventaris aset untuk dipindai di lapangan.
class QrStickerSheet extends StatelessWidget {
  final AsetDetailModel aset;

  /// Membuat sheet stiker QR dari data [aset].
  const QrStickerSheet({super.key, required this.aset});

  /// Menampilkan sheet stiker QR untuk [aset] sebagai modal bottom sheet.
  static Future<void> show(BuildContext context, AsetDetailModel aset) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QrStickerSheet(aset: aset),
    );
  }

  /// Membangun sheet berisi QR code kode aset, nama, nomor seri, dan tombol tutup.
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AppBottomSheetWrapper(
      title: 'Stiker QR Code Inventaris',
      subtitle: 'Gunakan QR ini untuk pemindaian fisik dan verifikasi di lapangan.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            // Screen preview keeps the QR readable without constraining text height.
            child: Column(
              children: [
                QrImageView(
                  data: aset.kodeAset,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: AppColors.surface,
                ),
                const SizedBox(height: 12),
                Text(
                  aset.kodeAset,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontFamily: 'JetBrains Mono', fontSize: 16, letterSpacing: 1.0),
                ),
                const SizedBox(height: 2),
                Text(
                  aset.namaKomoditas,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                if (aset.nomorSeri != '-') ...[
                  const SizedBox(height: 2),
                  Text(
                    'SN: ${aset.nomorSeri}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontFamily: 'JetBrains Mono', fontSize: 11),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 8),
                Text(
                  'SIMLOG RS • REGISTER INVENTARIS',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 0.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Tutup Stiker',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      ),
    );
  }
}
