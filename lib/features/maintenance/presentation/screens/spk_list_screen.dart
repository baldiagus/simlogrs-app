import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_filter_chip_bar.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../data/models/spk_model.dart';
import '../../../../core/models/pagination_meta.dart';
import '../../../../shared/widgets/app_paged_list_view.dart';
import '../providers/maintenance_provider.dart';
import 'spk_detail_screen.dart';
class SpkTabItem {
  final String label;
  final String status;
  /// Membuat SpkTabItem.
  const SpkTabItem(this.label, this.status);
}

class SpkListScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  final String? initialStatus;
  final String? customTitle;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final List<String>? allowedStatuses;

  /// Membuat SpkListScreen.
  const SpkListScreen({
    super.key,
    this.isEmbedded = false,
    this.initialStatus,
    this.customTitle,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.allowedStatuses,
  });
  /// Membuat state mutable untuk widget ini.
  @override
  ConsumerState<SpkListScreen> createState() => _SpkListScreenState();
}

class _SpkListScreenState extends ConsumerState<SpkListScreen>
    with SingleTickerProviderStateMixin {
  late final List<SpkTabItem> _tabs;
  TabController? _tabController;
  late String _selectedStatus;

  /// Inisialisasi state awal layar/sheet.
  @override
  void initState() {
    super.initState();
    final allowed = widget.allowedStatuses;
    if (allowed != null && allowed.length == 1) {
      _tabs = [
        SpkTabItem(
          allowed.first == 'DITUGASKAN' ? 'Ditugaskan' : allowed.first,
          allowed.first,
        ),
      ];
      _selectedStatus = allowed.first;
      _tabController = null;
    } else if (allowed != null &&
        allowed.contains('DITERIMA') &&
        allowed.contains('SELESAI') &&
        allowed.length == 2) {
      _tabs = const [
        SpkTabItem('Aktif Dikerjakan', 'DITERIMA'),
        SpkTabItem('Riwayat Selesai', 'SELESAI'),
      ];
      _selectedStatus = widget.initialStatus ?? 'DITERIMA';
      final initialIdx = _tabs.indexWhere((t) => t.status == _selectedStatus);
      _tabController = TabController(
        length: 2,
        vsync: this,
        initialIndex: initialIdx >= 0 ? initialIdx : 0,
      );
      _tabController!.addListener(_onTabChanged);
    } else {
      _tabs = const [
        SpkTabItem('Semua', 'SEMUA'),
        SpkTabItem('Ditugaskan', 'DITUGASKAN'),
        SpkTabItem('Diterima', 'DITERIMA'),
        SpkTabItem('Selesai', 'SELESAI'),
      ];
      _selectedStatus = widget.initialStatus ?? 'SEMUA';
      final initialIdx = _tabs.indexWhere((t) => t.status == _selectedStatus);
      _tabController = TabController(
        length: _tabs.length,
        vsync: this,
        initialIndex: initialIdx >= 0 ? initialIdx : 0,
      );
      _tabController!.addListener(_onTabChanged);
    }
  }

  /// Sinkronkan status filter SPK saat tab berganti.
  void _onTabChanged() {
    if (_tabController != null && !_tabController!.indexIsChanging) {
      setState(() {
        _selectedStatus = _tabs[_tabController!.index].status;
      });
    }
  }

  /// Bersihkan controller dan resource saat widget dilepas.
  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  /// Membangun tampilan _SpkListScreenState.
  @override
  Widget build(BuildContext context) {
    final pagedState = ref.watch(spkPagedListProvider(_selectedStatus));

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              automaticallyImplyLeading: widget.automaticallyImplyLeading,
              leading: widget.leading,
              title: Text(widget.customTitle ??
                  (_tabs.length == 1
                      ? 'Surat Perintah Kerja (SPK)'
                      : 'Lembar Kerja (SPK Aktif)')),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  tooltip: 'Segarkan',
                  onPressed: () {
                    ref.invalidate(spkListProvider(_selectedStatus));
                    ref.read(spkPagedListProvider(_selectedStatus).notifier).loadInitial();
                  },
                ),
              ],
              bottom: _tabs.length > 1 && _tabController != null
                  ? TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primaryPurple,
                      indicatorWeight: 3,
                      labelColor: AppColors.primaryPurple,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle:
                          const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      unselectedLabelStyle:
                          const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
                    )
                  : null,
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.isEmbedded && _tabs.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: AppColors.surface,
                child: AppFilterChipBar<String>(
                  selected: _selectedStatus,
                  onSelected: (val) {
                    setState(() => _selectedStatus = val);
                    final idx = _tabs.indexWhere((t) => t.status == val);
                    if (idx >= 0 && _tabController != null) _tabController!.animateTo(idx);
                  },
                  options: _tabs
                      .map((t) => AppFilterOption(label: t.label, value: t.status))
                      .toList(),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
            ],
            // Content List
            Expanded(
              child: _buildContent(context, pagedState),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun konten daftar SPK berhalaman atau tampilan status terkait.
  Widget _buildContent(BuildContext context, PagedListState<SpkHeaderModel> pagedState) {
    if (pagedState.isLoading && pagedState.items.isEmpty) {
      return const AppLoadingView();
    }

    if (pagedState.errorMessage != null && pagedState.items.isEmpty) {
      return AppErrorView(
        title: 'Gagal Memuat Tugas SPK',
        error: pagedState.errorMessage,
        onRetry: () {
          ref.invalidate(spkListProvider(_selectedStatus));
          ref.read(spkPagedListProvider(_selectedStatus).notifier).loadInitial();
        },
      );
    }

    final emptyWidget = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Builder(
          builder: (context) {
            String emptyTitle = 'Tidak Ada Data SPK';
            String emptyMsg = 'Belum ada surat perintah kerja pada status ini.';
            if (_selectedStatus == 'DITUGASKAN') {
              emptyTitle = 'Tidak Ada Tugas SPK Baru';
              emptyMsg = 'Saat ini belum ada surat perintah kerja baru yang ditugaskan kepada Anda.';
            } else if (_selectedStatus == 'DITERIMA') {
              emptyTitle = 'Tidak Ada SPK Berjalan';
              emptyMsg = 'Belum ada SPK yang sedang dikerjakan. Silakan konfirmasi tugas baru di menu Tugas SPK.';
            } else if (_selectedStatus == 'SELESAI') {
              emptyTitle = 'Belum Ada Riwayat Selesai';
              emptyMsg = 'Belum ada SPK yang diselesaikan pada daftar riwayat ini.';
            }
            return EmptyStateView(
              icon: LucideIcons.wrench,
              title: emptyTitle,
              message: emptyMsg,
            );
          },
        ),
      ),
    );

    return AppPagedListView<SpkHeaderModel>(
      items: pagedState.items,
      isLoadingMore: pagedState.isLoadingMore,
      hasMore: pagedState.hasMore,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      separatorBuilder: (_, __) => const SizedBox(height: 0),
      emptyWidget: emptyWidget,
      onLoadMore: () {
        ref.read(spkPagedListProvider(_selectedStatus).notifier).loadMore();
      },
      onRefresh: () async {
        ref.invalidate(spkListProvider(_selectedStatus));
        await ref.read(spkPagedListProvider(_selectedStatus).notifier).loadInitial();
      },
      itemBuilder: (context, index, spk) {
        return _buildSpkCard(context, spk);
      },
    );
  }


  /// Kartu ringkasan SPK; klik membuka detail SPK.
  Widget _buildSpkCard(BuildContext context, SpkHeaderModel spk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: spk.tiket.isCito
              ? AppColors.danger.withValues(alpha: 0.35)
              : AppColors.border,
          width: spk.tiket.isCito ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SpkDetailScreen(spkId: spk.id, kodeSpk: spk.kodeSpk),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tintTealBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          spk.kodeSpk,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tintTeal,
                          ),
                        ),
                      ),
                      if (spk.tiket.isCito) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'CITO',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  StatusBadge(status: spk.status),
                ],
              ),
              const SizedBox(height: 12),

              // Asset Name
              Text(
                spk.aset.nama,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Kode: ${spk.aset.kodeAset} • Lokasi: ${spk.aset.lokasi}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),

              // Problem Description Preview
              Text(
                spk.tiket.deskripsiMasalah,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer Meta
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Target: ${spk.targetSelesai ?? '-'}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          spk.status.toUpperCase() == 'SELESAI'
                              ? 'Buka Arsip SPK'
                              : (spk.status.toUpperCase() == 'DITUGASKAN'
                                  ? 'Konfirmasi & Buka SPK'
                                  : 'Catat Lembar Kerja'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryPurple),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.primaryPurple),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
