import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/tiket_maintenance_provider.dart';
import '../widgets/tiket_card_item.dart';
import 'lapor_cepat_screen.dart';

class LaporRusakHubScreen extends ConsumerStatefulWidget {
  /// Membuat LaporRusakHubScreen.
  const LaporRusakHubScreen({super.key});

  /// Membuat state mutable untuk widget ini.
  @override
  ConsumerState<LaporRusakHubScreen> createState() => _LaporRusakHubScreenState();
}

class _LaporRusakHubScreenState extends ConsumerState<LaporRusakHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchKeyword = '';
  String _prioritasFilter = 'SEMUA';

  /// Inisialisasi state awal layar/sheet.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  /// Bersihkan controller dan resource saat widget dilepas.
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Susun parameter filter tiket dari state pencarian dan prioritas.
  TiketFilterParams _resolveParams() {
    return TiketFilterParams(
      status: 'SEMUA',
      prioritas: _prioritasFilter,
      cari: _searchKeyword,
    );
  }

  /// Membangun tampilan _LaporRusakHubScreenState.
  @override
  Widget build(BuildContext context) {
    final params = _resolveParams();
    final tiketListAsync = ref.watch(daftarTiketUnitProvider(params));
    final allList = tiketListAsync.valueOrNull ?? [];
    final activeCount = allList.where((t) {
      final st = t.status.toUpperCase();
      return st != 'SELESAI' && st != 'DIBATALKAN';
    }).length;
    final riwayatCount = allList.where((t) {
      final st = t.status.toUpperCase();
      return st == 'SELESAI' || st == 'DIBATALKAN';
    }).length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Layanan Lapor Kerusakan'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Segarkan Tiket',
            onPressed: () {
              ref.invalidate(daftarTiketUnitProvider);
              ref.invalidate(dashboardSummaryProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Text(
                      'Laporan Aktif',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildTabBadge(activeCount),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Text(
                      'Riwayat Selesai',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (riwayatCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildTabBadge(riwayatCount),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const LaporCepatScreen()),
          );
          if (created == true) {
            ref.invalidate(daftarTiketUnitProvider);
            ref.invalidate(dashboardSummaryProvider);
          }
        },
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('Lapor Kerusakan', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Toolbar Search & Filter Prioritas
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSearchBar(
                  hint: 'Cari kode tiket, nama alat, keluhan...',
                  onChanged: (v) => setState(() => _searchKeyword = v.trim()),
                  onClear: () => setState(() => _searchKeyword = ''),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Prioritas: ',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      _buildPrioritasPill('SEMUA', 'Semua'),
                      const SizedBox(width: 6),
                      _buildPrioritasPill('CITO', 'CITO (Darurat)', color: AppColors.danger),
                      const SizedBox(width: 6),
                      _buildPrioritasPill('TINGGI', 'Tinggi', color: AppColors.warning),
                      const SizedBox(width: 6),
                      _buildPrioritasPill('SEDANG', 'Sedang', color: AppColors.tintBlue),
                      const SizedBox(width: 6),
                      _buildPrioritasPill('RENDAH', 'Rendah'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // TabBarView: Laporan Aktif vs Riwayat
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTiketListView(isRiwayat: false),
                _buildTiketListView(isRiwayat: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pill filter prioritas yang bisa diklik untuk memfilter daftar tiket.
  Widget _buildPrioritasPill(String val, String label, {Color? color}) {
    final isSelected = _prioritasFilter == val;
    final pillColor = color ?? AppColors.primaryPurple;

    return InkWell(
      onTap: () => setState(() => _prioritasFilter = val),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? pillColor : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? pillColor : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Badge jumlah tiket pada tab; disembunyikan saat jumlah 0.
  Widget _buildTabBadge(int count) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tintVioletBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryPurple,
        ),
      ),
    );
  }

  /// Daftar tiket (aktif atau riwayat) dengan state loading, error, dan kosong.
  Widget _buildTiketListView({required bool isRiwayat}) {
    final params = _resolveParams();
    final tiketListAsync = ref.watch(daftarTiketUnitProvider(params));

    return RefreshIndicator(
      color: AppColors.primaryPurple,
      onRefresh: () async {
        ref.invalidate(daftarTiketUnitProvider);
        ref.invalidate(dashboardSummaryProvider);
      },
      child: tiketListAsync.when(
        data: (allList) {
          // Filter status sesuai tab
          final list = allList.where((t) {
            final st = t.status.toUpperCase();
            if (isRiwayat) {
              return st == 'SELESAI' || st == 'DIBATALKAN';
            } else {
              return st != 'SELESAI' && st != 'DIBATALKAN';
            }
          }).toList();

          if (list.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: EmptyStateView(
                  icon: isRiwayat ? LucideIcons.history : LucideIcons.clockAlert,
                  title: isRiwayat ? 'Belum Ada Riwayat Selesai' : 'Tidak Ada Laporan Aktif',
                  message: isRiwayat
                      ? 'Seluruh tiket kerusakan yang telah selesai diperbaiki atau dibatalkan akan diarsipkan di sini.'
                      : 'Ruangan Anda saat ini tidak memiliki laporan kerusakan fasilitas yang sedang dalam penanganan teknisi.',
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final tiket = list[index];
              return TiketCardItem(
                item: tiket,
              );
            },
          );
        },
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          title: 'Gagal Memuat Daftar Tiket',
          error: err,
          onRetry: () => ref.invalidate(daftarTiketUnitProvider),
        ),
      ),
    );
  }
}
