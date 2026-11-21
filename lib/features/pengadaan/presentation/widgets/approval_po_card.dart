import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
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

  Future<void> _openDetail(BuildContext context) async {
    final send = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (sheetContext) => _PoDetailSheet(
        po: po,
        canSend: po.isDiterbitkan && canManagePo && !isReadOnly &&
            onUpdateKirim != null,
        isReadOnly: isReadOnly,
      ),
    );
    // Close the snapshot before the existing confirmation/action workflow.
    // Reopening detail then uses the refreshed list rather than a stale PO.
    if (send == true && context.mounted) onUpdateKirim?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.softCard,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(po.kode, style: theme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'JetBrains Mono',
                    )),
                    StatusBadge(status: po.status),
                    if (po.isDiterbitkan && canManagePo && !isReadOnly)
                      Text('Perlu Tindakan', style: theme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPurple,
                      )), 
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  po.namaPemasok,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleMedium?.copyWith(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  po.prKode != null
                      ? 'PR: ${po.prKode} · ${po.prUnit ?? "Unit tidak tersedia"}'
                      : 'Tanpa PR',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(AppFormatters.rupiah(po.totalBiaya),
                  style: theme.titleMedium?.copyWith(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppColors.tintBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Estimasi: ${po.estimasiTanggalKirim}',
                      style: theme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    Text('${po.totalItem} item', style: theme.bodySmall),
                    TextButton.icon(
                      onPressed: () => _openDetail(context),
                      icon: const Icon(LucideIcons.chevronRight, size: 16),
                      label: const Text('Detail'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PoDetailSheet extends StatelessWidget {
  const _PoDetailSheet({
    required this.po,
    required this.canSend,
    required this.isReadOnly,
  });

  final PesananPembelianModel po;
  final bool canSend;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return AppBottomSheetWrapper(
      title: po.kode,
      subtitle: 'Detail Pesanan Pembelian',
      fixedHeader: true,
      maxHeightFactor: 0.92,
      trailing: IconButton(
        tooltip: 'Tutup detail PO',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(LucideIcons.x),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerLeft,
            child: StatusBadge(status: po.status)),
          const SizedBox(height: 16),
          Text(po.namaPemasok, style: theme.titleMedium?.copyWith(
            fontSize: 16, fontWeight: FontWeight.w700)),
          _PoDetailField('Kode pemasok', po.kodePemasok),
          _PoDetailField('Referensi PR', po.prKode ?? 'Tanpa PR'),
          _PoDetailField('Unit', po.prUnit),
          const Divider(height: 32),
          Text('Ringkasan', style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          _PoDetailField('Total nilai PO', AppFormatters.rupiah(po.totalBiaya)),
          _PoDetailField('Tanggal PO', po.tanggalPo),
          _PoDetailField('Estimasi tanggal kirim', po.estimasiTanggalKirim),
          _PoDetailField('Syarat pembayaran', po.syaratPembayaran),
          _PoDetailField('Catatan', po.catatan),
          _PoDetailField('Dibuat oleh', po.pembuat),
          const Divider(height: 32),
          Text('Rincian barang (${po.totalItem} item)',
            style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (po.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Rincian barang tidak tersedia.'),
            ),
          for (final item in po.items) ...[
            const SizedBox(height: 16),
            Text(item.namaBarang, style: theme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700)),
            _PoDetailField('Dipesan', '${item.jumlahDipesan} ${item.satuan}'),
            _PoDetailField('Diterima', '${item.jumlahDiterima} ${item.satuan}'),
            _PoDetailField('Harga satuan', AppFormatters.rupiah(item.hargaSatuan)),
            _PoDetailField('Subtotal', AppFormatters.rupiah(item.subtotal)),
            const Divider(height: 24),
          ],
          if (canSend) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(LucideIcons.truck, size: 18),
              label: const Text('Tandai Dikirim Vendor'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: AppColors.tintBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ] else if (isReadOnly) ...[
            const SizedBox(height: 16),
            Text('Mode Pengawasan Eksekutif (Hanya Lihat)',
              style: theme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _PoDetailField extends StatelessWidget {
  const _PoDetailField(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(text == null || text.isEmpty || text == '-'
              ? 'Tidak tersedia' : text),
        ],
      ),
    );
  }
}
