import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simlog_mobile/core/models/pagination_meta.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/core/theme/app_shadows.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';
import 'package:simlog_mobile/shared/widgets/app_error_view.dart';
import 'package:simlog_mobile/shared/widgets/app_loading_view.dart';
import 'package:simlog_mobile/shared/widgets/empty_state_view.dart';
import '../../utils/audit_presentation.dart';

/// Tab daftar jejak audit (siapa mengubah apa); [onOpenDetail] dipanggil dengan ID log yang diketuk.
class AuditTrailTab extends ConsumerStatefulWidget {
  final ValueChanged<int> onOpenDetail;

  const AuditTrailTab({super.key, required this.onOpenDetail});

  /// Membuat state tab jejak audit.
  @override
  ConsumerState<AuditTrailTab> createState() => _AuditTrailTabState();
}

/// State tab jejak audit: menyimpan filter aksi dan teks pencarian serta mengontrol infinite scroll.
class _AuditTrailTabState extends ConsumerState<AuditTrailTab> {
  String? _trailAksi;
  final TextEditingController _trailSearchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Menginisialisasi listener scroll.
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  /// Memantau posisi scroll untuk memicu loadMore saat mendekati dasar list.
  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      ref.read(auditTrailProvider.notifier).loadMore();
    }
  }

  /// Membuang controller pencarian dan scroll agar tidak bocor memori.
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _trailSearchCtrl.dispose();
    super.dispose();
  }

  /// Menerapkan filter saat pilihan aksi atau kolom pencarian berubah.
  void _applyFilter() {
    final search = _trailSearchCtrl.text.trim();
    ref.read(auditTrailProvider.notifier).setFilter(
      aksi: _trailAksi,
      search: search.isEmpty ? null : search,
    );
  }

  /// Membangun tab jejak audit: filter aksi, kolom pencarian, daftar log berhalaman, dan footer status.
  @override
  Widget build(BuildContext context) {
    final trailState = ref.watch(auditTrailProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                TextField(
                  controller: _trailSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari referensi, pengguna, IP...',
                    prefixIcon: const Icon(LucideIcons.search, size: 16),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.canvas,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _applyFilter(),
                ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final action in <String?>[
                      null, 'TAMBAH', 'UBAH', 'HAPUS',
                      'APPROVE', 'REJECT', 'ADJUSTMENT',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(action == null
                              ? 'Semua Aksi'
                              : AuditPresentation.action(action)),
                          selected: _trailAksi == action,
                          showCheckmark: false,
                          selectedColor: AppColors.primaryPurple,
                          backgroundColor: AppColors.canvas,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(
                            color: _trailAksi == action
                                ? AppColors.primaryPurple
                                : AppColors.border,
                          ),
                          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _trailAksi == action
                                ? AppColors.surface
                                : AppColors.textSecondary,
                            fontWeight: _trailAksi == action
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          onSelected: (_) {
                            if (_trailAksi == action) return;
                            setState(() => _trailAksi = action);
                            _applyFilter();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildBody(trailState),
        ),
      ],
    );
  }

  /// Membangun konten utama daftar jejak audit berdasarkan status pemuatan.
  Widget _buildBody(PagedListState<AuditTrailItemModel> trailState) {
    if (trailState.isLoading) {
      return const AppLoadingView();
    }

    if (trailState.errorMessage != null && trailState.items.isEmpty) {
      return AppErrorView(
        title: 'Gagal Memuat Log Audit',
        error: trailState.errorMessage,
        onRetry: () => ref.read(auditTrailProvider.notifier).refresh(),
      );
    }

    if (trailState.items.isEmpty) {
      return const EmptyStateView(
        icon: LucideIcons.fileSearch,
        title: 'Tidak Ada Log Audit',
        message:
            'Tidak ditemukan rekaman log audit forensik dengan kriteria filter saat ini.',
      );
    }

    final showFooter =
        trailState.isLoadingMore || (!trailState.hasMore && trailState.items.isNotEmpty);
    final itemCount = trailState.items.length + (showFooter ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () async => ref.read(auditTrailProvider.notifier).refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 200) {
            ref.read(auditTrailProvider.notifier).loadMore();
          }
          return false;
        },
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            if (i == trailState.items.length) {
              return _buildFooter(trailState);
            }
            return _buildTrailCard(trailState.items[i]);
          },
        ),
      ),
    );
  }

  /// Membangun footer daftar untuk indikator pemuatan lanjutan atau teks akhir data.
  Widget _buildFooter(PagedListState<AuditTrailItemModel> trailState) {
    if (trailState.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!trailState.hasMore && trailState.items.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Semua data log audit telah ditampilkan',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Membangun kartu satu log audit dengan badge aksi berwarna; ketuk membuka detail forensik.
  Widget _buildTrailCard(AuditTrailItemModel item) {
    Color badgeColor;
    Color badgeBg;

    switch (item.aksi.toUpperCase()) {
      case 'TAMBAH':
        badgeColor = AppColors.success;
        badgeBg = AppColors.success.withValues(alpha: 0.08);
        break;
      case 'UBAH':
        badgeColor = AppColors.tintBlue;
        badgeBg = AppColors.tintBlueBg;
        break;
      case 'HAPUS':
      case 'REJECT':
        badgeColor = AppColors.danger;
        badgeBg = AppColors.danger.withValues(alpha: 0.08);
        break;
      case 'APPROVE':
        badgeColor = AppColors.tintViolet;
        badgeBg = AppColors.tintVioletBg;
        break;
      default:
        badgeColor = AppColors.tintOrange;
        badgeBg = AppColors.tintOrangeBg;
    }

    return InkWell(
      onTap: () => widget.onOpenDetail(item.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    AuditPresentation.action(item.aksi),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: badgeColor),
                  ),
                ),
                Text(
                  item.waktu,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${AuditPresentation.entity(item.referensiJenis)} #${item.referensiId}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.user, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${item.penggunaNama} (${AuditPresentation.role(item.peran)})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(LucideIcons.globe, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'IP: ${item.ipAddress}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                if (item.hasDataSebelum || item.hasDataSesudah)
                  Text(
                    'Lihat perubahan',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primaryPurple),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
