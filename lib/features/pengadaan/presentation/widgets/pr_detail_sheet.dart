import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/pr_model.dart';

class PrDetailSheet extends StatelessWidget {
  final PrHeaderModel pr;
  final bool canApproveKaru;
  final bool canManagePo;
  final VoidCallback onSetujui;
  final VoidCallback onTolak;
  final VoidCallback onTeruskan;
  final VoidCallback onTerbitkanPo;

  const PrDetailSheet({
    super.key,
    required this.pr,
    required this.canApproveKaru,
    required this.canManagePo,
    required this.onSetujui,
    required this.onTolak,
    required this.onTeruskan,
    required this.onTerbitkanPo,
  });

  static Future<void> show(
    BuildContext context, {
    required PrHeaderModel pr,
    required bool canApproveKaru,
    required bool canManagePo,
    required VoidCallback onSetujui,
    required VoidCallback onTolak,
    required VoidCallback onTeruskan,
    required VoidCallback onTerbitkanPo,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PrDetailSheet(
        pr: pr,
        canApproveKaru: canApproveKaru,
        canManagePo: canManagePo,
        onSetujui: onSetujui,
        onTolak: onTolak,
        onTeruskan: onTeruskan,
        onTerbitkanPo: onTerbitkanPo,
      ),
    );
  }

  bool get hasActionAvailable {
    if (pr.status == 'DIAJUKAN' && canApproveKaru) return true;
    if (pr.status == 'DISETUJUI' && canApproveKaru) return true;
    if (pr.status == 'DITERUSKAN_KE_PENGADAAN' && canManagePo) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetWrapper(
      maxHeightFactor: 0.85,
      title: pr.kode,
      subtitle: '${pr.unit} • Oleh ${pr.pengaju} (${AppFormatters.tanggalString(pr.tanggalPermintaan)})',
      trailing: StatusBadge(status: pr.status),
      child: Column(
        children: [
          if (pr.nomorPo != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.tintBlueBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tintBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.shoppingBag, size: 18, color: AppColors.tintBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Realisasi Pesanan Pembelian (PO)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tintBlue,
                          ),
                        ),
                        Text(
                          '${pr.nomorPo!}${pr.statusPo != null ? ' • ${pr.statusPo!.replaceAll('_', ' ')}' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: pr.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (ctx, i) {
                final item = pr.items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.namaBarang,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.kodeBarang != null)
                              Text(
                                item.kodeBarang!,
                                style:
                                    const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.jumlah} ${item.satuan}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (hasActionAvailable) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildActionRow(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    if (pr.status == 'DIAJUKAN' && canApproveKaru) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Tolak',
              height: 40,
              isOutlined: true,
              backgroundColor: AppColors.danger,
              textColor: AppColors.danger,
              icon: const Icon(LucideIcons.x, size: 16, color: AppColors.danger),
              onPressed: () {
                Navigator.pop(context);
                onTolak();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomButton(
              text: 'Setujui PR',
              height: 40,
              backgroundColor: AppColors.success,
              icon: const Icon(LucideIcons.check, size: 16, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                onSetujui();
              },
            ),
          ),
        ],
      );
    }

    if (pr.status == 'DISETUJUI' && canApproveKaru) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Tolak',
              height: 40,
              isOutlined: true,
              backgroundColor: AppColors.danger,
              textColor: AppColors.danger,
              icon: const Icon(LucideIcons.x, size: 16, color: AppColors.danger),
              onPressed: () {
                Navigator.pop(context);
                onTolak();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomButton(
              text: 'Teruskan ke Pengadaan',
              height: 40,
              backgroundColor: AppColors.primaryPurple,
              icon: const Icon(LucideIcons.send, size: 16, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                onTeruskan();
              },
            ),
          ),
        ],
      );
    }

    if (pr.status == 'DITERUSKAN_KE_PENGADAAN' && canManagePo) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Tolak Belanja',
              height: 40,
              isOutlined: true,
              backgroundColor: AppColors.danger,
              textColor: AppColors.danger,
              icon: const Icon(LucideIcons.x, size: 16, color: AppColors.danger),
              onPressed: () {
                Navigator.pop(context);
                onTolak();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomButton(
              text: 'Terbitkan PO',
              height: 40,
              backgroundColor: AppColors.primaryPurple,
              icon: const Icon(LucideIcons.fileSpreadsheet, size: 16, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                onTerbitkanPo();
              },
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
