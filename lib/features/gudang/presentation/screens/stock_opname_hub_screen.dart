import '../../../../core/network/user_error_message.dart';
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
      ref.invalidate(dashboardSummaryProvider);
    });
  }
  /// Menyusun UI hub opname: daftar sesi dengan status loading/error/kosong dan tombol mulai opname.
  @override
  Widget build(BuildContext context) {
    final opnameAsync = ref.watch(stockOpnameListProvider);
    final user = ref.watch(authStateProvider).user;

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
      bottomNavigationBar: user?.canInisiasiStockOpname == true
          ? Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: CustomButton(
                    text: 'Inisiasi Opname',
                    height: 48,
                    icon: const Icon(LucideIcons.plus, size: 20, color: Colors.white),
                    onPressed: _openInisiasiModal,
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: opnameAsync.when(
          loading: () => const AppLoadingView(),
          error: (err, _) => AppErrorView(
            title: 'Gagal Memuat Sesi Opname',
            error: userErrorMessage(err, action: 'memuat sesi opname'),
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
              padding: const EdgeInsets.all(16),
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
                                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'JetBrains Mono',
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
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tanggal: ${op.tanggalOpname}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Diinisiasi oleh: ${op.petugasInisiasi}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
                      ),
                      if (op.catatan != '-') ...[
                        const SizedBox(height: 8),
                        Text(
                          'Catatan: ${op.catatan}',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      const Divider(color: AppColors.border, height: 18),
                      Wrap(
                        spacing: 24,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Total item: ${op.totalItem}',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Terhitung: ${op.totalTerhitung}',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        op.totalTerhitung == 0
                            ? 'Belum ada hasil hitung'
                            : op.totalSelisih > 0
                                ? '${op.totalSelisih} Batch Selisih'
                                : op.totalTerhitung < op.totalItem
                                    ? '0 selisih pada item terhitung'
                                    : 'Cocok (0 Selisih)',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: op.totalTerhitung == 0
                              ? AppColors.textSecondary
                              : op.totalSelisih > 0
                                  ? AppColors.danger
                                  : op.totalTerhitung < op.totalItem
                                      ? AppColors.textSecondary
                                      : AppColors.success,
                        ),
                      ),
                      if (op.isBerjalan) ...[
                        const SizedBox(height: 14),
                        CustomButton(
                          text: 'Buka Hitung Fisik (Blind Count)',
                          height: 48,
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
