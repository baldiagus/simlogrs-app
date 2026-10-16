import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_filter_chip_bar.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../widgets/riwayat_pr_card_item.dart';
import '../widgets/pr_detail_sheet.dart';
import '../providers/approval_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/pr_model.dart';
import '../providers/pengadaan_provider.dart';
import '../widgets/terbitkan_po_sheet.dart';
import 'form_pengajuan_pr_screen.dart';

class RiwayatPrScreen extends ConsumerStatefulWidget {
  const RiwayatPrScreen({super.key});

  /// Membuat state daftar riwayat PR beserta pencarian dan filter.
  @override
  ConsumerState<RiwayatPrScreen> createState() => _RiwayatPrScreenState();
}

class _RiwayatPrScreenState extends ConsumerState<RiwayatPrScreen> {
  String _query = '';
  String _selectedFilter = 'SEMUA';

  /// Meminta konfirmasi lalu menyetujui PR (aksi Kepala Ruangan) dan me-refresh data terkait.
  Future<void> _showSetujuiDialog(BuildContext context, PrHeaderModel pr) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Konfirmasi Persetujuan PR',
      message:
          'Setujui permohonan pengadaan ${pr.kode} dari ${pr.unit}?\n\nDokumen akan berstatus DISETUJUI dan siap diteruskan ke Bagian Pengadaan.',
      confirmLabel: 'Ya, Setujui PR',
      confirmColor: AppColors.success,
      icon: LucideIcons.checkCheck,
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref.read(approvalActionProvider.notifier).approvePr(
          id: pr.id,
          aksi: 'setujui',
        );
    if (!context.mounted) return;
    final state = ref.read(approvalActionProvider);
    if (ok) {
      AppToast.success(context, state.successMessage ?? 'PR berhasil disetujui.');
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal menyetujui PR.');
    }
    if (ok) {
      ref.invalidate(daftarPrProvider);
      ref.invalidate(approvalPendingProvider);
      ref.invalidate(dashboardSummaryProvider);
    }
  }

  /// Menampilkan dialog penolakan PR dengan input alasan wajib, lalu mengirim penolakan ke server.
  void _showTolakDialog(BuildContext context, PrHeaderModel pr, {bool isPengadaan = false}) {
    final catatanCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPengadaan ? 'Tolak oleh Tim Pengadaan' : 'Tolak Permohonan PR'),
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
            /// Memvalidasi alasan penolakan lalu mengirim penolakan PR dan menyegarkan data bila berhasil.
            onPressed: () async {
              final catatan = catatanCtrl.text.trim();
              if (catatan.isEmpty) {
                AppToast.error(context, 'Alasan penolakan wajib dicantumkan.');
                return;
              }
              Navigator.pop(ctx);
              final ok = await ref.read(approvalActionProvider.notifier).approvePr(
                    id: pr.id,
                    aksi: 'tolak',
                    catatan: catatan,
                  );
              if (!context.mounted) return;
              final state = ref.read(approvalActionProvider);
              if (ok) {
                AppToast.success(context, state.successMessage ?? 'PR telah ditolak.');
              } else {
                AppToast.error(context, state.errorMessage ?? 'Gagal menolak PR.');
              }
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

  /// Meminta konfirmasi lalu meneruskan PR yang sudah disetujui ke Bagian Pengadaan.
  Future<void> _showTeruskanDialog(BuildContext context, PrHeaderModel pr) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Teruskan ke Bagian Pengadaan',
      message:
          'Teruskan dokumen ${pr.kode} dari ${pr.unit} ke Bagian Pengadaan untuk proses belanja / penerbitan PO vendor?',
      confirmLabel: 'Ya, Teruskan',
      confirmColor: AppColors.primaryPurple,
      icon: LucideIcons.send,
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref.read(approvalActionProvider.notifier).approvePr(
          id: pr.id,
          aksi: 'teruskan',
        );
    if (!context.mounted) return;
    final state = ref.read(approvalActionProvider);
    if (ok) {
      AppToast.success(context, state.successMessage ?? 'PR berhasil diteruskan ke Pengadaan.');
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal meneruskan PR.');
    }
    if (ok) {
      ref.invalidate(daftarPrProvider);
      ref.invalidate(approvalPendingProvider);
      ref.invalidate(dashboardSummaryProvider);
    }
  }

  /// Membuka bottom sheet detail PR dengan tombol aksi sesuai hak akses pengguna.
  void _showDetailModal(
    BuildContext context,
    PrHeaderModel pr, {
    required bool canApproveKaru,
    required bool canManagePo,
  }) {
    PrDetailSheet.show(
      context,
      pr: pr,
      canApproveKaru: canApproveKaru,
      canManagePo: canManagePo,
      onSetujui: () => _showSetujuiDialog(context, pr),
      onTolak: () => _showTolakDialog(
        context,
        pr,
        isPengadaan: (pr.status == PrStatus.diteruskanKePengadaan || pr.status == PrStatus.disetujui) && canManagePo,
      ),
      onTeruskan: () => _showTeruskanDialog(context, pr),
      onTerbitkanPo: () => TerbitkanPoSheet.show(context, pr.toApprovalItem()),
    );
  }

  /// Membangun layar riwayat PR lengkap dengan pencarian, filter status, dan daftar kartu PR.
  @override
  Widget build(BuildContext context) {
    final prListAsync = ref.watch(daftarPrProvider);
    final user = ref.watch(authStateProvider).user;
    final isPengadaan = user?.isPengadaan ?? false;
    final canApproveKaru = user?.canApprovePrMeja1 ?? false;
    final canManagePo = user?.canManagePo ?? false;
    final canCreate = user?.canCreatePr ?? false;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Riwayat PR'),
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
              heroTag: null,
              /// Membuka form pengajuan PR dan menyegarkan daftar PR bila PR berhasil dibuat.
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
                  AppSearchBar(
                    hint: 'Cari kode PR, nama pemohon, atau unit...',
                    onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
                    onClear: () => setState(() => _query = ''),
                  ),
                  const SizedBox(height: 8),
                  AppFilterChipBar<String>(
                    padding: EdgeInsets.zero,
                    selected: _selectedFilter,
                    onSelected: (val) => setState(() => _selectedFilter = val),
                    options: const [
                      AppFilterOption(label: 'Semua Status', value: 'SEMUA'),
                      AppFilterOption(label: 'Menunggu Otorisasi', value: PrStatus.diajukan),
                      AppFilterOption(label: 'Siap PO / Diteruskan', value: PrStatus.diteruskanKePengadaan),
                      AppFilterOption(label: 'Sedang Belanja', value: PrStatus.diproses),
                      AppFilterOption(label: 'Selesai', value: PrStatus.selesai),
                      AppFilterOption(label: 'Ditolak', value: PrStatus.ditolak),
                    ],
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
                                    /// Membuka form pengajuan PR dari tampilan kosong dan menyegarkan daftar bila berhasil.
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
                      /// Membangun kartu PR per baris daftar hasil filter.
                      itemBuilder: (context, index) {
                        final pr = filtered[index];
                        return RiwayatPrCardItem(
                          pr: pr,
                          canApproveKaru: canApproveKaru,
                          canManagePo: canManagePo,
                          onDetailTap: () => _showDetailModal(
                            context,
                            pr,
                            canApproveKaru: canApproveKaru,
                            canManagePo: canManagePo,
                          ),
                          onSetujuiTap: () => _showSetujuiDialog(context, pr),
                          onTolakTap: () => _showTolakDialog(
                            context,
                            pr,
                            isPengadaan: (pr.status == PrStatus.diteruskanKePengadaan || pr.status == PrStatus.disetujui) && canManagePo,
                          ),
                          onTeruskanTap: () => _showTeruskanDialog(context, pr),
                          onTerbitkanPoTap: () =>
                              TerbitkanPoSheet.show(context, pr.toApprovalItem()),
                        );
                      },
                    ),
                  );
                },
                loading: () => const AppLoadingView(),
                error: (err, _) => AppErrorView(
                  error: err,
                  onRetry: () => ref.invalidate(daftarPrProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
