import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/peminjaman_aset_model.dart';
import '../providers/peminjaman_provider.dart';
import 'peminjaman_card_item.dart';
import 'sirkulasi_hub_common_widgets.dart';

typedef SirkulasiHubItemAction = void Function(
    BuildContext context, PeminjamanAsetModel item);

/// Tab 3 hub sirkulasi: Siap Pengembalian (Perspektif: Dipinjam vs Dipinjamkan).
///
/// State perspektif disimpan di parent agar tidak hilang saat berpindah tab.
class SirkulasiHubSiapKembaliTab extends ConsumerWidget {
  /// Membuat tab siap kembali dengan data kedua perspektif dan callback aksi.
  const SirkulasiHubSiapKembaliTab({
    super.key,
    required this.dipinjamAsync,
    required this.dipinjamkanAsync,
    required this.subPerspektif,
    required this.onSubPerspektifChanged,
    required this.onExtend,
    required this.onReturn,
  });

  final AsyncValue<List<PeminjamanAsetModel>> dipinjamAsync;
  final AsyncValue<List<PeminjamanAsetModel>> dipinjamkanAsync;

  /// 'dipinjam' (peminjam) atau 'dipinjamkan' (penyedia).
  final String subPerspektif;
  final ValueChanged<String> onSubPerspektifChanged;
  final SirkulasiHubItemAction onExtend;
  final SirkulasiHubItemAction onReturn;

  /// Membangun pill pemilih perspektif dan daftar sesuai [subPerspektif].
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: SirkulasiHubSubTabPill(
                  title: 'Aset Dipinjam',
                  count: dipinjamAsync.valueOrNull?.length ?? 0,
                  isActive: subPerspektif == 'dipinjam',
                  onTap: () => onSubPerspektifChanged('dipinjam'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SirkulasiHubSubTabPill(
                  title: 'Aset Dipinjamkan',
                  count: dipinjamkanAsync.valueOrNull?.length ?? 0,
                  isActive: subPerspektif == 'dipinjamkan',
                  onTap: () => onSubPerspektifChanged('dipinjamkan'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: subPerspektif == 'dipinjam'
              ? _buildListDipinjam(ref)
              : _buildListDipinjamkan(ref),
        ),
      ],
    );
  }

  /// Membangun daftar aset yang sedang dipinjam (perspektif peminjam) dengan aksi perpanjang.
  Widget _buildListDipinjam(WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    return dipinjamAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return SirkulasiHubEmptyRefreshView(
            onRefresh: () async =>
                ref.invalidate(daftarPeminjamanAktifDipinjamProvider),
            heightFactor: 0.55,
            child: const EmptyStateView(
              icon: LucideIcons.packageCheck,
              title: 'Tidak Ada Aset Dipinjam',
              message:
                  'Unit Anda saat ini tidak memiliki tanggungan peminjaman aset dari unit lain atau gudang.',
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(daftarPeminjamanAktifDipinjamProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return PeminjamanCardItem(
                item: item,
                isPenyediaPerspective: false,
                onExtendTap: (user?.canPerpanjangPeminjaman ?? false)
                    ? () => onExtend(context, item)
                    : null,
                onReturnTap: null,
              );
            },
          ),
        );
      },
      loading: () => const AppLoadingView(),
      error: (err, _) => AppErrorView(
          error: err,
          onRetry: () => ref.invalidate(daftarPeminjamanAktifDipinjamProvider)),
    );
  }

  /// Membangun daftar aset yang dipinjamkan (perspektif penyedia) dengan aksi pengembalian.
  Widget _buildListDipinjamkan(WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final isGudang = user?.isKepalaGudang == true ||
        user?.isAdminLogistik == true ||
        user?.gudang != null;

    return dipinjamkanAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return SirkulasiHubEmptyRefreshView(
            onRefresh: () async =>
                ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider),
            heightFactor: 0.55,
            child: EmptyStateView(
              icon: LucideIcons.armchair,
              title: 'Tidak Ada Aset Dipinjamkan',
              message: isGudang
                  ? 'Seluruh aset inventaris fasilitas gudang saat ini berada di tempat (tidak ada yang sedang dipinjam unit luar).'
                  : 'Seluruh aset inventaris unit Anda saat ini berada di tempat (tidak ada yang sedang dipinjam unit lain).',
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return PeminjamanCardItem(
                item: item,
                isPenyediaPerspective: true,
                onReturnTap: () => onReturn(context, item),
              );
            },
          ),
        );
      },
      loading: () => const AppLoadingView(),
      error: (err, _) => AppErrorView(
          error: err,
          onRetry: () =>
              ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider)),
    );
  }
}
