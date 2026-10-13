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
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(color: AppColors.border, height: 20),
          const Text(
            'Daftar Batch yang Mengalami Selisih:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
                  child: Row(
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.namaBarang,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Batch: ${it.nomorBatch} • Rak: ${it.lokasiRak}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isKurang ? '-' : '+'}${it.jumlahPenyesuaian} ${it.satuan}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isKurang ? AppColors.danger : AppColors.success,
                            ),
                          ),
                          Text(
                            AppFormatters.rupiah(it.subtotalNilai),
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
              Row(
                children: [
                  Expanded(
                    flex: 1,
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
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
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
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Menunggu peninjauan dan pengesahan resmi oleh Kepala Gudang.',
                        style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
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
