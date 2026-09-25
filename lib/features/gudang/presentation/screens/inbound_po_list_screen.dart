import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/po_inbound_model.dart';
import '../providers/inbound_provider.dart';
import 'form_penerimaan_po_screen.dart';

class InboundPoListScreen extends ConsumerStatefulWidget {
  const InboundPoListScreen({super.key});

  @override
  ConsumerState<InboundPoListScreen> createState() => _InboundPoListScreenState();
}

class _InboundPoListScreenState extends ConsumerState<InboundPoListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poListAsync = ref.watch(daftarPoInboundProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Penerimaan PO (Inbound)'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Segarkan',
            onPressed: () => ref.invalidate(daftarPoInboundProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surface,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari nomor PO atau nama vendor pemasok...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Content List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryPurple,
                onRefresh: () async => ref.invalidate(daftarPoInboundProvider),
                child: poListAsync.when(
                  data: (list) {
                    final filtered = list.where((po) {
                      if (_query.isEmpty) return true;
                      return po.kodePo.toLowerCase().contains(_query) ||
                          po.pemasok.toLowerCase().contains(_query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.65,
                          child: const EmptyStateView(
                            icon: LucideIcons.truck,
                            title: 'Tidak Ada Kiriman PO Aktif',
                            message: 'Semua pesanan pembelian telah selesai diterima atau belum ada pengiriman aktif dari vendor.',
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final po = filtered[index];
                        return _buildPoCard(context, po);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryPurple),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 40, color: AppColors.danger),
                          const SizedBox(height: 12),
                          const Text('Gagal Memuat Daftar PO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(
                            err.toString().replaceAll('ApiException: ', ''),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(daftarPoInboundProvider),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoCard(BuildContext context, PoInboundHeaderModel po) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tintBlueBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.truck, size: 14, color: AppColors.tintBlue),
                          const SizedBox(width: 4),
                          Text(
                            po.kodePo,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tintBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: po.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  po.pemasok,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Tgl PO: ${po.tanggalPo}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    if (po.estimasiTanggalKirim != null) ...[
                      const SizedBox(width: 10),
                      const Icon(LucideIcons.clock, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Estimasi: ${po.estimasiTanggalKirim}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${po.totalItem} Item Komoditas Barang',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      Text(
                        po.isDiterbitkan ? 'Menunggu Pengiriman Vendor' : 'Siap Inbound',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: po.isDiterbitkan ? AppColors.warning : AppColors.tintBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (po.canReceive) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: CustomButton(
                text: 'Proses Penerimaan Fisik',
                height: 42,
                backgroundColor: AppColors.primaryPurple,
                icon: const Icon(LucideIcons.packageCheck, size: 16, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FormPenerimaanPoScreen(po: po)),
                  );
                },
              ),
            ),
          ] else if (po.isDiterbitkan) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.clock, size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PO baru diterbitkan ke vendor. Penerimaan fisik dapat diproses setelah vendor mengirim barang (DIKIRIM VENDOR).',
                        style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
