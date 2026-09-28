import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pengadaan/data/models/po_model.dart';
import '../../../pengadaan/presentation/providers/pengadaan_provider.dart';
import '../../data/models/approval_item_model.dart';
import '../providers/approval_provider.dart';
import '../widgets/approval_card.dart';

class ApprovalCenterScreen extends ConsumerStatefulWidget {
  const ApprovalCenterScreen({super.key});

  @override
  ConsumerState<ApprovalCenterScreen> createState() => _ApprovalCenterScreenState();
}

class _ApprovalCenterScreenState extends ConsumerState<ApprovalCenterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _poSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _poSearchCtrl.dispose();
    super.dispose();
  }

  void _showActionModal({
    required ApprovalItemModel item,
    required String aksi, // 'setujui', 'tolak', 'serahkan'
  }) {
    final noteController = TextEditingController();
    final actionNotifier = ref.read(approvalActionProvider.notifier);
    final isSetujui = aksi == 'setujui';
    final isSerahkan = aksi == 'serahkan';

    final Color themeColor = isSetujui
        ? AppColors.success
        : (isSerahkan ? AppColors.primaryPurple : AppColors.danger);
    final IconData icon = isSetujui
        ? LucideIcons.checkCheck
        : (isSerahkan ? LucideIcons.send : LucideIcons.alertTriangle);
    final String modalTitle = isSetujui
        ? 'Setujui Dokumen'
        : (isSerahkan ? 'Serahkan ke Bagian Pengadaan' : 'Tolak Dokumen');
    final String buttonLabel = isSetujui
        ? 'Ya, Setujui'
        : (isSerahkan ? 'Ya, Serahkan ke Pengadaan' : 'Ya, Tolak');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: themeColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modalTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.kode} • ${item.unit}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isSetujui
                    ? 'Catatan persetujuan (opsional)...'
                    : (isSerahkan ? 'Catatan pelimpahan ke bagian pengadaan...' : 'Alasan penolakan dokumen (wajib)...'),
                filled: true,
                fillColor: AppColors.canvas,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: buttonLabel,
              backgroundColor: themeColor,
              textColor: Colors.white,
              onPressed: () async {
                final catatan = noteController.text.trim();
                if (!isSetujui && !isSerahkan && catatan.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alasan penolakan wajib diisi!'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final ok = await actionNotifier.eksekusi(
                  id: item.id,
                  tipe: item.tipe,
                  aksi: aksi,
                  catatan: catatan,
                );
                final state = ref.read(approvalActionProvider);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(ok ? (state.successMessage ?? 'Berhasil') : (state.errorMessage ?? 'Gagal')),
                    backgroundColor: ok ? AppColors.success : AppColors.danger,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // MODAL TERBITKAN PO DARI PR DISETUJUI
  // -------------------------------------------------------------
  void _showTerbitkanPoModal(BuildContext context, ApprovalItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TerbitkanPoSheet(prItem: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(approvalPendingProvider);
    final user = ref.watch(authStateProvider).user;
    final poListAsync = ref.watch(poListProvider);

    final isPengadaanFlow = (user?.isPengadaan == true) ||
        (user?.isAdminLogistik == true) ||
        (user?.isManajemen == true) ||
        (user?.isAuditor == true);

    final canManagePo = (user?.isPengadaan == true) ||
        (user?.isAdminLogistik == true) ||
        (user?.hasRole('super_admin') == true);
    final isReadOnly = (user?.isManajemen == true) || (user?.isAuditor == true);

    final canApprovePr = user?.can('update_pengadaan::permintaan::pengadaan') ?? false;
    final canApproveAmprah = (user?.can('update_layanan_unit::approval::karu') ?? false) ||
        (user?.can('update_gudang_stok::distribusi::approval') ?? false) ||
        (user?.hasRole('admin_logistik') ?? false);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Approval Center'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pengadaan (PR)'),
                  const SizedBox(width: 6),
                  _buildCountBadge(pendingAsync.valueOrNull?.totalPr ?? 0),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isPengadaanFlow ? 'Pesanan (PO)' : 'Amprah Ruangan'),
                  const SizedBox(width: 6),
                  _buildCountBadge(
                    isPengadaanFlow
                        ? (poListAsync.valueOrNull?.length ?? 0)
                        : (pendingAsync.valueOrNull?.totalAmprah ?? 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: pendingAsync.when(
        data: (pending) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: PR List
              _buildList(
                items: pending.prList,
                emptyTitle: 'Tidak Ada Antrean PR',
                emptyMessage: 'Semua dokumen Permintaan Pengadaan telah disetujui atau belum ada pengajuan baru.',
                canApprove: isReadOnly ? false : (canApprovePr || canManagePo),
                onTerbitkanPoTap: canManagePo ? (item) => _showTerbitkanPoModal(context, item) : null,
              ),

              // Tab 2: Pesanan PO (untuk Pengadaan/Admin/Manajemen/Auditor) atau Amprah Ruangan
              if (isPengadaanFlow)
                _buildPoListTab(canManagePo: canManagePo, isReadOnly: isReadOnly)
              else
                _buildList(
                  items: pending.amprahList,
                  emptyTitle: 'Tidak Ada Antrean Amprah',
                  emptyMessage: 'Semua permintaan distribusi ruangan telah diproses.',
                  canApprove: canApproveAmprah,
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle, size: 40, color: AppColors.danger),
                const SizedBox(height: 12),
                const Text(
                  'Gagal Memuat Antrean',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  err.toString().replaceAll('ApiException: ', ''),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(approvalPendingProvider),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: PESANAN PEMBELIAN (PO)
  // -------------------------------------------------------------
  Widget _buildPoListTab({required bool canManagePo, required bool isReadOnly}) {
    final filterStatus = ref.watch(poStatusFilterProvider);
    final poListAsync = ref.watch(poListProvider);

    return Column(
      children: [
        // Status filter pills & Search bar
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _poSearchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari kode PO atau nama rekanan vendor...',
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
                  ref.read(poSearchQueryProvider.notifier).state = val.trim();
                },
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPoFilterChip('SEMUA', 'Semua PO', filterStatus),
                    const SizedBox(width: 6),
                    _buildPoFilterChip('DITERBITKAN', 'Diterbitkan', filterStatus),
                    const SizedBox(width: 6),
                    _buildPoFilterChip('DIKIRIM_VENDOR', 'Dikirim Vendor', filterStatus),
                    const SizedBox(width: 6),
                    _buildPoFilterChip('DITERIMA_SEBAGIAN', 'Diterima Sebagian', filterStatus),
                    const SizedBox(width: 6),
                    _buildPoFilterChip('DITERIMA_LENGKAP', 'Selesai', filterStatus),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // List PO
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.refresh(poListProvider),
            child: poListAsync.when(
              data: (pos) {
                if (pos.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: const EmptyStateView(
                        icon: LucideIcons.truck,
                        title: 'Tidak Ada Pesanan PO',
                        message: 'Belum ada dokumen PO yang diterbitkan atau cocok dengan filter.',
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: pos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _buildPoCard(pos[i], canManagePo, isReadOnly),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Gagal memuat PO: $err', style: const TextStyle(color: AppColors.danger)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPoFilterChip(String value, String label, String current) {
    final isSelected = value == current;
    return InkWell(
      onTap: () {
        ref.read(poStatusFilterProvider.notifier).state = value;
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

  Widget _buildPoCard(PesananPembelianModel po, bool canManagePo, bool isReadOnly) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                po.kode,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
              ),
              StatusBadge(status: po.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rekanan / Vendor: ${po.namaPemasok}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            po.prKode != null ? 'Dasar PR: ${po.prKode} (${po.prUnit ?? "-"})' : 'Dasar PR: Tanpa PR',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nilai PO: ${currency.format(po.totalBiaya)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.tintBlue),
              ),
              Text(
                'Estimasi: ${po.estimasiTanggalKirim}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          if (po.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              '${po.totalItem} Komoditas Dipesan:',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            ...po.items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${it.namaBarang} (${it.jumlahDipesan} ${it.satuan})',
                          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        currency.format(it.subtotal),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )),
          ],

          // Action Button: Update status kirim (hanya untuk pengadaan & admin logistik)
          if (po.isDiterbitkan && canManagePo) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmUpdateKirim(context, po),
                icon: const Icon(LucideIcons.truck, size: 16, color: Colors.white),
                label: const Text('Tandai Dikirim Vendor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tintBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else if (isReadOnly) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(6)),
              child: const Text('Mode Pengawasan Eksekutif (Hanya Lihat)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmUpdateKirim(BuildContext context, PesananPembelianModel po) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pengiriman Vendor'),
        content: Text(
          'Ubah status pesanan ${po.kode} (Vendor: ${po.namaPemasok}) menjadi DIKIRIM_VENDOR? Menandakan barang pesanan sedang dalam proses ekspedisi.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final notifier = ref.read(poActionProvider.notifier);
              final ok = await notifier.updateStatusKirim(po.id);
              final s = ref.read(poActionProvider);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok ? (s.successMessage ?? 'Status berhasil diperbarui') : (s.errorMessage ?? 'Gagal')),
                  backgroundColor: ok ? AppColors.success : AppColors.danger,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tintBlue),
            child: const Text('Ya, Tandai Dikirim', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required List<ApprovalItemModel> items,
    required String emptyTitle,
    required String emptyMessage,
    required bool canApprove,
    void Function(ApprovalItemModel item)? onTerbitkanPoTap,
  }) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => ref.invalidate(approvalPendingProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: EmptyStateView(
              icon: LucideIcons.checkCheck,
              title: emptyTitle,
              message: emptyMessage,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(approvalPendingProvider),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ApprovalCard(
            item: item,
            canApprove: canApprove,
            onApproveTap: () => _showActionModal(item: item, aksi: 'setujui'),
            onRejectTap: () => _showActionModal(item: item, aksi: 'tolak'),
            onSerahkanTap: () => _showActionModal(item: item, aksi: 'serahkan'),
            onTerbitkanPoTap: onTerbitkanPoTap != null ? () => onTerbitkanPoTap(item) : null,
          );
        },
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: count > 0 ? AppColors.tintVioletBg : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: count > 0 ? AppColors.primaryPurple : AppColors.textMuted,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// BOTTOM SHEET MODAL: TERBITKAN PO BARU DARI PR
// -------------------------------------------------------------
class _TerbitkanPoSheet extends ConsumerStatefulWidget {
  final ApprovalItemModel prItem;

  const _TerbitkanPoSheet({required this.prItem});

  @override
  ConsumerState<_TerbitkanPoSheet> createState() => _TerbitkanPoSheetState();
}

class _TerbitkanPoSheetState extends ConsumerState<_TerbitkanPoSheet> {
  int? _selectedPemasokId;
  DateTime _estimasiKirim = DateTime.now().add(const Duration(days: 7));
  String _syaratBayar = 'TEMPO_30_HARI';
  final TextEditingController _catatanCtrl = TextEditingController();
  final Map<int, TextEditingController> _priceControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.prItem.items.length; i++) {
      _priceControllers[i] = TextEditingController(text: '100000');
    }
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    for (final ctrl in _priceControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  double _calculateTotal() {
    double total = 0;
    for (int i = 0; i < widget.prItem.items.length; i++) {
      final it = widget.prItem.items[i];
      final price = double.tryParse(_priceControllers[i]?.text.replaceAll('.', '') ?? '0') ?? 0;
      total += it.jumlah * price;
    }
    return total;
  }

  Future<void> _submitPo() async {
    if (_selectedPemasokId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih rekanan / vendor pemasok terlebih dahulu.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    // Validasi setiap item memiliki ID barang valid
    for (final it in widget.prItem.items) {
      if (it.barangId == null || it.barangId! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item "${it.namaBarang}" tidak memiliki ID barang yang valid.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    final itemsPayload = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.prItem.items.length; i++) {
      final it = widget.prItem.items[i];
      final price = double.tryParse(_priceControllers[i]?.text.replaceAll('.', '') ?? '0') ?? 0;
      if (price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harga satuan untuk "${it.namaBarang}" wajib lebih dari 0.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      itemsPayload.add({
        'barang_id': it.barangId!,
        'jumlah': it.jumlah,
        'harga_satuan': price,
      });
    }

    setState(() => _isLoading = true);
    try {

      final notifier = ref.read(poActionProvider.notifier);
      final ok = await notifier.terbitkanPo(
        prId: widget.prItem.id,
        pemasokId: _selectedPemasokId!,
        estimasiTanggalKirim: _estimasiKirim.toIso8601String().substring(0, 10),
        syaratPembayaran: _syaratBayar,
        catatan: _catatanCtrl.text.trim(),
        items: itemsPayload,
      );

      if (mounted) {
        final state = ref.read(poActionProvider);
        if (ok) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage ?? 'PO Berhasil Diterbitkan!'), backgroundColor: AppColors.success),
          );
          ref.invalidate(approvalPendingProvider);
          ref.invalidate(poListProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Gagal menerbitkan PO'), backgroundColor: AppColors.danger),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pemasokAsync = ref.watch(pemasokListProvider);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Terbitkan Pesanan Pembelian (PO)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('Dasar PR: ${widget.prItem.kode} • ${widget.prItem.unit}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Pilih Rekanan
                  const Text('Rekanan / Vendor Pemasok *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 6),
                  pemasokAsync.when(
                    data: (vendors) {
                      return DropdownButtonFormField<int>(
                        initialValue: _selectedPemasokId,
                        isExpanded: true,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Pilih vendor rekanan...'),
                        items: vendors.map((v) {
                          return DropdownMenuItem(
                            value: v.id,
                            child: Text('${v.nama} (${v.kode})', style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedPemasokId = val),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text('Gagal memuat vendor: $err', style: const TextStyle(color: AppColors.danger)),
                  ),
                  const SizedBox(height: 14),

                  // 2. Estimasi Kirim & Syarat Bayar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimasi Kirim', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _estimasiKirim,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 180)),
                                );
                                if (d != null) setState(() => _estimasiKirim = d);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.calendar, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text(DateFormat('dd/MM/yyyy').format(_estimasiKirim), style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Syarat Bayar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _syaratBayar,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'TEMPO_30_HARI', child: Text('Tempo 30 Hari', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'TEMPO_60_HARI', child: Text('Tempo 60 Hari', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'TUNAI', child: Text('Tunai / COD', style: TextStyle(fontSize: 12))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _syaratBayar = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Catatan PO
                  const Text('Catatan Pesanan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _catatanCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Keterangan tambahan untuk vendor...'),
                  ),
                  const SizedBox(height: 16),

                  // 4. Item Barang & Harga Negosiasi Satuan
                  const Text('Rincian Item Komoditas & Harga Satuan:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...widget.prItem.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final it = entry.value;
                    final ctrl = _priceControllers[index]!;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.namaBarang, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                Text('Qty: ${it.jumlah} ${it.satuan ?? 'Pcs'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: ctrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Harga (Rp)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Total Nilai & Tombol Terbitkan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Biaya PO:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(
                currency.format(_calculateTotal()),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primaryPurple),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitPo,
              icon: const Icon(LucideIcons.filePlus, size: 16, color: Colors.white),
              label: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Terbitkan PO Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
