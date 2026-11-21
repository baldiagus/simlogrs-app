import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/pengalihan_model.dart';

/// Kartu ringkasan satu pengalihan pada daftar tab Aktif/Otorisasi/Riwayat.
class PengalihanCardItem extends StatelessWidget {
  final PengalihanItemModel item;
  final String tab;
  final VoidCallback onCancelTap;
  final VoidCallback onRejectTap;
  final VoidCallback onApproveTap;
  final VoidCallback onReceiveTap;

  /// Membuat kartu pengalihan dengan callback batal, tolak, setujui, dan terima.
  const PengalihanCardItem({
    super.key,
    required this.item,
    required this.tab,
    required this.onCancelTap,
    required this.onRejectTap,
    required this.onApproveTap,
    required this.onReceiveTap,
  });

  /// Membangun kartu pengalihan; tombol aksi muncul sesuai tab dan hak akses item.
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
          _buildHeader(context),
          const SizedBox(height: 8),
          Text(
            item.namaItem,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          _buildJumlahRow(context),
          const SizedBox(height: 8),
          _buildRuteBox(context),
          const SizedBox(height: 4),
          Text(
            'Tgl: ${item.tanggalPengalihan} • ${item.alasan ?? '-'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (hasActions) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            _buildActions(
              context,
              showCancelAction: showCancelAction,
              showApproveActions: showApproveActions,
              showReceiveAction: showReceiveAction,
            ),
          ],
        ],
      ),
    );
  }

  /// Membangun header kartu: nomor/jenis pengalihan dan badge status.
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  item.kode,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primaryPurple, fontFamily: 'JetBrains Mono'),
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
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: item.tipe == 'ASET'
                        ? AppColors.tintOrange
                        : AppColors.tintBlue),
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

  /// Membangun baris jumlah barang/aset yang dialihkan.
  Widget _buildJumlahRow(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.package,
            size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '${item.jumlah} unit',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        if (item.items.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text('•',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.items.length <= 3
                  ? item.items.map((d) => d.kodeAset).join(', ')
                  : '${item.items.take(3).map((d) => d.kodeAset).join(', ')} +${item.items.length - 3} lainnya',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primaryPurple, fontFamily: 'JetBrains Mono'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  /// Membangun kotak rute asal dan tujuan pengalihan.
  Widget _buildRuteBox(BuildContext context) {
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
              style: Theme.of(context).textTheme.labelMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun baris tombol aksi (batal/tolak/setujui/terima) sesuai flag yang aktif.
  Widget _buildActions(BuildContext context, {
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
            child: Text('Batalkan',
                style: Theme.of(context).textTheme.labelMedium),
          ),
        if (showApproveActions) ...[
          OutlinedButton(
            onPressed: onRejectTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text('Tolak',
                style: Theme.of(context).textTheme.labelMedium),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onApproveTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text('Setujui',
                style: Theme.of(context).textTheme.labelMedium),
          ),
        ],
        if (showReceiveAction)
          ElevatedButton.icon(
            onPressed: onReceiveTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(LucideIcons.checkCheck, size: 14),
            label: Text('Konfirmasi BAST',
                style: Theme.of(context).textTheme.labelMedium),
          ),
      ],
    );
  }
}
