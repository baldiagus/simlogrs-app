import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openUnitDetailModal(BuildContext context, UnitAnggaranModel unit, String tahun) {
    if (unit.unitId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UnitDrilldownSheet(unitId: unit.unitId!, tahun: tahun, unitNama: unit.unitNama),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
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
            _buildMacroHeader(data.ringkasan, currency, selectedTahun),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Unit Ruangan
                  _buildUnitTab(data.unitAnggarans, currency, selectedTahun),

                  // Tab 2: Sparepart IPSRS
                  _buildSparepartTab(data, currency, selectedTahun),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.alertCircle, color: AppColors.danger, size: 36),
                const SizedBox(height: 12),
                Text('Gagal memuat data: $err', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(screeningAnggaranProvider),
                  icon: const Icon(LucideIcons.refreshCw, size: 14),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroHeader(AnggaranRingkasanModel ringkasan, NumberFormat currency, String tahun) {
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
                    currency.format(ringkasan.totalRealisasiDistribusi),
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
                    currency.format(ringkasan.totalRealisasiSparepart),
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

  Widget _buildUnitTab(List<UnitAnggaranModel> units, NumberFormat currency, String tahun) {
    final filteredUnits = units.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.unitNama.toLowerCase().contains(q) ||
          u.unitKode.toLowerCase().contains(q) ||
          u.posAnggaran.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Search Filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Cari ruangan atau unit kerja...',
              prefixIcon: const Icon(LucideIcons.search, size: 16),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
        ),

        // List Units
        Expanded(
          child: filteredUnits.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Tidak ada data unit kerja yang sesuai kriteria.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.refresh(screeningAnggaranProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filteredUnits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final item = filteredUnits[index];
                      return _buildUnitCard(item, currency, tahun);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUnitCard(UnitAnggaranModel item, NumberFormat currency, String tahun) {
    final statusColor = item.status == 'Over-Budget'
        ? AppColors.danger
        : (item.status == 'Waspada' ? AppColors.warning : AppColors.success);

    return Container(
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.tintBlueBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.unitKode.isNotEmpty ? item.unitKode : item.kode,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.tintBlue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.unitNama,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pengeluaran Metrics Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amprah Logistik', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text(currency.format(item.bebanDistribusi), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.tintTeal)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sparepart Servis', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text(currency.format(item.bebanSparepart), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.tintViolet)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Beban Unit', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text(currency.format(item.realisasi), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pagu & Serapan Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pagu: ${currency.format(item.pagu)}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('Serapan: ${item.serapan.toStringAsFixed(1)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (item.serapan / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),

          // Action Button Drilldown
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => _openUnitDetailModal(context, item, tahun),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.eye, size: 14, color: AppColors.primaryPurple),
                    SizedBox(width: 4),
                    Text('Rincian Bukti Fisik', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryPurple)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparepartTab(AnggaranScreeningModel data, NumberFormat currency, String tahun) {
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(screeningAnggaranProvider),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Total Suku Cadang IPSRS
            if (data.sparepartAnggaran != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.softCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.wrench, size: 16, color: AppColors.tintViolet),
                        SizedBox(width: 6),
                        Text('Pos Suku Cadang IPSRS Sentral', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tintViolet)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Biaya Terpakai', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(
                              currency.format(data.sparepartAnggaran!.realisasi),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.tintViolet),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Pagu Alokasi', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(currency.format(data.sparepartAnggaran!.pagu), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('Sisa: ${currency.format(data.sparepartAnggaran!.sisa)}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Top 5 Aset Penyerap Biaya Pemeliharaan
            const Text(
              'Top 5 Aset Penyerap Biaya Pemeliharaan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const Text(
              'Aset sarana rumah sakit dengan akumulasi biaya suku cadang tertinggi.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            if (data.topAset.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Belum ada pemakaian suku cadang pada aset untuk TA ini.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              )
            else
              ...data.topAset.map((aset) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.tintOrangeBg, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(LucideIcons.armchair, size: 16, color: AppColors.tintOrange),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(aset.nama, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              Text('${aset.kodeAset} • Lokasi: ${aset.lokasiRuangan}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currency.format(aset.totalBiayaSparepart), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tintViolet)),
                            Text('${aset.frekuensiServis}x servis', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  )),

            const SizedBox(height: 20),

            // Log Konsumsi Suku Cadang Terakhir
            const Text(
              'Log Konsumsi Suku Cadang Terakhir',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const Text(
              'Catatan suku cadang yang dipasang teknisi pada lembar kerja SPK.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            if (data.riwayatSparepart.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Belum ada log pergantian suku cadang.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              )
            else
              ...data.riwayatSparepart.map((log) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.sparepartNama, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              Text('Aset: ${log.asetNama} (SPK: ${log.spkKode})', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              Text('Batch: ${log.nomorBatch} • Tgl: ${log.tanggal}', style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currency.format(log.subtotal), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.tintTeal)),
                            Text('${log.jumlah} unit', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// DRILLDOWN DETAIL UNIT SHEET
// -------------------------------------------------------------
class _UnitDrilldownSheet extends ConsumerWidget {
  final int unitId;
  final String tahun;
  final String unitNama;

  const _UnitDrilldownSheet({
    required this.unitId,
    required this.tahun,
    required this.unitNama,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final detailAsync = ref.watch(unitDrilldownProvider((unitId: unitId, tahun: tahun)));

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Screening Pengeluaran TA $tahun', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryPurple)),
                    Text(unitNama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: detailAsync.when(
              data: (detail) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3 Metric Stat Boxes
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.tintTealBg, borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Amprah', style: TextStyle(fontSize: 10, color: AppColors.tintTeal, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(currency.format(detail.bebanDistribusi), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.tintVioletBg, borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sparepart', style: TextStyle(fontSize: 10, color: AppColors.tintViolet, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(currency.format(detail.bebanSparepart), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.tintBlueBg, borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 10, color: AppColors.tintBlue, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(currency.format(detail.totalPengeluaran), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Section 1: Riwayat SPPB Distribusi
                    const Text('Riwayat Distribusi Amprah (SPPB)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (detail.riwayatSppb.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Belum ada pengiriman SPPB untuk unit ini pada TA $tahun.', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      )
                    else
                      ...detail.riwayatSppb.map((sppb) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sppb.kode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                    Text('${sppb.gudangNama} • Tgl: ${sppb.tanggalKirim} • ${sppb.totalItem} item', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  ],
                                ),
                                Text(currency.format(sppb.totalNilai), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tintTeal)),
                              ],
                            ),
                          )),

                    const SizedBox(height: 18),

                    // Section 2: Riwayat Servis Sarana & Sparepart
                    const Text('Riwayat Penggantian Sparepart Sarana', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (detail.riwayatServis.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Belum ada suku cadang terpasang untuk unit ini pada TA $tahun.', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      )
                    else
                      ...detail.riwayatServis.map((servis) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(servis.sparepartNama, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                      Text('Aset: ${servis.asetNama} (SPK: ${servis.spkKode}) • ${servis.tanggal}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(currency.format(servis.subtotal), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.tintViolet)),
                                    Text('${servis.jumlah} unit', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Gagal memuat detail: $err', style: const TextStyle(fontSize: 12, color: AppColors.danger))),
            ),
          ),
        ],
      ),
    );
  }
}
