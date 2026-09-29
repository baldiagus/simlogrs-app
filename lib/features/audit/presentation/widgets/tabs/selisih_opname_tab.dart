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

class SelisihOpnameTab extends ConsumerWidget {
  const SelisihOpnameTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            padding: const EdgeInsets.all(16),
            children: [
              if (sesiList.isNotEmpty) ...[
                const Text(
                  'Sesi Opname dengan Selisih Kuantitas',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                ...sesiList.map((s) => _buildSesiSelisihCard(s)),
                const SizedBox(height: 20),
              ],
              if (penyesuaianList.isNotEmpty) ...[
                const Text(
                  'Register Penyesuaian Stok (Adjustments)',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                ...penyesuaianList.map((p) => _buildPenyesuaianCard(p)),
              ],
            ],
          ),
        );
      },
      loading: () => const AppLoadingView(),
      error: (err, _) => AppErrorView(
        title: 'Gagal Memuat Selisih Opname',
        error: err,
        onRetry: () => ref.refresh(selisihOpnameProvider),
      ),
    );
  }

  Widget _buildSesiSelisihCard(SesiOpnameSelisihModel sesi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sesi.kode,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${sesi.totalBatchSelisih} Batch Selisih',
                  style: const TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lokasi: ${sesi.gudang} • Petugas: ${sesi.petugas}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...sesi.details.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.namaBarang,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          Text('Batch: ${d.nomorBatch}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Sistem: ${d.jumlahSistem} -> Fisik: ${d.jumlahFisik}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Selisih: ${d.selisih > 0 ? "+" : ""}${d.selisih} ${d.satuan}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: d.selisih < 0 ? AppColors.danger : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPenyesuaianCard(PenyesuaianStokAuditModel p) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  p.kode,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isMenunggu ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.status,
                  style: TextStyle(
                    color: isMenunggu ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Gudang: ${p.gudang} • Diajukan: ${p.pengaju}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          if (p.alasan != null && p.alasan!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('Alasan: ${p.alasan}',
                style: const TextStyle(
                    fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${p.totalItem} Komoditas Disesuaikan',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('Penyetuju: ${p.penyetuju}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
