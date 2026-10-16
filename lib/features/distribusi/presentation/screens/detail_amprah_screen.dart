import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/distribusi_provider.dart';
import '../widgets/amprah_approval_modal.dart';

class DetailAmprahScreen extends ConsumerWidget {
  final int amprahId;
  final String kodeAmprah;

  const DetailAmprahScreen({
    super.key,
    required this.amprahId,
    required this.kodeAmprah,
  });

  /// Membangun halaman detail amprah: info permintaan, linimasa status, daftar barang, dan aksi sesuai peran.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(detailAmprahProvider(amprahId));
    final actionState = ref.watch(amprahActionProvider);
    final user = ref.watch(authStateProvider).user;
    final canPick = user?.canPickingDistribusi ?? false;
    final canMeja1 = user?.canApproveAmprahMeja1 ?? false;
    final canMeja2 = user?.canApproveAmprahMeja2 ?? false;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Amprah: $kodeAmprah'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Muat ulang',
            onPressed: () => ref.invalidate(detailAmprahProvider(amprahId)),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (amprah) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Header Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryHeroGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                amprah.kode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            StatusBadge(status: amprah.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          amprah.unit,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.user, size: 13, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      amprah.pengaju,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(LucideIcons.calendar, size: 13, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppFormatters.tanggalString(amprah.tanggalPermintaan),
                                    style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(LucideIcons.warehouse, size: 13, color: Colors.white70),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Tujuan: ${amprah.gudang}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Banner Pengiriman Sebagian (Backorder)
                  if (amprah.isDikirimSebagian) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.clock, size: 18, color: AppColors.warning),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Permintaan ini telah dikirim sebagian. Sisa barang yang terhutang akan diprioritaskan saat restok gudang.',
                              style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Tracking Progres Meja Otorisasi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tahapan Persetujuan:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        _buildStepRow(
                          title: 'Tahap 1: Persetujuan Kepala Ruangan (Karu)',
                          subtitle: amprah.isDiajukan
                              ? 'Menunggu persetujuan Karu'
                              : amprah.isDitolak
                                  ? 'Ditolak'
                                  : 'Disetujui Karu',
                          isPassed: amprah.isTahapKaruSelesai,
                          isCurrent: amprah.isDiajukan,
                        ),
                        const SizedBox(height: 10),
                        _buildStepRow(
                          title: 'Tahap 2: Otorisasi Gudang Logistik',
                          subtitle: amprah.isDisetujuiKaru
                              ? 'Menunggu verifikasi stok gudang'
                              : (amprah.isDikirimSebagian
                                  ? 'Disetujui Sebagian (Pengiriman Bertahap)'
                                  : (amprah.isDisetujuiGudang || amprah.isSedangDikirim || amprah.isSelesai
                                      ? 'Disetujui untuk pengeluaran barang'
                                      : '-')),
                          isPassed: amprah.isDisetujuiGudang || amprah.isSedangDikirim || amprah.isSelesai || amprah.isDikirimSebagian,
                          isCurrent: amprah.isDisetujuiKaru,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Catatan Pengajuan if any
                  if (amprah.catatan != null && amprah.catatan!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Catatan Kebutuhan Ruangan:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            amprah.catatan!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Items List Section
                  Row(
                    children: [
                      const Icon(LucideIcons.boxes, size: 18, color: AppColors.primaryPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rincian Komoditas Diminta (${amprah.items.length} Item)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ...amprah.items.map((d) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.namaBarang,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  d.kodeBarang,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${d.jumlahDiminta} ${d.satuan}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              if (d.jumlahDisetujui != d.jumlahDiminta)
                                Text(
                                  'Acc: ${d.jumlahDisetujui}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.tintBlue, fontWeight: FontWeight.w700),
                                ),
                              if (d.jumlahDikirim > 0 || amprah.isDikirimSebagian) ...[
                                Text(
                                  'Terkirim: ${d.jumlahDikirim}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                                ),
                                if (d.sisaBackorder > 0)
                                  Text(
                                    'Sisa: ${d.sisaBackorder}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  // Tombol Keputusan Persetujuan Meja 1 / Meja 2
                  if ((canMeja1 && amprah.isDiajukan) || (canMeja2 && amprah.isDisetujuiKaru)) ...[
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Tolak',
                            backgroundColor: const Color(0xFFFEF2F2),
                            textColor: AppColors.danger,
                            icon: const Icon(LucideIcons.x, size: 18, color: AppColors.danger),
                            isLoading: actionState.isLoading,
                            onPressed: () async {
                              final res = await AmprahApprovalModal.show(
                                context,
                                amprah: amprah,
                                isSetujui: false,
                              );
                              if (res == true) {
                                ref.invalidate(detailAmprahProvider(amprahId));
                                ref.invalidate(daftarAmprahProvider);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Setujui',
                            backgroundColor: AppColors.success,
                            textColor: Colors.white,
                            icon: const Icon(LucideIcons.checkCheck, size: 18, color: Colors.white),
                            isLoading: actionState.isLoading,
                            onPressed: () async {
                              final res = await AmprahApprovalModal.show(
                                context,
                                amprah: amprah,
                                isSetujui: true,
                              );
                              if (res == true) {
                                ref.invalidate(detailAmprahProvider(amprahId));
                                ref.invalidate(daftarAmprahProvider);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Tombol Eksekusi Picking FEFO (Khusus Petugas / Kepala Gudang)
                  if (canPick &&
                      (amprah.status == 'DISETUJUI_GUDANG' ||
                          amprah.status == 'DIKIRIM_SEBAGIAN')) ...[
                    CustomButton(
                      text: 'Eksekusi Picking FEFO & Terbitkan SPPB',
                      height: 44,
                      backgroundColor: AppColors.primaryPurple,
                      icon: const Icon(LucideIcons.arrowRightCircle, size: 18, color: Colors.white),
                      isLoading: actionState.isLoading,
                      onPressed: () async {
                        final confirmed = await AppConfirmDialog.show(
                          context,
                          title: 'Konfirmasi Picking FEFO',
                          message:
                              'Alokasikan stok batch FEFO gudang dan terbitkan dokumen pengiriman SPPB untuk ${amprah.kode}?',
                          confirmLabel: 'Ya, Eksekusi Picking',
                          confirmColor: AppColors.primaryPurple,
                          icon: LucideIcons.arrowRightCircle,
                        );
                        if (!confirmed || !context.mounted) return;

                        final notifier = ref.read(amprahActionProvider.notifier);
                        final ok = await notifier.eksekusiPicking(amprah.id);
                        if (!context.mounted) return;
                        final s = ref.read(amprahActionProvider);
                        if (ok) {
                          AppToast.success(context, s.successMessage ?? 'Picking FEFO berhasil. SPPB telah diterbitkan.');
                          ref.invalidate(detailAmprahProvider(amprahId));
                          ref.invalidate(daftarAmprahProvider);
                          ref.invalidate(antreanPickingProvider);
                          ref.invalidate(sppbInboundProvider);
                        } else {
                          AppToast.error(context, s.errorMessage ?? 'Gagal mengeksekusi picking');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Tombol Tutup Sisa Hutang bila ada sisa backorder dan status DIKIRIM_SEBAGIAN
                  if (amprah.canTutupSisa) ...[
                    CustomButton(
                      text: 'Tutup Sisa Hutang',
                      backgroundColor: const Color(0xFFFFFBEB),
                      textColor: const Color(0xFFB45309),
                      icon: const Icon(LucideIcons.checkCheck, size: 18, color: Color(0xFFB45309)),
                      isLoading: actionState.isLoading,
                      onPressed: () async {
                        final confirmed = await AppConfirmDialog.show(
                          context,
                          title: 'Tutup Sisa Hutang Amprah',
                          message:
                              'Sisa barang yang belum terkirim tidak akan dikirim lagi dan permohonan dinyatakan selesai.',
                          confirmLabel: 'Ya, Tutup Sisa Hutang',
                          confirmColor: AppColors.primaryPurple,
                          icon: LucideIcons.checkCheck,
                        );
                        if (!confirmed || !context.mounted) return;

                        final ok = await ref
                            .read(amprahActionProvider.notifier)
                            .tutupSisaAmprah(amprah.id);
                        if (!context.mounted) return;
                        final s = ref.read(amprahActionProvider);
                        if (ok) {
                          AppToast.success(
                            context,
                            s.successMessage ?? 'Sisa barang terhutang telah ditutup.',
                          );
                          ref.invalidate(detailAmprahProvider(amprahId));
                          ref.invalidate(daftarAmprahProvider);
                        } else {
                          AppToast.error(context, s.errorMessage ?? 'Gagal menutup sisa amprah');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Batal Action button if canCancel
                  if (amprah.canCancel) ...[
                    CustomButton(
                      text: 'Batalkan Permintaan Amprah',
                      backgroundColor: const Color(0xFFFEF2F2),
                      textColor: AppColors.danger,
                      icon: const Icon(LucideIcons.x, size: 18, color: AppColors.danger),
                      isLoading: actionState.isLoading,
                      onPressed: () async {
                        final ok = await ref.read(amprahActionProvider.notifier).batalkanAmprah(amprah.id);
                        if (!context.mounted) return;
                        final s = ref.read(amprahActionProvider);
                        if (ok) {
                          AppToast.success(context, s.successMessage ?? 'Dibatalkan');
                        } else {
                          AppToast.error(context, s.errorMessage ?? 'Gagal');
                        }
                        ref.invalidate(detailAmprahProvider(amprahId));
                        ref.invalidate(daftarAmprahProvider);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          title: 'Gagal Memuat Detail Amprah',
          error: err,
          onRetry: () => ref.invalidate(detailAmprahProvider(amprahId)),
        ),
      ),
    );
  }

  /// Membuat satu baris langkah linimasa status amprah dengan ikon dan warna sesuai kondisi (lewat/aktif/belum).
  Widget _buildStepRow({
    required String title,
    required String subtitle,
    required bool isPassed,
    required bool isCurrent,
  }) {
    Color circleColor = AppColors.surfaceSecondary;
    Color iconColor = AppColors.textMuted;
    IconData icon = LucideIcons.circle;

    if (isPassed) {
      circleColor = AppColors.tintVioletBg;
      iconColor = AppColors.primaryPurple;
      icon = LucideIcons.checkCircle2;
    } else if (isCurrent) {
      circleColor = const Color(0xFFFFFBEB);
      iconColor = AppColors.warning;
      icon = LucideIcons.clock;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
