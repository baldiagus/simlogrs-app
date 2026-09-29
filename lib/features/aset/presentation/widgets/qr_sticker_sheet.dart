import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/models/aset_detail_model.dart';

class QrStickerSheet extends StatelessWidget {
  final AsetDetailModel aset;

  const QrStickerSheet({super.key, required this.aset});

  static Future<void> show(BuildContext context, AsetDetailModel aset) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QrStickerSheet(aset: aset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetWrapper(
      title: 'Stiker QR Code Inventaris',
      subtitle: 'Gunakan QR ini untuk pemindaian fisik dan verifikasi di lapangan.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                QrImageView(
                  data: aset.kodeAset,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  aset.kodeAset,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  aset.namaKomoditas,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  textAlign: TextAlign.center,
                ),
                if (aset.nomorSeri != '-') ...[
                  const SizedBox(height: 2),
                  Text(
                    'SN: ${aset.nomorSeri}',
                    style: const TextStyle(
                        fontSize: 11, fontFamily: 'monospace', color: Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 8),
                const Text(
                  'SIMLOG RS • REGISTER INVENTARIS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
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
    );
  }
}
