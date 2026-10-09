import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/audit_models.dart';
import '../providers/audit_provider.dart';
import '../widgets/sheets/detail_temuan_sheet.dart';
import '../widgets/sheets/form_capa_from_po_sheet.dart';
import '../widgets/sheets/form_terbitkan_temuan_sheet.dart';
import '../widgets/sheets/trail_detail_sheet.dart';
import '../widgets/tabs/audit_trail_tab.dart';
import '../widgets/tabs/kepatuhan_po_tab.dart';
import '../widgets/tabs/selisih_opname_tab.dart';
import '../widgets/tabs/temuan_capa_tab.dart';

class AuditSpiHubScreen extends ConsumerStatefulWidget {
  const AuditSpiHubScreen({super.key});

  @override
  ConsumerState<AuditSpiHubScreen> createState() => _AuditSpiHubScreenState();
}

class _AuditSpiHubScreenState extends ConsumerState<AuditSpiHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final hasAccess = user?.hasAuditAccess ?? false;

    if (!hasAccess) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Audit Internal (SPI)')),
        body: Center(
          child: EmptyStateView(
            icon: LucideIcons.shieldAlert,
            title: 'Akses Ditolak (403)',
            message: 'Anda tidak memiliki wewenang untuk mengakses Pusat Audit SPI & CAPA.',
            action: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: const Text('Kembali ke Beranda'),
            ),
          ),
        ),
      );
    }

    final summaryAsync = ref.watch(auditSummaryProvider);
    final isAuditor = user?.isAuditor ?? false;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text(
          'Audit Internal (SPI)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () {
              ref.invalidate(auditSummaryProvider);
              ref.invalidate(auditTrailProvider);
              ref.invalidate(kepatuhanPengadaanProvider);
              ref.invalidate(selisihOpnameProvider);
              ref.invalidate(registerTemuanProvider);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primaryPurple,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryPurple,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(text: 'Audit Trail'),
                Tab(text: 'Kepatuhan PO'),
                Tab(text: 'Selisih Opname'),
                Tab(text: 'Temuan & CAPA'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Executive Summary Pill
          summaryAsync.when(
            data: (summary) => _buildSummaryHeader(summary),
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 2. Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AuditTrailTab(onOpenDetail: (logId) => _openTrailDetailModal(context, logId)),
                KepatuhanPoTab(onTerbitkanCapa: (po) => _openFormCapaFromPo(context, po)),
                const SelisihOpnameTab(),
                TemuanCapaTab(onOpenDetail: (temuan) => _openDetailTemuanModal(context, temuan, isAuditor)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isAuditor
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _openFormTerbitkanTemuan(context),
              backgroundColor: AppColors.primaryPurple,
              icon: const Icon(LucideIcons.filePlus, color: Colors.white, size: 18),
              label: const Text('Temuan Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  // -------------------------------------------------------------
  // EXECUTIVE SUMMARY HEADER
  // -------------------------------------------------------------
  Widget _buildSummaryHeader(AuditSummaryModel summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: _buildMetricItem(
              label: 'Open CAPA',
              value: '${summary.totalInProgress + summary.totalInReview}',
              color: AppColors.danger,
              bgColor: const Color(0xFFFEF2F2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricItem(
              label: 'Closing Rate',
              value: '${summary.closingRate}%',
              color: AppColors.success,
              bgColor: const Color(0xFFECFDF5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricItem(
              label: 'Anomali PO',
              value: '${summary.totalPoAnomali}',
              color: AppColors.warning,
              bgColor: const Color(0xFFFFFBEB),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricItem(
              label: 'Selisih Opname',
              value: '${summary.sesiOpnameSelisih}',
              color: AppColors.tintViolet,
              bgColor: AppColors.tintVioletBg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // MODALS & DETAIL SHEETS
  // -------------------------------------------------------------
  void _openTrailDetailModal(BuildContext context, int logId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TrailDetailSheet(logId: logId),
    );
  }

  void _openFormCapaFromPo(BuildContext context, KepatuhanPoModel po) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FormCapaFromPoSheet(po: po),
    );
  }

  void _openFormTerbitkanTemuan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FormTerbitkanTemuanSheet(),
    );
  }

  void _openDetailTemuanModal(BuildContext context, TemuanCapaModel temuan, bool isAuditor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DetailTemuanSheet(temuan: temuan, isAuditor: isAuditor),
    );
  }
}

