import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/audit_models.dart';
import '../../data/repositories/audit_repository.dart';
import '../providers/audit_provider.dart';

class AuditSpiHubScreen extends ConsumerStatefulWidget {
  const AuditSpiHubScreen({super.key});

  @override
  ConsumerState<AuditSpiHubScreen> createState() => _AuditSpiHubScreenState();
}

class _AuditSpiHubScreenState extends ConsumerState<AuditSpiHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filters for Audit Trail
  String? _trailAksi;
  final TextEditingController _trailSearchCtrl = TextEditingController();

  // Filters for Kepatuhan PO
  final TextEditingController _poSearchCtrl = TextEditingController();

  // Filters for Temuan CAPA
  String? _capaStatus;
  String? _capaRisiko;
  final TextEditingController _capaSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trailSearchCtrl.dispose();
    _poSearchCtrl.dispose();
    _capaSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(auditSummaryProvider);
    final user = ref.watch(authStateProvider).user;
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
                _buildAuditTrailTab(),
                _buildKepatuhanPoTab(),
                _buildSelisihOpnameTab(),
                _buildTemuanCapaTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isAuditor
          ? FloatingActionButton.extended(
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
  // TAB 1: AUDIT TRAIL (FORENSIK DIGITAL)
  // -------------------------------------------------------------
  Widget _buildAuditTrailTab() {
    final filter = AuditTrailFilter(
      aksi: _trailAksi,
      search: _trailSearchCtrl.text.trim().isEmpty ? null : _trailSearchCtrl.text.trim(),
    );
    final trailAsync = ref.watch(auditTrailProvider(filter));

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
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
                  onSubmitted: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _trailAksi,
                hint: const Text('Semua Aksi', style: TextStyle(fontSize: 12)),
                underline: const SizedBox.shrink(),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua Aksi')),
                  DropdownMenuItem(value: 'TAMBAH', child: Text('TAMBAH')),
                  DropdownMenuItem(value: 'UBAH', child: Text('UBAH')),
                  DropdownMenuItem(value: 'HAPUS', child: Text('HAPUS')),
                  DropdownMenuItem(value: 'APPROVE', child: Text('APPROVE')),
                  DropdownMenuItem(value: 'REJECT', child: Text('REJECT')),
                  DropdownMenuItem(value: 'ADJUSTMENT', child: Text('ADJUSTMENT')),
                ],
                onChanged: (val) => setState(() => _trailAksi = val),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: trailAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return _buildEmptyState(
                  icon: LucideIcons.fileSearch,
                  title: 'Tidak Ada Log Audit',
                  message: 'Tidak ditemukan rekaman log audit forensik dengan kriteria filter saat ini.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(auditTrailProvider(filter)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _buildTrailCard(items[i]),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _buildErrorState(err.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildTrailCard(AuditTrailItemModel item) {
    Color badgeColor;
    Color badgeBg;

    switch (item.aksi.toUpperCase()) {
      case 'TAMBAH':
        badgeColor = AppColors.success;
        badgeBg = const Color(0xFFECFDF5);
        break;
      case 'UBAH':
        badgeColor = AppColors.tintBlue;
        badgeBg = AppColors.tintBlueBg;
        break;
      case 'HAPUS':
      case 'REJECT':
        badgeColor = AppColors.danger;
        badgeBg = const Color(0xFFFEF2F2);
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
      onTap: () => _openTrailDetailModal(context, item.id),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    item.aksi,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
                Text(
                  item.waktu,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${item.referensiJenis} #${item.referensiId}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.user, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${item.penggunaNama} (${item.peran})',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(LucideIcons.globe, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'IP: ${item.ipAddress}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const Spacer(),
                if (item.hasDataSebelum || item.hasDataSesudah)
                  const Text(
                    'Lihat Diff Data ->',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryPurple),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: KEPATUHAN PENGADAAN (PO VS PR)
  // -------------------------------------------------------------
  Widget _buildKepatuhanPoTab() {
    final currentFilter = ref.watch(kepatuhanPoFilterProvider);
    final poListAsync = ref.watch(kepatuhanPengadaanProvider);
    final user = ref.watch(authStateProvider).user;
    final isAuditor = user?.isAuditor ?? false;

    return Column(
      children: [
        // Filter pills & search
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Column(
            children: [
              TextField(
                controller: _poSearchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari kode PO atau nama vendor...',
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
                onSubmitted: (val) {
                  ref.read(kepatuhanPoSearchProvider.notifier).state = val;
                },
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPoFilterChip('SEMUA', 'Semua PO', currentFilter),
                    const SizedBox(width: 6),
                    _buildPoFilterChip('TANPA_PR', 'Tanpa PR (Mayor)', currentFilter),
                    const SizedBox(width: 6),
                    _buildPoFilterChip('TERLAMBAT', 'Terlambat Kirim', currentFilter),
                    const SizedBox(width: 6),
                    _buildPoFilterChip('SELISIH_RCV', 'Selisih Diterima', currentFilter),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: poListAsync.when(
            data: (pos) {
              if (pos.isEmpty) {
                return _buildEmptyState(
                  icon: LucideIcons.shieldCheck,
                  title: 'Semua Transaksi Patuh',
                  message: 'Tidak ditemukan transaksi PO dengan anomali kepatuhan pada filter ini.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(kepatuhanPengadaanProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: pos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _buildKepatuhanPoCard(pos[i], isAuditor),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _buildErrorState(err.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildPoFilterChip(String value, String label, String current) {
    final isSelected = value == current;
    return InkWell(
      onTap: () {
        ref.read(kepatuhanPoFilterProvider.notifier).state = value;
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.canvas,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primaryPurple : AppColors.border),
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

  Widget _buildKepatuhanPoCard(KepatuhanPoModel po, bool isAuditor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: po.isCompliant ? AppColors.border : AppColors.danger.withValues(alpha: 0.3),
        ),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                po.kode,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
              ),
              if (po.isCompliant)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                  child: const Text('PATUH', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 10)),
                )
              else
                Wrap(
                  spacing: 4,
                  children: po.anomaliTags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        tag,
                        style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 9),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rekanan / Vendor: ${po.pemasok}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            po.prKode != null ? 'Dasar PR: ${po.prKode} (${po.prUnit ?? "-"})' : 'Dasar PR: [Diterbitkan Tanpa PR]',
            style: TextStyle(
              fontSize: 12,
              color: po.prKode != null ? AppColors.textSecondary : AppColors.danger,
              fontWeight: po.prKode != null ? FontWeight.normal : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nilai PO: Rp ${po.totalBiaya.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.tintBlue),
              ),
              Text(
                'Estimasi: ${po.estimasiTanggalKirim}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          if (!po.isCompliant && isAuditor) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openFormCapaFromPo(context, po),
                icon: const Icon(LucideIcons.shieldAlert, size: 14, color: AppColors.danger),
                label: const Text('Terbitkan Temuan CAPA', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: SELISIH OPNAME
  // -------------------------------------------------------------
  Widget _buildSelisihOpnameTab() {
    final opnameAsync = ref.watch(selisihOpnameProvider);

    return opnameAsync.when(
      data: (data) {
        final sesiList = (data['sesi_opname'] as List<SesiOpnameSelisihModel>?) ?? [];
        final penyesuaianList = (data['penyesuaian'] as List<PenyesuaianStokAuditModel>?) ?? [];

        if (sesiList.isEmpty && penyesuaianList.isEmpty) {
          return _buildEmptyState(
            icon: LucideIcons.scale,
            title: 'Stok Fisik & Sistem Klop',
            message: 'Tidak ada catatan selisih hasil stock opname atau antrean otorisasi penyesuaian.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(selisihOpnameProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (sesiList.isNotEmpty) ...[
                const Text(
                  'Sesi Opname dengan Selisih Kuantitas',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                ...sesiList.map((s) => _buildSesiSelisihCard(s)),
                const SizedBox(height: 20),
              ],
              if (penyesuaianList.isNotEmpty) ...[
                const Text(
                  'Register Penyesuaian Stok (Adjustments)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                ...penyesuaianList.map((p) => _buildPenyesuaianCard(p)),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _buildErrorState(err.toString()),
    );
  }

  Widget _buildSesiSelisihCard(SesiOpnameSelisihModel sesi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sesi.kode,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${sesi.totalBatchSelisih} Batch Selisih',
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lokasi: ${sesi.gudang} • Petugas: ${sesi.petugas}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...sesi.details.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.namaBarang, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          Text('Batch: ${d.nomorBatch}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Sistem: ${d.jumlahSistem} -> Fisik: ${d.jumlahFisik}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Selisih: ${d.selisih > 0 ? "+" : ""}${d.selisih} ${d.satuan}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: d.selisih < 0 ? AppColors.danger : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPenyesuaianCard(PenyesuaianStokAuditModel p) {
    final isMenunggu = p.status == 'MENUNGGU';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p.kode, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isMenunggu ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.status,
                  style: TextStyle(
                    color: isMenunggu ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Gudang: ${p.gudang} • Diajukan: ${p.pengaju}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          if (p.alasan != null && p.alasan!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('Alasan: ${p.alasan}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${p.totalItem} Komoditas Disesuaikan', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Text('Penyetuju: ${p.penyetuju}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: TEMUAN AUDIT & CAPA
  // -------------------------------------------------------------
  Widget _buildTemuanCapaTab() {
    ref.watch(temuanFilterProvider);
    final temuanAsync = ref.watch(registerTemuanProvider);
    final user = ref.watch(authStateProvider).user;
    final isAuditor = user?.isAuditor ?? false;

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Column(
            children: [
              TextField(
                controller: _capaSearchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari objek audit, kode AUD...',
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
                onSubmitted: (val) {
                  ref.read(temuanFilterProvider.notifier).state = TemuanFilter(
                    status: _capaStatus,
                    risiko: _capaRisiko,
                    search: val.trim().isEmpty ? null : val.trim(),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _capaStatus,
                      hint: const Text('Semua Status', style: TextStyle(fontSize: 11)),
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Semua Status')),
                        DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'In Review', child: Text('In Review')),
                        DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                      ],
                      onChanged: (val) {
                        setState(() => _capaStatus = val);
                        ref.read(temuanFilterProvider.notifier).state = TemuanFilter(
                          status: val,
                          risiko: _capaRisiko,
                          search: _capaSearchCtrl.text.trim().isEmpty ? null : _capaSearchCtrl.text.trim(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _capaRisiko,
                      hint: const Text('Semua Risiko', style: TextStyle(fontSize: 11)),
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Semua Risiko')),
                        DropdownMenuItem(value: 'Mayor', child: Text('Mayor')),
                        DropdownMenuItem(value: 'Moderat', child: Text('Moderat')),
                        DropdownMenuItem(value: 'Minor', child: Text('Minor')),
                      ],
                      onChanged: (val) {
                        setState(() => _capaRisiko = val);
                        ref.read(temuanFilterProvider.notifier).state = TemuanFilter(
                          status: _capaStatus,
                          risiko: val,
                          search: _capaSearchCtrl.text.trim().isEmpty ? null : _capaSearchCtrl.text.trim(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: temuanAsync.when(
            data: (temuans) {
              if (temuans.isEmpty) {
                return _buildEmptyState(
                  icon: LucideIcons.clipboardList,
                  title: 'Register CAPA Bersih',
                  message: 'Tidak ditemukan rekaman temuan audit pada kriteria filter saat ini.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.refresh(registerTemuanProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: temuans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _buildTemuanCard(temuans[i], isAuditor),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _buildErrorState(err.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildTemuanCard(TemuanCapaModel temuan, bool isAuditor) {
    Color riskColor;
    switch (temuan.tingkatRisiko) {
      case 'Mayor':
        riskColor = AppColors.danger;
        break;
      case 'Moderat':
        riskColor = AppColors.warning;
        break;
      default:
        riskColor = AppColors.tintBlue;
    }

    Color statusColor;
    Color statusBg;
    switch (temuan.statusCapa) {
      case 'Closed':
        statusColor = AppColors.success;
        statusBg = const Color(0xFFECFDF5);
        break;
      case 'In Review':
        statusColor = AppColors.tintViolet;
        statusBg = AppColors.tintVioletBg;
        break;
      default:
        statusColor = temuan.isOverdue ? AppColors.danger : AppColors.warning;
        statusBg = temuan.isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    }

    return InkWell(
      onTap: () => _openDetailTemuanModal(context, temuan, isAuditor),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: temuan.isOverdue ? AppColors.danger.withValues(alpha: 0.5) : AppColors.border),
          boxShadow: AppShadows.softCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      temuan.kode,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        temuan.tingkatRisiko,
                        style: TextStyle(color: riskColor, fontWeight: FontWeight.w700, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    temuan.statusCapa,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              temuan.objekAudit,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              temuan.ringkasan,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.calendar, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Due Date: ${temuan.dueDateCapa}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: temuan.isOverdue ? FontWeight.w700 : FontWeight.normal,
                    color: temuan.isOverdue ? AppColors.danger : AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  'Unit: ${temuan.unit}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
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
      builder: (ctx) => _TrailDetailSheet(logId: logId),
    );
  }

  void _openFormCapaFromPo(BuildContext context, KepatuhanPoModel po) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FormCapaFromPoSheet(po: po),
    );
  }

  void _openFormTerbitkanTemuan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _FormTerbitkanTemuanSheet(),
    );
  }

  void _openDetailTemuanModal(BuildContext context, TemuanCapaModel temuan, bool isAuditor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DetailTemuanSheet(temuan: temuan, isAuditor: isAuditor),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Gagal memuat data: $error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.danger, fontSize: 13),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// DETAIL AUDIT TRAIL SHEET (DIFF LAMA VS BARU)
// -------------------------------------------------------------
class _TrailDetailSheet extends ConsumerWidget {
  final int logId;

  const _TrailDetailSheet({required this.logId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(auditRepositoryProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: FutureBuilder<AuditTrailItemModel>(
        future: repo.getAuditTrailDetail(logId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(child: Text('Gagal memuat detail log: ${snap.error}'));
          }

          final log = snap.data!;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Log Forensik #${log.id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(log.aksi, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryPurple)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Entitas: ${log.referensiJenis} ID ${log.referensiId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Operator: ${log.penggunaNama} (${log.peran})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('Waktu: ${log.waktu}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    Text('IP: ${log.ipAddress} • Device: ${log.device}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 16),
                    const Text('Data Sebelum Perubahan (Nilai Lama):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.danger)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        log.dataSebelum != null ? log.dataSebelum.toString() : '[Kosong / Nilai Awal]',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Data Sesudah Perubahan (Nilai Baru):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.success)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        log.dataSesudah != null ? log.dataSesudah.toString() : '[Kosong / Dihapus]',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// FORM TERBITKAN CAPA DARI ANOMALI PO
// -------------------------------------------------------------
class _FormCapaFromPoSheet extends ConsumerStatefulWidget {
  final KepatuhanPoModel po;

  const _FormCapaFromPoSheet({required this.po});

  @override
  ConsumerState<_FormCapaFromPoSheet> createState() => _FormCapaFromPoSheetState();
}

class _FormCapaFromPoSheetState extends ConsumerState<_FormCapaFromPoSheet> {
  String _risiko = 'Mayor';
  final TextEditingController _ringkasanCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final po = widget.po;
    if (po.anomaliTags.contains('TANPA_PR')) {
      _ringkasanCtrl.text = 'Penerbitan PO ${po.kode} senilai Rp ${po.totalBiaya.toStringAsFixed(0)} tanpa dokumen PR resmi dari unit.';
    } else if (po.anomaliTags.contains('TERLAMBAT')) {
      _ringkasanCtrl.text = 'Pengiriman barang PO ${po.kode} dari vendor ${po.pemasok} terlambat melewati estimasi kirim.';
    } else {
      _ringkasanCtrl.text = 'Ditemukan selisih kuantitas barang yang diterima di gudang pada dokumen PO ${po.kode}.';
    }
  }

  @override
  void dispose() {
    _ringkasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(auditRepositoryProvider);
      await repo.buatTemuanKepatuhan(
        widget.po.id,
        tingkatRisiko: _risiko,
        dueDateCapa: _dueDate.toIso8601String().substring(0, 10),
        ringkasan: _ringkasanCtrl.text.trim(),
        tipeAnomali: widget.po.anomaliTags.isNotEmpty ? widget.po.anomaliTags.first : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Temuan CAPA berhasil diterbitkan ke register!'), backgroundColor: AppColors.success),
        );
        ref.invalidate(auditSummaryProvider);
        ref.invalidate(registerTemuanProvider);
        ref.invalidate(kepatuhanPengadaanProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menerbitkan CAPA: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Terbitkan Temuan CAPA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Objek Audit: PO ${widget.po.kode} - ${widget.po.pemasok}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 12),
          const Text('Tingkat Risiko *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: _risiko,
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'Mayor', child: Text('Mayor (14 Hari)')),
              DropdownMenuItem(value: 'Moderat', child: Text('Moderat (30 Hari)')),
              DropdownMenuItem(value: 'Minor', child: Text('Minor (60 Hari)')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _risiko = val;
                  _dueDate = DateTime.now().add(Duration(days: val == 'Mayor' ? 14 : (val == 'Moderat' ? 30 : 60)));
                });
              }
            },
          ),
          const SizedBox(height: 12),
          const Text('Ringkasan Temuan & Ketidaksesuaian *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: _ringkasanCtrl,
            maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Uraikan ketidakpatuhan prosedur...'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan ke Register CAPA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// FORM TERBITKAN TEMUAN BARU OLEH AUDITOR
// -------------------------------------------------------------
class _FormTerbitkanTemuanSheet extends ConsumerStatefulWidget {
  const _FormTerbitkanTemuanSheet();

  @override
  ConsumerState<_FormTerbitkanTemuanSheet> createState() => _FormTerbitkanTemuanSheetState();
}

class _FormTerbitkanTemuanSheetState extends ConsumerState<_FormTerbitkanTemuanSheet> {
  final TextEditingController _objekCtrl = TextEditingController();
  final TextEditingController _ringkasanCtrl = TextEditingController();
  String _risiko = 'Moderat';
  final DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void dispose() {
    _objekCtrl.dispose();
    _ringkasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_objekCtrl.text.trim().length < 5 || _ringkasanCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Objek minimal 5 karakter, ringkasan minimal 10 karakter.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(auditRepositoryProvider);
      await repo.simpanTemuan(
        objekAudit: _objekCtrl.text.trim(),
        ringkasan: _ringkasanCtrl.text.trim(),
        tingkatRisiko: _risiko,
        tanggalAudit: DateTime.now().toIso8601String().substring(0, 10),
        dueDateCapa: _dueDate.toIso8601String().substring(0, 10),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Temuan audit berhasil diterbitkan!'), backgroundColor: AppColors.success),
        );
        ref.invalidate(auditSummaryProvider);
        ref.invalidate(registerTemuanProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendaftarkan temuan: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Penerbitan Temuan Audit Baru', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Objek Audit / Bidang Pemeriksaan *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
              controller: _objekCtrl,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'misal: Logistik Sentral, Gudang Farmasi, Ruang ICU'),
            ),
            const SizedBox(height: 12),
            const Text('Tingkat Risiko *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _risiko,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Mayor', child: Text('Mayor')),
                DropdownMenuItem(value: 'Moderat', child: Text('Moderat')),
                DropdownMenuItem(value: 'Minor', child: Text('Minor')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _risiko = val);
              },
            ),
            const SizedBox(height: 12),
            const Text('Ringkasan Uraian Temuan *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
              controller: _ringkasanCtrl,
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Uraikan fakta temuan, regulasi/SOP yang dilanggar...'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Daftarkan Temuan ke SPI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// DETAIL & AKSI TINDAK LANJUT / EVALUASI CLOSING CAPA
// -------------------------------------------------------------
class _DetailTemuanSheet extends ConsumerStatefulWidget {
  final TemuanCapaModel temuan;
  final bool isAuditor;

  const _DetailTemuanSheet({required this.temuan, required this.isAuditor});

  @override
  ConsumerState<_DetailTemuanSheet> createState() => _DetailTemuanSheetState();
}

class _DetailTemuanSheetState extends ConsumerState<_DetailTemuanSheet> {
  final TextEditingController _analisisCtrl = TextEditingController();
  final TextEditingController _tindakanCtrl = TextEditingController();
  final TextEditingController _evaluasiCtrl = TextEditingController();
  String _hasilEvaluasi = 'Closed';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _analisisCtrl.text = widget.temuan.analisisPenyebab ?? '';
    _tindakanCtrl.text = widget.temuan.tindakanPerbaikan ?? '';
    _evaluasiCtrl.text = widget.temuan.catatanEvaluasi ?? '';
  }

  @override
  void dispose() {
    _analisisCtrl.dispose();
    _tindakanCtrl.dispose();
    _evaluasiCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitTindakLanjut() async {
    if (_analisisCtrl.text.trim().length < 10 || _tindakanCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analisis dan tindakan perbaikan minimal 10 karakter.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(auditRepositoryProvider);
      await repo.tindakLanjutTemuan(
        widget.temuan.id,
        analisisPenyebab: _analisisCtrl.text.trim(),
        tindakanPerbaikan: _tindakanCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tindak lanjut berhasil dikirimkan ke auditor!'), backgroundColor: AppColors.success),
        );
        ref.invalidate(registerTemuanProvider);
        ref.invalidate(auditSummaryProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirimkan tindak lanjut: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitEvaluasi() async {
    if (_evaluasiCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan evaluasi minimal 5 karakter.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(auditRepositoryProvider);
      await repo.evaluasiTemuan(
        widget.temuan.id,
        hasilEvaluasi: _hasilEvaluasi,
        catatanEvaluasi: _evaluasiCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evaluasi closing berhasil disimpan ($_hasilEvaluasi)!'), backgroundColor: AppColors.success),
        );
        ref.invalidate(registerTemuanProvider);
        ref.invalidate(auditSummaryProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan evaluasi: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.temuan;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.kode, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 6),
            Text(t.objekAudit, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text('Unit: ${t.unit} • Auditor: ${t.auditor}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(10)),
              child: Text(t.ringkasan, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Bagian Tindak Lanjut Auditee
            const Text('Tindak Lanjut Auditee (Penyebab & Solusi)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _analisisCtrl,
              maxLines: 2,
              enabled: t.statusCapa != 'Closed',
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Analisis akar penyebab (Root Cause)...'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tindakanCtrl,
              maxLines: 2,
              enabled: t.statusCapa != 'Closed',
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Tindakan perbaikan dan pencegahan (CAPA)...'),
            ),
            if (t.statusCapa != 'Closed') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitTindakLanjut,
                  icon: const Icon(LucideIcons.send, size: 14, color: Colors.white),
                  label: const Text('Kirim Tindak Lanjut', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.tintBlue),
                ),
              ),
            ],

            // Bagian Evaluasi Closing (Khusus Auditor)
            if (widget.isAuditor) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Evaluasi Closing Auditor SPI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryPurple)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _hasilEvaluasi,
                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Closed', child: Text('Closed (Puas & Masalah Selesai)')),
                  DropdownMenuItem(value: 'In Progress', child: Text('In Progress (Tolak / Perlu Perbaikan Lanjut)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _hasilEvaluasi = val);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _evaluasiCtrl,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Catatan rekomendasi evaluator...'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitEvaluasi,
                  icon: const Icon(LucideIcons.checkCheck, size: 14, color: Colors.white),
                  label: const Text('Simpan Evaluasi Auditor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
