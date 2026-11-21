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

/// Layar hub Audit SPI: ringkasan eksekutif plus tab jejak audit, kepatuhan PO, selisih opname, dan temuan CAPA.
class AuditSpiHubScreen extends ConsumerStatefulWidget {
  /// Indeks tab awal (0 = Audit Trail ... 3 = Temuan & CAPA).
  final int initialTab;

  const AuditSpiHubScreen({super.key, this.initialTab = 0});

  /// Membuat state hub Audit SPI.
  @override
  ConsumerState<AuditSpiHubScreen> createState() => _AuditSpiHubScreenState();
}

/// State hub Audit SPI: mengelola TabController empat tab.
class _AuditSpiHubScreenState extends ConsumerState<AuditSpiHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Menyiapkan [TabController] untuk empat tab hub audit.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
  }

  /// Membuang [TabController] agar tidak bocor memori.
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Membangun hub audit SPI: header ringkasan, tab navigasi, dan tombol terbitkan temuan untuk auditor.
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
        title: Text(
          'Audit Internal (SPI)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Muat ulang',
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
          preferredSize: Size.fromHeight(24 + MediaQuery.textScalerOf(context).scale(14) * 2),
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
              labelStyle: Theme.of(context).textTheme.titleSmall,
              unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium,
              tabs: [
                for (final label in ['Audit Trail', 'Kepatuhan PO', 'Selisih Opname', 'Temuan & CAPA'])
                  Tab(
                    height: 24 + MediaQuery.textScalerOf(context).scale(14) * 2,
                    child: Text(label),
                  ),
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
                TemuanCapaTab(onOpenDetail: (temuan) => _openDetailTemuanModal(context, temuan)),
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
              icon: const Icon(LucideIcons.filePlus, color: AppColors.surface, size: 18),
              label: Text('Temuan Baru', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.surface)),
            )
          : null,
    );
  }

  // -------------------------------------------------------------
  // EXECUTIVE SUMMARY HEADER
  // -------------------------------------------------------------
  /// Membangun header ringkasan eksekutif: closing rate CAPA dan hitungan temuan/anomali dari [summary].
  Widget _buildSummaryHeader(AuditSummaryModel summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labels = ['Open CAPA', 'Closing Rate', 'Anomali PO', 'Selisih Opname'];
          final values = ['${summary.totalInProgress + summary.totalInReview}', '${summary.closingRate}%', '${summary.totalPoAnomali}', '${summary.sesiOpnameSelisih}'];
          final scaler = MediaQuery.textScalerOf(context);
          final style = Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 11);
          var width = (constraints.maxWidth - 24) / 4;
          for (final label in labels) {
            for (final word in label.split(' ')) {
              final painter = TextPainter(text: TextSpan(text: word, style: style), textDirection: Directionality.of(context), textScaler: scaler)..layout();
              if (painter.width + 12 > width) width = painter.width + 12;
              painter.dispose();
            }
          }
          for (final value in values) {
            final painter = TextPainter(text: TextSpan(text: value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)), textDirection: Directionality.of(context), textScaler: scaler)..layout();
            if (painter.width + 12 > width) width = painter.width + 12;
            painter.dispose();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: width, child: _buildMetricItem(
                label: 'Open CAPA',
                value: '${summary.totalInProgress + summary.totalInReview}',
                color: AppColors.danger,
                bgColor: AppColors.danger.withValues(alpha: 0.08),
              )),
              const SizedBox(width: 8),
              SizedBox(width: width, child: _buildMetricItem(
                label: 'Closing Rate', value: '${summary.closingRate}%',
                color: AppColors.success,
                bgColor: AppColors.success.withValues(alpha: 0.08),
              )),
              const SizedBox(width: 8),
              SizedBox(width: width, child: _buildMetricItem(
                label: 'Anomali PO', value: '${summary.totalPoAnomali}',
                color: AppColors.warning,
                bgColor: AppColors.warning.withValues(alpha: 0.08),
              )),
              const SizedBox(width: 8),
              SizedBox(width: width, child: _buildMetricItem(
                label: 'Selisih Opname', value: '${summary.sesiOpnameSelisih}',
                color: AppColors.tintViolet, bgColor: AppColors.tintVioletBg,
              )),
            ],
          )),
          ),
          if (width * 4 + 24 > constraints.maxWidth)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Geser untuk melihat semua ringkasan →', style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
          );
        },
      ),
    );
  }

  /// Membangun kartu metrik kecil (label + nilai) pada header ringkasan.
  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontSize: 11),
          )),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // MODALS & DETAIL SHEETS
  // -------------------------------------------------------------
  /// Membuka sheet detail forensik log audit (data sebelum vs sesudah) untuk [logId].
  void _openTrailDetailModal(BuildContext context, int logId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TrailDetailSheet(logId: logId),
    );
  }

  /// Membuka sheet form penerbitan CAPA berdasarkan anomali [po] terpilih.
  void _openFormCapaFromPo(BuildContext context, KepatuhanPoModel po) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FormCapaFromPoSheet(po: po),
    );
  }

  /// Membuka sheet form penerbitan temuan audit baru (khusus auditor).
  void _openFormTerbitkanTemuan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FormTerbitkanTemuanSheet(),
    );
  }

  /// Membuka sheet detail temuan; hak tindak lanjut (auditee) dan evaluasi (auditor) dihitung dari user aktif.
  void _openDetailTemuanModal(BuildContext context, TemuanCapaModel temuan) {
    final user = ref.read(authStateProvider).user;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DetailTemuanSheet(
        temuan: temuan,
        canTindakLanjut: canTindakLanjutTemuan(user, temuan),
        canEvaluasi: canEvaluasiTemuan(user),
      ),
    );
  }
}

