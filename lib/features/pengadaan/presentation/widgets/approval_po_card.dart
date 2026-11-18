import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/po_model.dart';

/// Kartu ringkasan Pesanan Pembelian (PO) untuk antrean approval/pengadaan.
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

  /// Menyusun kartu PO: kode, vendor, nilai, daftar item, dan tombol tandai dikirim bila user berhak dan PO diterbitkan.
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
                style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w800,  color: AppColors.textPrimary, fontFamily: 'JetBrains Mono'),
              ),
              if (po.isDiterbitkan && !isReadOnly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.tintVioletBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Perlu Tindakan',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
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
            style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700,  color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            po.prKode != null
                ? 'Dasar PR: ${po.prKode} (${po.prUnit ?? "-"})'
                : 'Dasar PR: Tanpa PR',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textSecondary),
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
                style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w800,  color: AppColors.tintBlue),
              ),
              Text(
                'Estimasi: ${po.estimasiTanggalKirim}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          if (po.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              '${po.totalItem} Komoditas Dipesan:',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            ...po.items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${it.namaBarang} (${it.jumlahDipesan} ${it.satuan})',
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textPrimary),
                        ),
                      Text(
                        AppFormatters.rupiah(it.subtotal),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
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
                label: Text('Tandai Dikirim Vendor',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(color: AppColors.surface, fontWeight: FontWeight.w700)),
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
              child: Text('Mode Pengawasan Eksekutif (Hanya Lihat)',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textMuted)),
            ),
          ],
        ],
      ),
    );
  }
}
