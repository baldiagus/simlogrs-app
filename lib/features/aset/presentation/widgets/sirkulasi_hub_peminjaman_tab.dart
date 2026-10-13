import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/peminjaman_aset_model.dart';
import '../providers/peminjaman_provider.dart';
import 'peminjaman_card_item.dart';
import 'sirkulasi_hub_common_widgets.dart';

/// Tab 1 hub sirkulasi: daftar Peminjaman Saya / Peminjaman Gudang.
class SirkulasiHubPeminjamanTab extends ConsumerWidget {
  /// Membuat tab peminjaman dengan data, callback ajukan, dan callback perpanjang.
  const SirkulasiHubPeminjamanTab({
    super.key,
    required this.peminjamanAsync,
    required this.onAjukan,
    required this.onExtend,
  });

  final AsyncValue<List<PeminjamanAsetModel>> peminjamanAsync;
  final VoidCallback onAjukan;
  final void Function(BuildContext context, PeminjamanAsetModel item) onExtend;

  /// Membatalkan peminjaman via provider aksi lalu menampilkan toast hasilnya.
  Future<void> _batalkan(
      BuildContext context, WidgetRef ref, PeminjamanAsetModel item) async {
    final notifier = ref.read(peminjamanActionProvider.notifier);
    final ok = await notifier.batalkanPeminjaman(item.id);
    if (!context.mounted) return;
    final state = ref.read(peminjamanActionProvider);
    if (ok) {
      AppToast.success(context, state.successMessage ?? 'Dibatalkan');
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal');
    }
  }

  /// Membangun daftar peminjaman dari [peminjamanAsync] (loading/error/kosong/data).
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    return peminjamanAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return SirkulasiHubEmptyRefreshView(
            onRefresh: () async => ref.invalidate(daftarPeminjamanSayaProvider),
            heightFactor: 0.65,
            child: EmptyStateView(
              icon: LucideIcons.armchair,
              title: 'Belum Ada Peminjaman',
              message: (user?.isKepalaGudang == true ||
                      user?.isAdminLogistik == true ||
                      user?.gudang != null)
                  ? 'Belum ada unit fasilitas gudang yang sedang atau pernah dipinjam oleh ruangan lain.'
                  : 'Unit Anda belum pernah meminjam sarana dari ruangan lain atau gudang.',
              action: (user?.unit != null)
                  ? ElevatedButton.icon(
                      onPressed: onAjukan,
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Ajukan Peminjaman'),
                    )
                  : null,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(daftarPeminjamanSayaProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return PeminjamanCardItem(
                item: item,
                onExtendTap:
                    item.isDipinjam ? () => onExtend(context, item) : null,
                onReturnTap: null,
                onCancelTap: item.isDiajukan
                    ? () => _batalkan(context, ref, item)
                    : null,
              );
            },
          ),
        );
      },
      loading: () => const AppLoadingView(),
      error: (err, _) => AppErrorView(
          error: err,
          onRetry: () => ref.invalidate(daftarPeminjamanSayaProvider)),
    );
  }
}
