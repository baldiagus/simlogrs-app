import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../gudang/data/models/po_inbound_model.dart';
import '../../../gudang/presentation/providers/inbound_provider.dart';

/// Tab "Penerimaan Inbound" pada Hub Pengadaan.
class PengadaanHubInboundTab extends ConsumerWidget {
  final AsyncValue<List<PoInboundHeaderModel>> inboundAsync;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final bool canReceiveInbound;
  final ValueChanged<PoInboundHeaderModel> onTerima;

  const PengadaanHubInboundTab({
    super.key,
    required this.inboundAsync,
    required this.query,
    required this.onQueryChanged,
    required this.canReceiveInbound,
    required this.onTerima,
  });

  /// Membangun tab inbound: kolom pencarian dan daftar PO yang menunggu diterima,
  /// dengan dukungan tarik-untuk-segarkan.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surface,
          child: AppSearchBar(
            hint: 'Cari kode PO atau nama rekanan pemasok...',
            onChanged: onQueryChanged,
            onClear: () => onQueryChanged(''),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryPurple,
            onRefresh: () async => ref.invalidate(daftarPoInboundProvider),
            child: inboundAsync.when(
              data: _buildList,
              loading: () => const AppLoadingView(),
              error: (err, _) => AppErrorView(
                title: 'Gagal Memuat Antrean Inbound',
                error: err,
                onRetry: () => ref.invalidate(daftarPoInboundProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Menyaring PO inbound berdasarkan kata kunci pencarian lalu membangun daftarnya,
  /// atau menampilkan tampilan kosong bila tidak ada hasil.
  Widget _buildList(List<PoInboundHeaderModel> list) {
    var filtered = list;
    if (query.isNotEmpty) {
      filtered = filtered.where((po) {
        final matchKode = po.kodePo.toLowerCase().contains(query);
        final matchPemasok = po.pemasok.toLowerCase().contains(query);
        return matchKode || matchPemasok;
      }).toList();
    }

    if (filtered.isEmpty) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(top: 80),
          child: EmptyStateView(
            title: 'Tidak Ada Antrean Inbound',
            message:
                'Semua barang pesanan PO telah diterima atau belum ada pengiriman aktif.',
            icon: LucideIcons.packageCheck,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      // Membangun kartu PO inbound untuk tiap item hasil filter.
      itemBuilder: (ctx, idx) {
        final item = filtered[idx];
        return PengadaanHubInboundCard(
          item: item,
          canReceiveInbound: canReceiveInbound,
          onTerima: () => onTerima(item),
        );
      },
    );
  }
}

/// Kartu antrean penerimaan PO inbound.
class PengadaanHubInboundCard extends StatelessWidget {
  final PoInboundHeaderModel item;
  final bool canReceiveInbound;
  final VoidCallback onTerima;

  const PengadaanHubInboundCard({
    super.key,
    required this.item,
    required this.canReceiveInbound,
    required this.onTerima,
  });

  /// Membangun kartu ringkasan PO inbound beserta tombol terima barang
  /// yang hanya aktif bila pengguna berhak dan PO siap diterima.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                item.kodePo,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryPurple),
              ),
              StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.pemasok,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.totalItem} Item Barang • Tanggal PO: ${item.tanggalPo}',
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          if (canReceiveInbound && item.canReceive) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTerima,
                icon: const Icon(LucideIcons.packageCheck, size: 16),
                label: const Text('Periksa & Terima Barang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else if (item.canReceive && !canReceiveInbound) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.eye,
                      size: 13, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Mode Pemantauan (Penerimaan di Gudang)',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
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
