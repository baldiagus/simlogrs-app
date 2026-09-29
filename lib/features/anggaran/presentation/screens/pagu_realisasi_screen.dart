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

class PaguRealisasiScreen extends ConsumerStatefulWidget {
  const PaguRealisasiScreen({super.key});

  @override
  ConsumerState<PaguRealisasiScreen> createState() => _PaguRealisasiScreenState();
}

class _PaguRealisasiScreenState extends ConsumerState<PaguRealisasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  void _openUnitDetailModal(BuildContext context, UnitAnggaranModel unit, String tahun) {
    if (unit.unitId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UnitDrilldownSheet(unitId: unit.unitId!, tahun: tahun, unitNama: unit.unitNama),
    );
  }

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
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagu & Realisasi Anggaran',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              'Screening Pengeluaran Logistik & Suku Cadang',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
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
                items: const [
                  DropdownMenuItem(value: '2026', child: Text('TA 2026', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                  DropdownMenuItem(value: '2025', child: Text('TA 2025', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
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
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.refresh(screeningAnggaranProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(LucideIcons.building2, size: 16),
              text: 'Pengeluaran Ruangan',
            ),
            Tab(
              icon: Icon(LucideIcons.wrench, size: 16),
              text: 'Suku Cadang IPSRS',
            ),
          ],
        ),
      ),
      body: screeningAsync.when(
        data: (data) => Column(
          children: [
            // Macro KPI Summary Cards
            _buildMacroHeader(data.ringkasan, selectedTahun),

            // Tab Views
            Expanded(
              child: TabBarView(
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
          ],
        ),
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          error: err,
          onRetry: () => ref.refresh(screeningAnggaranProvider),
        ),
      ),
    );
  }

  Widget _buildMacroHeader(AnggaranRingkasanModel ringkasan, String tahun) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Total Amprah Unit
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tintTealBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tintTeal.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amprah Ruangan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.tintTeal)),
                      Icon(LucideIcons.truck, size: 14, color: AppColors.tintTeal),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.rupiah(ringkasan.totalRealisasiDistribusi),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text('Distribusi logistik TA $tahun', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Total Sparepart IPSRS
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tintVioletBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tintViolet.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sparepart IPSRS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.tintViolet)),
                      Icon(LucideIcons.wrench, size: 14, color: AppColors.tintViolet),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.rupiah(ringkasan.totalRealisasiSparepart),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text('Servis sarana TA $tahun', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
