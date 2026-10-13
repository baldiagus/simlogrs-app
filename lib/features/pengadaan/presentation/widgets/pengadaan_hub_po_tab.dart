import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../approval/presentation/widgets/approval_po_card.dart';
import '../../data/models/po_model.dart';
import '../providers/pengadaan_provider.dart';

/// Tab "Pesanan (PO)" pada Hub Pengadaan.
class PengadaanHubPoTab extends ConsumerWidget {
  final AsyncValue<List<PesananPembelianModel>> poListAsync;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final bool canManagePo;
  final ValueChanged<PesananPembelianModel> onUpdateKirim;

  const PengadaanHubPoTab({
    super.key,
    required this.poListAsync,
    required this.query,
    required this.onQueryChanged,
    required this.canManagePo,
    required this.onUpdateKirim,
  });

  /// Membangun tab PO: kolom pencarian dan daftar pesanan pembelian,
  /// dengan dukungan tarik-untuk-segarkan.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surface,
          child: AppSearchBar(
            hint: 'Cari kode PO, rekanan vendor, atau kode PR...',
            onChanged: onQueryChanged,
            onClear: () => onQueryChanged(''),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryPurple,
            onRefresh: () async => ref.invalidate(poListProvider),
            child: poListAsync.when(
              data: _buildList,
              loading: () => const AppLoadingView(),
              error: (err, _) => AppErrorView(
                title: 'Gagal Memuat Daftar PO',
                error: err,
                onRetry: () => ref.invalidate(poListProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Menyaring PO berdasarkan kata kunci pencarian lalu membangun daftar kartunya,
  /// atau menampilkan tampilan kosong bila tidak ada hasil.
  Widget _buildList(List<PesananPembelianModel> list) {
    var filtered = list;
    if (query.isNotEmpty) {
      filtered = filtered.where((po) {
        final matchNomor = po.kode.toLowerCase().contains(query);
        final matchVendor = po.namaPemasok.toLowerCase().contains(query);
        final matchPr = (po.prKode ?? '').toLowerCase().contains(query);
        return matchNomor || matchVendor || matchPr;
      }).toList();
    }

    if (filtered.isEmpty) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: EmptyStateView(
            title: 'Tidak Ada Dokumen PO',
            message:
                'Belum ada Purchase Order yang aktif atau sesuai dengan kriteria pencarian.',
            icon: LucideIcons.shoppingBag,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      // Membangun kartu PO untuk tiap item hasil filter.
      itemBuilder: (ctx, idx) {
        final po = filtered[idx];
        return ApprovalPoCard(
          po: po,
          canManagePo: canManagePo,
          isReadOnly: !canManagePo,
          onUpdateKirim: () => onUpdateKirim(po),
        );
      },
    );
  }
}
