import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/pr_model.dart';

class RiwayatPrCardItem extends StatelessWidget {
  final PrHeaderModel pr;
  final bool canApproveKaru;
  final bool canManagePo;
  final VoidCallback onDetailTap;
  final VoidCallback onSetujuiTap;
  final VoidCallback onTolakTap;
  final VoidCallback onTeruskanTap;
  final VoidCallback onTerbitkanPoTap;

  const RiwayatPrCardItem({
    super.key,
    required this.pr,
    required this.canApproveKaru,
    required this.canManagePo,
    required this.onDetailTap,
    required this.onSetujuiTap,
    required this.onTolakTap,
    required this.onTeruskanTap,
    required this.onTerbitkanPoTap,
  });

  bool get hasActionAvailable {
    if (pr.status == PrStatus.diajukan && canApproveKaru) return true;
    if ((pr.status == PrStatus.diteruskanKePengadaan || pr.status == PrStatus.disetujui) && canManagePo) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: pr.isCito ? AppColors.danger.withValues(alpha: 0.3) : AppColors.border,
        ),
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
          InkWell(
            onTap: onDetailTap,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(18),
              bottom: Radius.circular(hasActionAvailable ? 0 : 18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.tintVioletBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pr.kode,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                          ),
                          if (pr.isCito) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CITO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      StatusBadge(status: pr.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pr.unit,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Diajukan: ${AppFormatters.tanggalString(pr.tanggalPermintaan)} • Oleh ${pr.pengaju}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          '${pr.jumlahItem} Item Barang',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (pr.nomorPo != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.tintBlueBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.tintBlue.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.shoppingCart, size: 10, color: AppColors.tintBlue),
                                const SizedBox(width: 3),
                                Text(
                                  pr.nomorPo!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.tintBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Detail',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 14,
                              color: AppColors.primaryPurple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasActionAvailable) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: _buildActionRow(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    if (pr.status == PrStatus.diajukan && canApproveKaru) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Tolak',
              height: 36,
              isOutlined: true,
              backgroundColor: AppColors.danger,
              textColor: AppColors.danger,
              icon: const Icon(LucideIcons.x, size: 14, color: AppColors.danger),
              onPressed: onTolakTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomButton(
              text: 'Setujui',
              height: 36,
              backgroundColor: AppColors.success,
              icon: const Icon(LucideIcons.check, size: 14, color: Colors.white),
              onPressed: onSetujuiTap,
            ),
          ),
        ],
      );
    }

    if ((pr.status == PrStatus.diteruskanKePengadaan || pr.status == PrStatus.disetujui) && canManagePo) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Tolak Belanja',
              height: 36,
              isOutlined: true,
              backgroundColor: AppColors.danger,
              textColor: AppColors.danger,
              icon: const Icon(LucideIcons.x, size: 14, color: AppColors.danger),
              onPressed: onTolakTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomButton(
              text: 'Terbitkan PO',
              height: 36,
              backgroundColor: AppColors.primaryPurple,
              icon: const Icon(LucideIcons.fileSpreadsheet, size: 14, color: Colors.white),
              onPressed: onTerbitkanPoTap,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
