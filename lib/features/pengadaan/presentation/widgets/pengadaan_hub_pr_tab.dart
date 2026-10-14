import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_filter_chip_bar.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../data/models/pr_model.dart';
import '../providers/pengadaan_provider.dart';
import 'pr_detail_sheet.dart';
import 'riwayat_pr_card_item.dart';
import 'terbitkan_po_sheet.dart';

/// Tab "Permintaan (PR)" pada Hub Pengadaan.
class PengadaanHubPrTab extends ConsumerWidget {
  final AsyncValue<List<PrHeaderModel>> prListAsync;
  final String query;
  final String filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onFilterSelected;
  final bool isPengadaan;
  final bool canApproveKaru;
  final bool canManagePo;
  final ValueChanged<PrHeaderModel> onSetujui;
  final void Function(PrHeaderModel pr, bool isPengadaan) onTolak;
  final ValueChanged<PrHeaderModel> onTeruskan;

  const PengadaanHubPrTab({
    super.key,
    required this.prListAsync,
    required this.query,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterSelected,
    required this.isPengadaan,
    required this.canApproveKaru,
    required this.canManagePo,
    required this.onSetujui,
    required this.onTolak,
    required this.onTeruskan,
  });

  /// Membangun tab PR: pencarian, filter status, dan daftar permintaan pengadaan,
  /// dengan dukungan tarik-untuk-segarkan.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.surface,
          child: Column(
            children: [
              AppSearchBar(
                hint: 'Cari kode PR, nama pengaju, atau unit...',
                onChanged: onQueryChanged,
                onClear: () => onQueryChanged(''),
              ),
              const SizedBox(height: 8),
              AppFilterChipBar<String>(
                padding: EdgeInsets.zero,
                selected: filter,
                onSelected: onFilterSelected,
                options: const [
                  AppFilterOption(label: 'Semua Status', value: 'SEMUA'),
                  AppFilterOption(
                      label: 'Menunggu Otorisasi', value: PrStatus.diajukan),
                  AppFilterOption(
                      label: 'Siap Terbitkan PO',
                      value: PrStatus.diteruskanKePengadaan),
                  AppFilterOption(
                      label: 'Disetujui', value: PrStatus.disetujui),
                  AppFilterOption(label: 'Ditolak', value: PrStatus.ditolak),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryPurple,
            onRefresh: () async => ref.invalidate(daftarPrProvider),
            child: prListAsync.when(
              data: (list) => _buildList(context, list),
              loading: () => const AppLoadingView(),
              error: (err, _) => AppErrorView(
                title: 'Gagal Memuat Daftar PR',
                error: err,
                onRetry: () => ref.invalidate(daftarPrProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Menyaring PR berdasarkan status dan kata kunci lalu membangun daftar kartunya,
  /// atau menampilkan tampilan kosong bila tidak ada hasil.
  Widget _buildList(BuildContext context, List<PrHeaderModel> list) {
    var filtered = list;
    if (filter != 'SEMUA') {
      filtered = filtered.where((pr) => pr.status == filter).toList();
    }
    if (query.isNotEmpty) {
      filtered = filtered.where((pr) {
        final matchKode = pr.kode.toLowerCase().contains(query);
        final matchUnit = pr.unit.toLowerCase().contains(query);
        final matchPengaju = pr.pengaju.toLowerCase().contains(query);
        return matchKode || matchUnit || matchPengaju;
      }).toList();
    }

    if (filtered.isEmpty) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: EmptyStateView(
            title: 'Tidak Ada Data PR',
            message:
                'Belum ada dokumen permohonan pengadaan yang sesuai dengan filter.',
            icon: LucideIcons.fileSpreadsheet,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      // Membangun kartu PR untuk tiap item hasil filter.
      itemBuilder: (ctx, idx) {
        final pr = filtered[idx];
        return RiwayatPrCardItem(
          pr: pr,
          canApproveKaru: canApproveKaru,
          canManagePo: canManagePo,
          onDetailTap: () => PrDetailSheet.show(
            context,
            pr: pr,
            canApproveKaru: canApproveKaru,
            canManagePo: canManagePo,
            onSetujui: () => onSetujui(pr),
            onTolak: () => onTolak(pr, isPengadaan),
            onTeruskan: () => onTeruskan(pr),
            onTerbitkanPo: () =>
                TerbitkanPoSheet.show(context, pr.toApprovalItem()),
          ),
          onSetujuiTap: () => onSetujui(pr),
          // Tombol Tolak pada kartu mengikuti peran pengguna (pengadaan atau karu).
          onTolakTap: () => onTolak(pr, isPengadaan),
          onTeruskanTap: () => onTeruskan(pr),
          onTerbitkanPoTap: () =>
              TerbitkanPoSheet.show(context, pr.toApprovalItem()),
        );
      },
    );
  }
}
