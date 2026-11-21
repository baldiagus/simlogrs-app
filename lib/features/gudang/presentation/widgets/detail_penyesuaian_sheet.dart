import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/penyesuaian_stok_model.dart';

/// Bottom sheet detail penyesuaian stok hasil opname, dengan aksi otorisasi/tolak bila user berwenang.
class DetailPenyesuaianSheet extends StatelessWidget {
  final PenyesuaianStokHeaderModel adj;
  final bool canAuthorize;
  final VoidCallback? onAuthorize;
  final VoidCallback? onReject;

  const DetailPenyesuaianSheet({
    super.key,
    required this.adj,
    required this.canAuthorize,
    this.onAuthorize,
    this.onReject,
  });

  /// Menampilkan sheet detail penyesuaian sebagai modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required PenyesuaianStokHeaderModel adj,
    required bool canAuthorize,
    VoidCallback? onAuthorize,
    VoidCallback? onReject,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DetailPenyesuaianSheet(
        adj: adj,
        canAuthorize: canAuthorize,
        onAuthorize: onAuthorize,
        onReject: onReject,
      ),
    );
  }

  /// Membangun isi sheet: rincian penyesuaian dan tombol otorisasi/tolak bila [canAuthorize].
  @override
  Widget build(BuildContext context) {
    return AppBottomSheetWrapper(
      maxHeightFactor: 0.85,
      title: adj.kode,
      subtitle: 'Sesi Opname: ${adj.kodeOpname}',
      trailing: StatusBadge(status: adj.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Alasan: ${adj.alasan}',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textSecondary),
          ),
          const Divider(color: AppColors.border, height: 20),
          Text(
            'Daftar Batch yang Mengalami Selisih:',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: adj.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (c, i) {
                final it = adj.items[i];
                final isKurang = it.isKurang;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isKurang ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isKurang ? LucideIcons.trendingDown : LucideIcons.trendingUp,
                          size: 16,
                          color: isKurang ? AppColors.danger : AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.namaBarang,
                              style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Batch: ${it.nomorBatch} • Rak: ${it.lokasiRak}',
                              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppColors.textSecondary, fontFamily: 'JetBrains Mono'),
                            ),
                          ],
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${isKurang ? '-' : '+'}${it.jumlahPenyesuaian} ${it.satuan}',
                            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isKurang ? AppColors.danger : AppColors.success,
                            ),
                          ),
                          Text(
                            AppFormatters.rupiah(it.subtotalNilai),
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (adj.isMenunggu) ...[
            const SizedBox(height: 16),
            if (canAuthorize)
              LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth < 400 * MediaQuery.textScalerOf(context).scale(1)
                    ? constraints.maxWidth : (constraints.maxWidth - 10) / 2;
                return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: width,
                    child: CustomButton(
                      text: 'Tolak',
                      height: 48,
                      isOutlined: true,
                      backgroundColor: AppColors.danger,
                      textColor: AppColors.danger,
                      icon: const Icon(LucideIcons.x, size: 16, color: AppColors.danger),
                      onPressed: () {
                        Navigator.pop(context);
                        onReject?.call();
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: CustomButton(
                      text: 'Sahkan Saldo',
                      height: 48,
                      icon: const Icon(LucideIcons.checkCheck, size: 18, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        onAuthorize?.call();
                      },
                    ),
                  ),
                ],
                );
              })
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Menunggu peninjauan dan pengesahan resmi oleh Kepala Gudang.',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
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
