import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../data/models/peminjaman_aset_model.dart';
import '../providers/peminjaman_provider.dart';
import 'sirkulasi_hub_common_widgets.dart';
import 'sirkulasi_hub_otorisasi_card.dart';

/// Tab 2 hub sirkulasi: antrean otorisasi peminjaman masuk (Karu & Kagud).
class SirkulasiHubOtorisasiTab extends ConsumerWidget {
  const SirkulasiHubOtorisasiTab({
    super.key,
    required this.approvalAsync,
    required this.onOtorisasi,
  });

  final AsyncValue<List<ApprovalPeminjamanModel>> approvalAsync;
  final void Function(
          BuildContext context, ApprovalPeminjamanModel item, String aksi)
      onOtorisasi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return approvalAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return SirkulasiHubEmptyRefreshView(
            onRefresh: () async =>
                ref.invalidate(daftarApprovalPeminjamanProvider),
            heightFactor: 0.65,
            child: const EmptyStateView(
              icon: LucideIcons.shieldCheck,
              title: 'Tidak Ada Antrean Otorisasi',
              message:
                  'Tidak ada permohonan peminjaman aset masuk yang memerlukan persetujuan saat ini.',
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(daftarApprovalPeminjamanProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return SirkulasiHubOtorisasiCard(
                item: item,
                onAksi: (aksi) => onOtorisasi(context, item, aksi),
              );
            },
          ),
        );
      },
      loading: () => const AppLoadingView(),
      error: (err, _) => AppErrorView(
          error: err,
          onRetry: () => ref.invalidate(daftarApprovalPeminjamanProvider)),
    );
  }
}
