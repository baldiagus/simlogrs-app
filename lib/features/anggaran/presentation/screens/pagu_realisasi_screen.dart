import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../widgets/anggaran_sparepart_tab.dart';
import '../widgets/anggaran_unit_tab.dart';
import '../widgets/unit_drilldown_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/anggaran_models.dart';
import '../providers/anggaran_provider.dart';

/// Layar Pagu & Realisasi Anggaran: ringkasan makro plus tab pengeluaran ruangan dan suku cadang IPSRS.
class PaguRealisasiScreen extends ConsumerStatefulWidget {
  const PaguRealisasiScreen({super.key});

  /// Membuat state layar Pagu & Realisasi Anggaran.
  @override
  ConsumerState<PaguRealisasiScreen> createState() => _PaguRealisasiScreenState();
}

/// State layar; mengelola [TabController] dua tab dan pembukaan detail unit.
class _PaguRealisasiScreenState extends ConsumerState<PaguRealisasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Menginisialisasi [TabController] untuk dua tab (ruangan dan suku cadang).
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  /// Membuang [TabController] agar tidak bocor memori.
  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  /// Membuka bottom sheet drilldown untuk unit terpilih; diabaikan bila unit tidak punya `unitId`.
  void _openUnitDetailModal(BuildContext context, UnitAnggaranModel unit, String tahun) {
    if (unit.unitId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UnitDrilldownSheet(unitId: unit.unitId!, tahun: tahun, unitNama: unit.unitNama),
    );
  }

  /// Membangun layar: cek hak akses, lalu tampilkan header ringkasan dan tab sesuai status data (loading/error/data).
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final canAccess = user != null && (
      user.isAuditor ||
      user.isManajemen ||
      user.isPengadaan ||
      user.isAdminLogistik ||
      user.hasRole('super_admin') ||
      user.can('view_any_pengadaan::realisasi::anggaran') ||
      user.can('page_RealisasiAnggaranIndex') ||
      user.can('page_ManajemenDashboard') ||
      user.can('page_AuditorDashboard')
    );

    if (!canAccess) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Pagu & Realisasi Anggaran')),
        body: Center(
          child: EmptyStateView(
            icon: LucideIcons.shieldAlert,
            title: 'Akses Ditolak (403)',
            message: 'Anda tidak memiliki wewenang untuk melihat Pagu & Realisasi Anggaran.',
            action: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: const Text('Kembali ke Beranda'),
            ),
          ),
        ),
      );
    }


    final selectedTahun = ref.watch(selectedTahunAnggaranProvider);
    final screeningAsync = ref.watch(screeningAnggaranProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final titleStyle = Theme.of(context).appBarTheme.titleTextStyle ??
            Theme.of(context).textTheme.titleLarge!;
        final yearStyle = Theme.of(context).textTheme.labelMedium!;
        final yearPainter = TextPainter(
          text: TextSpan(text: 'TA 2026', style: yearStyle),
          textDirection: Directionality.of(context),
          textScaler: textScaler,
        )..layout();
        final yearWidth = yearPainter.width + 48;
        final yearHeight = yearPainter.height + 16;
        yearPainter.dispose();
        final titlePainter = TextPainter(
          text: TextSpan(text: 'Pagu & Realisasi Anggaran', style: titleStyle),
          textDirection: Directionality.of(context),
          textScaler: textScaler,
        )..layout(
            maxWidth: (constraints.maxWidth - 56 - 16 - yearWidth - 48 - 8)
                .clamp(1.0, double.infinity).toDouble(),
          );
        final titleHeight = titlePainter.height + 16;
        final titleLines = titlePainter.computeLineMetrics().length;
        titlePainter.dispose();
        final contentHeight = titleHeight > yearHeight ? titleHeight : yearHeight;
        return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        toolbarHeight: contentHeight > 64 ? contentHeight : 64,
        leadingWidth: 56,
        titleSpacing: 8,
        title: Text(
          'Pagu & Realisasi Anggaran',
          style: titleStyle,
          softWrap: true,
          maxLines: titleLines,
        ),
        actions: [
          Container(
            width: yearWidth,
            constraints: const BoxConstraints(minHeight: 48),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedTahun,
                isDense: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                isExpanded: true,
                itemHeight: yearHeight > 48 ? yearHeight : 48,
                style: yearStyle,
                items: const [
                  DropdownMenuItem(value: '2026', child: Text('TA 2026')),
                  DropdownMenuItem(value: '2025', child: Text('TA 2025')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(selectedTahunAnggaranProvider.notifier).state = val;
                  }
                },
              ),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Muat ulang',
            onPressed: () => ref.refresh(screeningAnggaranProvider),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          tabs: [
            Tab(
              height: 32 + MediaQuery.textScalerOf(context).scale(14) * 2,
              child: const Text('Pengeluaran Ruangan'),
            ),
            Tab(
              height: 32 + MediaQuery.textScalerOf(context).scale(14) * 2,
              child: const Text('Suku Cadang IPSRS'),
            ),
          ],
        ),
      ),
      body: screeningAsync.when(
        data: (data) => NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(child: _buildMacroHeader(data.ringkasan, selectedTahun)),
          ],
          body: TabBarView(
                controller: _tabController,
                children: [
                  AnggaranUnitTab(
                    units: data.unitAnggarans,
                    tahun: selectedTahun,
                    onUnitTap: (unit) => _openUnitDetailModal(context, unit, selectedTahun),
                  ),
                  AnggaranSparepartTab(
                    data: data,
                    tahun: selectedTahun,
                  ),
                ],
              ),
        ),
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          error: err,
          onRetry: () => ref.refresh(screeningAnggaranProvider),
        ),
      ),
        );
      },
    );
  }

  /// Membangun kartu KPI ringkasan: total amprah ruangan (distribusi) dan sparepart IPSRS.
  Widget _buildMacroHeader(AnggaranRingkasanModel ringkasan, String tahun) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tintTealBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tintTeal.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('Amprah Ruangan', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tintTeal))),
                      Icon(LucideIcons.truck, size: 14, color: AppColors.tintTeal),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.rupiah(ringkasan.totalRealisasiDistribusi),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text('Distribusi logistik TA $tahun', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
          ),
          const SizedBox(height: 10),
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tintVioletBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tintViolet.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('Sparepart IPSRS', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.tintViolet))),
                      Icon(LucideIcons.wrench, size: 14, color: AppColors.tintViolet),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.rupiah(ringkasan.totalRealisasiSparepart),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text('Servis sarana TA $tahun', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
          ),
        ],
      ),
    );
  }
}
