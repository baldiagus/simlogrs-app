import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/inisiasi_opname_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import 'hitung_fisik_opname_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/stock_opname_model.dart';
import '../providers/persediaan_providers.dart';
import '../providers/gudang_provider.dart';

/// Layar hub stock opname: daftar sesi opname dan pintu masuk memulai opname baru atau menghitung fisik.
class StockOpnameHubScreen extends ConsumerStatefulWidget {
  const StockOpnameHubScreen({super.key});

  /// Membuat state layar hub stock opname.
  @override
  ConsumerState<StockOpnameHubScreen> createState() => _StockOpnameHubScreenState();
}

/// State layar hub stock opname; memantau daftar sesi opname dan menangani navigasi ke aksi terkait.
class _StockOpnameHubScreenState extends ConsumerState<StockOpnameHubScreen> {
  /// Membuka sheet inisiasi untuk memulai sesi opname baru.
  void _openInisiasiModal() {
    final user = ref.read(authStateProvider).user;
    InisiasiOpnameSheet.show(
      context,
      initialGudangId: user?.gudang?.id,
      onSuccess: () => ref.refresh(stockOpnameListProvider),
    );
  }

  /// Membuka layar hitung fisik untuk sesi [opname], lalu memuat ulang daftar sesi setelah kembali.
  void _openHitungFisikScreen(StokOpnameSesiModel opname) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HitungFisikOpnameScreen(opname: opname),
      ),
    ).then((_) {
      ref.invalidate(stockOpnameListProvider);
      ref.invalidate(otorisasiPenyesuaianListProvider);
      ref.invalidate(bukuMutasiListProvider);
      ref.invalidate(fefoMonitoringProvider);
      ref.invalidate(daftarRakProvider);
      ref.invalidate(dashboardSummaryProvider);
    });
  }
  /// Menyusun UI hub opname: daftar sesi dengan status loading/error/kosong dan tombol mulai opname.
  @override
  Widget build(BuildContext context) {
    final opnameAsync = ref.watch(stockOpnameListProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Stock Opname Gudang'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Muat ulang',
            onPressed: () => ref.refresh(stockOpnameListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: const Text('Inisiasi Opname', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: _openInisiasiModal,
      ),
      body: SafeArea(
        child: opnameAsync.when(
          loading: () => const AppLoadingView(),
          error: (err, _) => AppErrorView(
            title: 'Gagal Memuat Sesi Opname',
            error: err,
            onRetry: () => ref.refresh(stockOpnameListProvider),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return const EmptyStateView(
                icon: LucideIcons.clipboardList,
                title: 'Belum Ada Sesi Opname',
                message: 'Tekan tombol "Inisiasi Opname" di bawah untuk membuka sesi perhitungan fisik di rak gudang.',
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.refresh(stockOpnameListProvider.future),
              child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final op = sessions[index];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
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
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(LucideIcons.clipboardCheck, color: AppColors.primaryPurple, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    op.kode,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'monospace',
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: op.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        op.gudangNama,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tanggal: ${op.tanggalOpname} • Inisiasi: ${op.petugasInisiasi}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      if (op.catatan != '-') ...[
                        const SizedBox(height: 4),
                        Text(
                          op.catatan,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      ],
                      const Divider(color: AppColors.border, height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.boxes, size: 13, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${op.totalItem} Item (${op.totalTerhitung} Terhitung)',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (op.totalSelisih > 0)
                            Text(
                              '${op.totalSelisih} Batch Selisih',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.danger),
                            )
                          else
                            const Text(
                              'Cocok (0 Selisih)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                            ),
                        ],
                      ),
                      if (op.isBerjalan) ...[
                        const SizedBox(height: 14),
                        CustomButton(
                          text: 'Buka Hitung Fisik (Blind Count)',
                          height: 40,
                          icon: const Icon(LucideIcons.scanLine, size: 16, color: Colors.white),
                          onPressed: () => _openHitungFisikScreen(op),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ));
          },
        ),
      ),
    );
  }
}
