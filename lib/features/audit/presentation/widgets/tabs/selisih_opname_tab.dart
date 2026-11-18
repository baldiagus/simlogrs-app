import '../../../../../core/network/user_error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/core/theme/app_shadows.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';
import 'package:simlog_mobile/shared/widgets/app_error_view.dart';
import 'package:simlog_mobile/shared/widgets/app_loading_view.dart';
import 'package:simlog_mobile/shared/widgets/empty_state_view.dart';
import '../opname_detail_sheet.dart';

/// Tab pemeriksaan selisih stok fisik vs sistem dan penyesuaian stok yang menunggu persetujuan.
class SelisihOpnameTab extends ConsumerStatefulWidget {
  const SelisihOpnameTab({super.key});

  @override
  ConsumerState<SelisihOpnameTab> createState() => _SelisihOpnameTabState();
}

class _SelisihOpnameTabState extends ConsumerState<SelisihOpnameTab> {
  bool _detailOpen = false;
  final ScrollController _listController = ScrollController();

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _openDetails(SesiOpnameSelisihModel sesi) async {
    if (_detailOpen) return;
    _detailOpen = true;
    final triggerFocus = FocusManager.instance.primaryFocus;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => OpnameDetailSheet(sesi: sesi),
      );
    } finally {
      _detailOpen = false;
      if (mounted && triggerFocus != null && triggerFocus.context != null) {
        triggerFocus.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final opnameAsync = ref.watch(selisihOpnameProvider);

    return opnameAsync.when(
      data: (data) {
        final sesiList = (data['sesi_opname'] as List<SesiOpnameSelisihModel>?) ?? [];
        final penyesuaianList = (data['penyesuaian'] as List<PenyesuaianStokAuditModel>?) ?? [];

        if (sesiList.isEmpty && penyesuaianList.isEmpty) {
          return const EmptyStateView(
            icon: LucideIcons.scale,
            title: 'Stok Fisik & Sistem Klop',
            message:
                'Tidak ada catatan selisih hasil stock opname atau antrean otorisasi penyesuaian.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(selisihOpnameProvider),
          child: ListView(
            controller: _listController,
            padding: const EdgeInsets.all(16),
            children: [
              if (sesiList.isNotEmpty) ...[
                Text(
                  'Sesi Opname dengan Selisih Kuantitas',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                ...sesiList.map((s) => _buildSesiSelisihCard(context, s)),
                const SizedBox(height: 20),
              ],
              if (penyesuaianList.isNotEmpty) ...[
                Text(
                  'Register Penyesuaian Stok (Adjustments)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                ...penyesuaianList.map((p) => _buildPenyesuaianCard(context, p)),
              ],
            ],
          ),
        );
      },
      loading: () => const AppLoadingView(),
      error: (err, _) => AppErrorView(
        title: 'Gagal Memuat Selisih Opname',
        error: userErrorMessage(err, action: 'memuat selisih opname'),
        onRetry: () => ref.refresh(selisihOpnameProvider),
      ),
    );
  }

  /// Kartu ringkas membuka rincian tanpa mengubah posisi daftar utama.
  Widget _buildSesiSelisihCard(BuildContext context, SesiOpnameSelisihModel sesi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: 'Lihat rincian sesi ${sesi.kode}',
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openDetails(sesi),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(sesi.kode, style: Theme.of(context).textTheme.titleSmall),
                      Text('${sesi.totalBatchSelisih} Batch Selisih',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.danger)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Lokasi: ${sesi.gudang} • Petugas: ${sesi.petugas}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Expanded(child: Text('Lihat rincian')),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun kartu pengajuan penyesuaian stok; status MENUNGGU diberi penanda khusus.
  Widget _buildPenyesuaianCard(BuildContext context, PenyesuaianStokAuditModel p) {
    final isMenunggu = p.status == 'MENUNGGU';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
                Text(
                  p.kode,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFamily: 'JetBrains Mono'),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isMenunggu ? AppColors.warning.withValues(alpha: 0.08) : AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.status,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: isMenunggu ? AppColors.warning : AppColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Gudang: ${p.gudang} • Diajukan: ${p.pengaju}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          if (p.alasan != null && p.alasan!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('Alasan: ${p.alasan}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${p.totalItem} Komoditas Disesuaikan',
                  style: Theme.of(context).textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('Penyetuju: ${p.penyetuju}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
