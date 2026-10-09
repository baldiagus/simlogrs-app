import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../pengadaan/data/models/po_model.dart';

class ApprovalPoCard extends StatelessWidget {
  final PesananPembelianModel po;
  final bool canManagePo;
  final bool isReadOnly;
  final VoidCallback? onUpdateKirim;

  const ApprovalPoCard({
    super.key,
    required this.po,
    required this.canManagePo,
    required this.isReadOnly,
    this.onUpdateKirim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (po.isDiterbitkan && !isReadOnly)
              ? AppColors.primaryPurple.withValues(alpha: 0.4)
              : AppColors.border,
          width: (po.isDiterbitkan && !isReadOnly) ? 1.5 : 1.0,
        ),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                po.kode,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
              ),
              if (po.isDiterbitkan && !isReadOnly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.tintVioletBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Perlu Tindakan',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              StatusBadge(status: po.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rekanan / Vendor: ${po.namaPemasok}',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            po.prKode != null
                ? 'Dasar PR: ${po.prKode} (${po.prUnit ?? "-"})'
                : 'Dasar PR: Tanpa PR',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Nilai PO: ${AppFormatters.rupiah(po.totalBiaya)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.tintBlue),
              ),
              Text(
                'Estimasi: ${po.estimasiTanggalKirim}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          if (po.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              '${po.totalItem} Komoditas Dipesan:',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            ...po.items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${it.namaBarang} (${it.jumlahDipesan} ${it.satuan})',
                          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppFormatters.rupiah(it.subtotal),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )),
          ],
          if (po.isDiterbitkan && canManagePo) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onUpdateKirim,
                icon: const Icon(LucideIcons.truck, size: 16, color: Colors.white),
                label: const Text('Tandai Dikirim Vendor',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tintBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else if (isReadOnly) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.canvas, borderRadius: BorderRadius.circular(6)),
              child: const Text('Mode Pengawasan Eksekutif (Hanya Lihat)',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ),
          ],
        ],
      ),
    );
  }
}
