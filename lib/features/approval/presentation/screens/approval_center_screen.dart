import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: themeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modalTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        item.kode,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Catatan Otorisasi (Opsional):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isSetujui
                    ? 'Tambahkan catatan jika diperlukan...'
                    : (isSerahkan
                        ? 'Tambahkan catatan untuk bagian pengadaan...'
                        : 'Tuliskan alasan penolakan dokumen...'),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final note = noteController.text.trim();
                      bool ok = false;
                      if (item.tipe == 'PR') {
                        ok = await actionNotifier.approvePr(
                          id: item.id,
                          aksi: aksi,
                          catatan: note,
                        );
                      } else {
                        ok = await actionNotifier.approveAmprah(
                          id: item.id,
                          isSetujui: isSetujui,
                          catatan: note,
                        );
                      }

                      if (!mounted) return;
                      final actionState = ref.read(approvalActionProvider);
                      final msg = ok
                          ? (actionState.successMessage ?? 'Berhasil memproses dokumen')
                          : (actionState.errorMessage ?? 'Gagal memproses dokumen');

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: ok ? AppColors.success : AppColors.danger,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(buttonLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(approvalPendingProvider);
    final user = ref.watch(authStateProvider).user;

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
                  const Text('Amprah Ruangan'),
                  const SizedBox(width: 6),
                  _buildCountBadge(pendingAsync.valueOrNull?.totalAmprah ?? 0),
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
                canApprove: canApprovePr,
              ),

              // Tab 2: Amprah List
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
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(approvalPendingProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList({
    required List<ApprovalItemModel> items,
    required String emptyTitle,
    required String emptyMessage,
    required bool canApprove,
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
