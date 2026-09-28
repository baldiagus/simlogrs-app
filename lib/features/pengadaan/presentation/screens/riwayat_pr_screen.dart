import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../approval/presentation/providers/approval_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/pr_model.dart';
import '../providers/pengadaan_provider.dart';
import '../widgets/terbitkan_po_sheet.dart';
import 'form_pengajuan_pr_screen.dart';

class RiwayatPrScreen extends ConsumerStatefulWidget {
  const RiwayatPrScreen({super.key});

  @override
  ConsumerState<RiwayatPrScreen> createState() => _RiwayatPrScreenState();
}

class _RiwayatPrScreenState extends ConsumerState<RiwayatPrScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedFilter = 'SEMUA';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSetujuiDialog(BuildContext context, PrHeaderModel pr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Persetujuan PR'),
        content: Text(
          'Setujui permohonan pengadaan ${pr.kode} dari ${pr.unit}?\n\nDokumen akan berstatus DISETUJUI dan siap diteruskan ke Bagian Pengadaan.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final ok = await ref.read(approvalActionProvider.notifier).approvePr(
                    id: pr.id,
                    aksi: 'setujui',
                  );
              final state = ref.read(approvalActionProvider);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? (state.successMessage ?? 'PR berhasil disetujui.')
                      : (state.errorMessage ?? 'Gagal menyetujui PR.')),
                  backgroundColor: ok ? AppColors.success : AppColors.danger,
                ),
              );
              if (ok) {
                ref.invalidate(daftarPrProvider);
                ref.invalidate(approvalPendingProvider);
                ref.invalidate(dashboardSummaryProvider);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Ya, Setujui PR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTolakDialog(BuildContext context, PrHeaderModel pr, {bool isPengadaan = false}) {
    final catatanCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPengadaan ? 'Tolak di Meja Pengadaan' : 'Tolak Permohonan PR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPengadaan
                  ? 'Masukkan alasan penolakan belanja untuk PR ${pr.kode}:'
                  : 'Masukkan catatan penolakan untuk PR ${pr.kode}:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: catatanCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Misal: Melebihi plafon pagu atau barang tidak tersedia...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final catatan = catatanCtrl.text.trim();
              if (catatan.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alasan penolakan wajib dicantumkan.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final ok = await ref.read(approvalActionProvider.notifier).approvePr(
                    id: pr.id,
                    aksi: 'tolak',
                    catatan: catatan,
                  );
              final state = ref.read(approvalActionProvider);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? (state.successMessage ?? 'PR telah ditolak.')
                      : (state.errorMessage ?? 'Gagal menolak PR.')),
                  backgroundColor: ok ? AppColors.success : AppColors.danger,
                ),
              );
              if (ok) {
                ref.invalidate(daftarPrProvider);
                ref.invalidate(approvalPendingProvider);
                ref.invalidate(dashboardSummaryProvider);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Ya, Tolak PR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTeruskanDialog(BuildContext context, PrHeaderModel pr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Teruskan ke Bagian Pengadaan'),
        content: Text(
          'Teruskan dokumen ${pr.kode} dari ${pr.unit} ke Bagian Pengadaan untuk proses belanja / penerbitan PO vendor?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final ok = await ref.read(approvalActionProvider.notifier).approvePr(
                    id: pr.id,
                    aksi: 'teruskan',
                  );
              final state = ref.read(approvalActionProvider);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? (state.successMessage ?? 'PR berhasil diteruskan ke Pengadaan.')
                      : (state.errorMessage ?? 'Gagal meneruskan PR.')),
                  backgroundColor: ok ? AppColors.success : AppColors.danger,
                ),
              );
              if (ok) {
                ref.invalidate(daftarPrProvider);
                ref.invalidate(approvalPendingProvider);
                ref.invalidate(dashboardSummaryProvider);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
            child: const Text('Ya, Teruskan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDetailModal(
    BuildContext context,
    PrHeaderModel pr, {
    required bool canApproveKaru,
    required bool canManagePo,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pr.kode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryPurple,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${pr.unit} • Oleh ${pr.pengaju} (${pr.tanggalPermintaan})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: pr.status),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: pr.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (ctx, i) {
                  final item = pr.items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaBarang,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.kodeBarang != null)
                                Text(
                                  item.kodeBarang!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.jumlah} ${item.satuan}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Modal Sticky Action Bar
            if (_hasActionAvailable(pr, canApproveKaru: canApproveKaru, canManagePo: canManagePo)) ...[
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(ctx).padding.bottom + 12,
                ),
                child: _buildActionRow(
                  context,
                  pr,
                  canApproveKaru: canApproveKaru,
                  canManagePo: canManagePo,
                  onActionTaken: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasActionAvailable(
    PrHeaderModel pr, {
    required bool canApproveKaru,
    required bool canManagePo,
  }) {
    if (pr.isDiajukan && canApproveKaru) return true;
    if (pr.status == 'DISETUJUI' && (canManagePo || canApproveKaru)) return true;
    if (pr.status == 'DITERUSKAN_KE_PENGADAAN' && canManagePo) return true;
    return false;
  }

  Widget _buildActionRow(
    BuildContext context,
    PrHeaderModel pr, {
    required bool canApproveKaru,
    required bool canManagePo,
    VoidCallback? onActionTaken,
  }) {
    // 1. MEJA 1: PR DIAJUKAN -> Otorisasi Karu / Kepala Gudang
    if (pr.isDiajukan && canApproveKaru) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Tolak',
              height: 42,
              backgroundColor: const Color(0xFFFEF2F2),
              textColor: AppColors.danger,
              icon: const Icon(LucideIcons.x, size: 16, color: AppColors.danger),
              onPressed: () {
                onActionTaken?.call();
                _showTolakDialog(context, pr);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomButton(
              text: 'Setujui PR',
              height: 42,
              backgroundColor: AppColors.success,
              textColor: Colors.white,
              icon: const Icon(LucideIcons.check, size: 16, color: Colors.white),
              onPressed: () {
                onActionTaken?.call();
                _showSetujuiDialog(context, pr);
              },
            ),
          ),
        ],
      );
    }

    // 2. PR DISETUJUI
    if (pr.status == 'DISETUJUI') {
      if (canManagePo) {
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: CustomButton(
                text: 'Tolak',
                height: 42,
                backgroundColor: const Color(0xFFFEF2F2),
                textColor: AppColors.danger,
                icon: const Icon(LucideIcons.xCircle, size: 16, color: AppColors.danger),
                onPressed: () {
                  onActionTaken?.call();
                  _showTolakDialog(context, pr, isPengadaan: true);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Terbitkan PO',
                height: 42,
                backgroundColor: AppColors.primaryPurple,
                textColor: Colors.white,
                icon: const Icon(LucideIcons.filePlus, size: 16, color: Colors.white),
                onPressed: () {
                  onActionTaken?.call();
                  TerbitkanPoSheet.show(context, pr.toApprovalItem());
                },
              ),
            ),
          ],
        );
      } else if (canApproveKaru) {
        return CustomButton(
          text: 'Teruskan ke Bagian Pengadaan',
          height: 42,
          backgroundColor: AppColors.primaryPurple,
          textColor: Colors.white,
          icon: const Icon(LucideIcons.send, size: 16, color: Colors.white),
          onPressed: () {
            onActionTaken?.call();
            _showTeruskanDialog(context, pr);
          },
        );
      }
    }

    // 3. MEJA 2: PR DITERUSKAN KE PENGADAAN -> Khusus Pengadaan Terbitkan PO
    if (pr.status == 'DITERUSKAN_KE_PENGADAAN' && canManagePo) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: CustomButton(
              text: 'Tolak',
              height: 42,
              backgroundColor: const Color(0xFFFEF2F2),
              textColor: AppColors.danger,
              icon: const Icon(LucideIcons.xCircle, size: 16, color: AppColors.danger),
              onPressed: () {
                onActionTaken?.call();
                _showTolakDialog(context, pr, isPengadaan: true);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: 'Terbitkan PO',
              height: 42,
              backgroundColor: AppColors.primaryPurple,
              textColor: Colors.white,
              icon: const Icon(LucideIcons.filePlus, size: 16, color: Colors.white),
              onPressed: () {
                onActionTaken?.call();
                TerbitkanPoSheet.show(context, pr.toApprovalItem());
              },
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.canvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.border,
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

  @override
  Widget build(BuildContext context) {
    final prListAsync = ref.watch(daftarPrProvider);
    final user = ref.watch(authStateProvider).user;
    final isPengadaan = user?.isPengadaan ?? false;
    final isSuperAdmin = user?.hasRole('super_admin') ?? false;
    final isAdminLogistik = user?.isAdminLogistik ?? false;
    final isKaru = user?.isKaru ?? false;
    final isGudangUser = user?.isGudangUser ?? false;

    // Wewenang Otorisasi Meja 1 (Karu / Kepala Gudang / Admin Logistik / Super Admin)
    final canApproveKaru = !isPengadaan &&
        (isKaru ||
            isGudangUser ||
            isAdminLogistik ||
            isSuperAdmin ||
            (user?.can('update_pengadaan::permintaan::pengadaan') ?? false));

    // Wewenang Meja 2 (Pengadaan / Admin Logistik / Super Admin)
    final canManagePo = isPengadaan || isAdminLogistik || isSuperAdmin;

    final canCreate = !isPengadaan &&
        ((user?.can('create_pengadaan::permintaan::pengadaan') ?? false) ||
            (user?.hasRole('petugas_unit') ?? false) ||
            (user?.hasRole('kepala_unit') ?? false) ||
            isSuperAdmin);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Monitoring & Verifikasi PR'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.invalidate(daftarPrProvider),
            tooltip: 'Segarkan',
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const FormPengajuanPrScreen()),
                );
                if (created == true && context.mounted) {
                  ref.invalidate(daftarPrProvider);
                  ref.invalidate(dashboardSummaryProvider);
                }
              },
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text(
                'Ajukan PR Baru',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppColors.surface,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Cari kode PR, nama pemohon, atau unit...',
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua Status', 'SEMUA'),
                        const SizedBox(width: 6),
                        _buildFilterChip('Menunggu Otorisasi', 'DIAJUKAN'),
                        const SizedBox(width: 6),
                        _buildFilterChip('Siap PO (Disetujui)', 'DISETUJUI'),
                        const SizedBox(width: 6),
                        _buildFilterChip('Diteruskan ke Pengadaan', 'DITERUSKAN_KE_PENGADAAN'),
                        const SizedBox(width: 6),
                        _buildFilterChip('Ditolak', 'DITOLAK'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Content List
            Expanded(
              child: prListAsync.when(
                data: (list) {
                  final baseList = isPengadaan
                      ? list.where((pr) => pr.isDisetujui).toList()
                      : list;
                  final filtered = baseList.where((pr) {
                    // Filter Status
                    if (_selectedFilter != 'SEMUA') {
                      if (_selectedFilter == 'DITERUSKAN_KE_PENGADAAN') {
                        if (pr.status != 'DITERUSKAN_KE_PENGADAAN') return false;
                      } else if (pr.status != _selectedFilter) {
                        return false;
                      }
                    }

                    // Query Search
                    if (_query.isNotEmpty) {
                      final match = pr.kode.toLowerCase().contains(_query) ||
                          pr.unit.toLowerCase().contains(_query) ||
                          pr.pengaju.toLowerCase().contains(_query);
                      if (!match) return false;
                    }

                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(daftarPrProvider),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.65,
                          child: EmptyStateView(
                            icon: LucideIcons.fileSpreadsheet,
                            title: 'Tidak Ada Permintaan PR',
                            message: _query.isNotEmpty || _selectedFilter != 'SEMUA'
                                ? 'Tidak ada dokumen PR yang sesuai dengan kriteria filter saat ini.'
                                : (isPengadaan
                                    ? 'Belum ada permohonan pengadaan barang dari unit.'
                                    : 'Unit Anda belum pernah mengajukan permohonan pengadaan barang.'),
                            action: canCreate
                                ? ElevatedButton.icon(
                                    onPressed: () async {
                                      final created = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(builder: (_) => const FormPengajuanPrScreen()),
                                      );
                                      if (created == true && context.mounted) {
                                        ref.invalidate(daftarPrProvider);
                                        ref.invalidate(dashboardSummaryProvider);
                                      }
                                    },
                                    icon: const Icon(LucideIcons.plus, size: 18),
                                    label: const Text('Buat Pengajuan Sekarang'),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(daftarPrProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final pr = filtered[index];
                        final hasAction = _hasActionAvailable(
                          pr,
                          canApproveKaru: canApproveKaru,
                          canManagePo: canManagePo,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: pr.isCito
                                  ? AppColors.danger.withValues(alpha: 0.3)
                                  : AppColors.border,
                            ),
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
                              InkWell(
                                onTap: () => _showDetailModal(
                                  context,
                                  pr,
                                  canApproveKaru: canApproveKaru,
                                  canManagePo: canManagePo,
                                ),
                                borderRadius: BorderRadius.vertical(
                                  top: const Radius.circular(18),
                                  bottom: Radius.circular(hasAction ? 0 : 18),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.tintVioletBg,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      pr.kode,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.primaryPurple,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                                if (pr.isCito) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF2F2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text(
                                                      'CITO',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppColors.danger,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusBadge(status: pr.status),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        pr.unit,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Diajukan: ${pr.tanggalPermintaan} • Oleh ${pr.pengaju}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceSecondary,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${pr.jumlahItem} Item Barang',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const Row(
                                              children: [
                                                Text(
                                                  'Detail',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primaryPurple,
                                                  ),
                                                ),
                                                Icon(
                                                  LucideIcons.chevronRight,
                                                  size: 14,
                                                  color: AppColors.primaryPurple,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // In-card Action Bar
                              if (hasAction) ...[
                                const Divider(height: 1, color: AppColors.border),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: _buildActionRow(
                                    context,
                                    pr,
                                    canApproveKaru: canApproveKaru,
                                    canManagePo: canManagePo,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
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
                        const Icon(LucideIcons.circleAlert, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(daftarPrProvider),
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
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
}
