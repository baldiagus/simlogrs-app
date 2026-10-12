import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/pengalihan_model.dart';

class PengalihanCardItem extends StatelessWidget {
  final PengalihanItemModel item;
  final String tab;
  final VoidCallback onCancelTap;
  final VoidCallback onRejectTap;
  final VoidCallback onApproveTap;
  final VoidCallback onReceiveTap;

  const PengalihanCardItem({
    super.key,
    required this.item,
    required this.tab,
    required this.onCancelTap,
    required this.onRejectTap,
    required this.onApproveTap,
    required this.onReceiveTap,
  });

  @override
  Widget build(BuildContext context) {
    final showApproveActions = tab == 'otorisasi' && item.canApprove;
    final showCancelAction = tab == 'aktif' && item.canCancel;
    final showReceiveAction = tab == 'aktif' && item.canReceive;
    final hasActions =
        showApproveActions || showCancelAction || showReceiveAction;

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
          _buildHeader(),
          const SizedBox(height: 8),
          Text(
            item.namaItem,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          _buildJumlahRow(),
          const SizedBox(height: 8),
          _buildRuteBox(),
          const SizedBox(height: 4),
          Text(
            'Tgl: ${item.tanggalPengalihan} • ${item.alasan ?? '-'}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          if (hasActions) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            _buildActions(
              showCancelAction: showCancelAction,
              showApproveActions: showApproveActions,
              showReceiveAction: showReceiveAction,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  item.kode,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryPurple),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: item.tipe == 'ASET'
                      ? AppColors.tintOrangeBg
                      : AppColors.tintBlueBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.tipe,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: item.tipe == 'ASET'
                        ? AppColors.tintOrange
                        : AppColors.tintBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        StatusBadge(status: item.status),
      ],
    );
  }

  Widget _buildJumlahRow() {
    return Row(
      children: [
        const Icon(LucideIcons.package,
            size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '${item.jumlah} unit',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        if (item.items.isNotEmpty) ...[
          const SizedBox(width: 6),
          const Text('•',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.items.length <= 3
                  ? item.items.map((d) => d.kodeAset).join(', ')
                  : '${item.items.take(3).map((d) => d.kodeAset).join(', ')} +${item.items.length - 3} lainnya',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPurple),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRuteBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.arrowRightLeft,
              size: 14, color: AppColors.primaryPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${item.asalNama} ➔ ${item.tujuanNama}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions({
    required bool showCancelAction,
    required bool showApproveActions,
    required bool showReceiveAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showCancelAction)
          TextButton(
            onPressed: onCancelTap,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Batalkan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        if (showApproveActions) ...[
          OutlinedButton(
            onPressed: onRejectTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Tolak',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onApproveTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Setujui',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
        if (showReceiveAction)
          ElevatedButton.icon(
            onPressed: onReceiveTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(LucideIcons.checkCheck, size: 14),
            label: const Text('Konfirmasi BAST',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}
