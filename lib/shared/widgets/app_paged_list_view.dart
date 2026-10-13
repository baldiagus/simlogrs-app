import 'package:flutter/material.dart';
import 'package:simlog_mobile/core/models/pagination_meta.dart';
import '../../core/theme/app_colors.dart';

/// Widget daftar berhalaman generik dengan dukungan infinite scroll dan pull-to-refresh.
class AppPagedListView<T> extends StatelessWidget {
  /// Daftar data yang akan ditampilkan dalam list.
  final List<T> items;

  /// Pembangun elemen widget untuk setiap item data.
  final Widget Function(BuildContext context, int index, T item) itemBuilder;

  /// Aksi yang dipanggil ketika scroll mendekati batas bawah untuk memuat data lanjutan.
  final VoidCallback onLoadMore;

  /// Penanda status apakah pemuatan halaman berikutnya sedang berjalan.
  final bool isLoadingMore;

  /// Penanda apakah masih terdapat data halaman lanjutan di server.
  final bool hasMore;

  /// Callback opsional untuk aksi menyegarkan data dengan menarik layar ke bawah.
  final Future<void> Function()? onRefresh;

  /// Pembangun pemisah kustom antar item data.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Jarak padding di sekeliling daftar list.
  final EdgeInsetsGeometry padding;

  /// Aturan fisika perilaku scroll.
  final ScrollPhysics physics;

  /// Pengontrol scroll opsional bila dikelola dari luar.
  final ScrollController? controller;

  /// Tampilan pengganti saat daftar item kosong.
  final Widget? emptyWidget;

  /// Ambang batas piksel dari dasar daftar untuk memicu pemuatan lanjutan (default 200px).
  final double scrollThreshold;

  /// Membuat instance [AppPagedListView].
  const AppPagedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onRefresh,
    this.separatorBuilder,
    this.padding = const EdgeInsets.all(16),
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.controller,
    this.emptyWidget,
    this.scrollThreshold = 200.0,
  });

  /// Membuat instance [AppPagedListView] langsung dari [PagedListState].
  factory AppPagedListView.fromState({
    Key? key,
    required PagedListState<T> state,
    required Widget Function(BuildContext context, int index, T item) itemBuilder,
    required VoidCallback onLoadMore,
    Future<void> Function()? onRefresh,
    Widget Function(BuildContext context, int index)? separatorBuilder,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    ScrollPhysics physics = const AlwaysScrollableScrollPhysics(),
    ScrollController? controller,
    Widget? emptyWidget,
    double scrollThreshold = 200.0,
  }) {
    return AppPagedListView<T>(
      key: key,
      items: state.items,
      itemBuilder: itemBuilder,
      onLoadMore: onLoadMore,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMore,
      onRefresh: onRefresh,
      separatorBuilder: separatorBuilder,
      padding: padding,
      physics: physics,
      controller: controller,
      emptyWidget: emptyWidget,
      scrollThreshold: scrollThreshold,
    );
  }

  /// Membangun footer daftar untuk indikator pemuatan lanjutan atau pesan akhir data.
  Widget? _buildFooter(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
          ),
        ),
      );
    }

    if (!hasMore && items.length >= 15) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Semua data telah ditampilkan',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return null;
  }

  /// Memproses notifikasi pembaruan scroll untuk memicu pemuatan halaman lanjutan.
  bool _onScrollNotification(ScrollUpdateNotification notification) {
    final metrics = notification.metrics;
    if (metrics.maxScrollExtent - metrics.pixels <= scrollThreshold) {
      if (!isLoadingMore && hasMore) {
        onLoadMore();
      }
    }
    return false;
  }

  /// Membangun pohon widget daftar berhalaman.
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && emptyWidget != null) {
      if (onRefresh != null) {
        return RefreshIndicator(
          color: AppColors.primaryPurple,
          onRefresh: onRefresh!,
          child: SingleChildScrollView(
            physics: physics,
            child: emptyWidget!,
          ),
        );
      }
      return emptyWidget!;
    }

    final footer = _buildFooter(context);
    final hasFooter = footer != null;
    final totalCount = items.length + (hasFooter ? 1 : 0);

    Widget content = NotificationListener<ScrollUpdateNotification>(
      onNotification: _onScrollNotification,
      child: ListView.separated(
        controller: controller,
        physics: physics,
        padding: padding,
        itemCount: totalCount,
        separatorBuilder: (context, index) {
          if (separatorBuilder != null) {
            return separatorBuilder!(context, index);
          }
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, index) {
          if (hasFooter && index == items.length) {
            return footer;
          }
          return itemBuilder(context, index, items[index]);
        },
      ),
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        color: AppColors.primaryPurple,
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return content;
  }
}
