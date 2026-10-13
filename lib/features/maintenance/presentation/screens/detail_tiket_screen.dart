import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/tiket_maintenance_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/maintenance_provider.dart';
import '../widgets/disposisi_spk_sheet.dart';

class DetailTiketScreen extends ConsumerWidget {
  final int tiketId;
  final String kodeTiket;

  /// Membuat DetailTiketScreen.
  const DetailTiketScreen({
    super.key,
    required this.tiketId,
    required this.kodeTiket,
  });

  /// Warna teks/ikon badge sesuai prioritas tiket.
  Color _getPrioritasColor(String p) {
    switch (p.toUpperCase()) {
      case 'CITO':
        return AppColors.danger;
      case 'TINGGI':
        return AppColors.warning;
      case 'SEDANG':
        return AppColors.tintBlue;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Warna latar badge sesuai prioritas tiket.
  Color _getPrioritasBg(String p) {
    switch (p.toUpperCase()) {
      case 'CITO':
        return const Color(0xFFFEF2F2);
      case 'TINGGI':
        return const Color(0xFFFFFBEB);
      case 'SEDANG':
        return AppColors.tintBlueBg;
      default:
        return AppColors.surfaceSecondary;
    }
  }

  /// Membangun tampilan DetailTiketScreen.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(detailTiketUnitProvider(tiketId));
    final actionState = ref.watch(tiketActionProvider);
    final user = ref.watch(authStateProvider).user;
    final canDisposisi = (user?.isKepalaTeknisi == true) || (user?.isAdminLogistik == true) || (user?.hasRole('super_admin') == true);
    final isTeknisi = (user?.isTeknisi == true) || (user?.isKepalaTeknisi == true);
    return Scaffold(
      appBar: AppBar(
        title: Text('Tiket: $kodeTiket'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.invalidate(detailTiketUnitProvider(tiketId)),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (tiket) {
          final pColor = _getPrioritasColor(tiket.prioritas);
          final pBg = _getPrioritasBg(tiket.prioritas);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Header
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
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tiket.kode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            StatusBadge(status: tiket.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tiket.namaAset,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kode: ${tiket.kodeAset} • SN: ${tiket.nomorSeri}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detail Laporan Card
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
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Text(
                              'Dilaporkan: ${tiket.dibuatPada ?? '-'}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: pBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Prioritas: ${tiket.prioritas}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: pColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Deskripsi Kerusakan Fisik:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tiket.deskripsiMasalah,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Pelapor: ${tiket.pelapor} (${tiket.unit})',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        if (tiket.fotoUrl != null && tiket.fotoUrl!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 10),
                          const Text(
                            'Foto Bukti Kerusakan:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              tiket.fotoUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                final expected = loadingProgress.expectedTotalBytes;
                                final loaded = loadingProgress.cumulativeBytesLoaded;
                                final progress = (expected != null && expected > 0) ? loaded / expected : null;
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: AppColors.surfaceSecondary,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      color: AppColors.primaryPurple,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.imageOff, size: 28, color: AppColors.textMuted),
                                    SizedBox(height: 6),
                                    Text(
                                      'Foto tidak dapat dimuat',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tracking Penugasan Teknisi IPSRS Card
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
                        const Row(
                          children: [
                            Icon(LucideIcons.wrench, size: 16, color: AppColors.primaryPurple),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Disposisi & Penugasan Teknisi',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (tiket.penugasan.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(LucideIcons.clock, size: 16, color: AppColors.textSecondary),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tiket sedang menunggu disposisi SPK dari Koordinator IPSRS.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canDisposisi && (tiket.status == 'DILAPORKAN' || tiket.status == 'MENUNGGU_SPK')) ...[
                            const SizedBox(height: 10),
                            CustomButton(
                              width: double.infinity,
                              text: 'Disposisi SPK ke Teknisi',
                              icon: const Icon(LucideIcons.wrench, size: 16, color: Colors.white),
                              onPressed: () async {
                                final created = await DisposisiSpkSheet.show(
                                  context,
                                  tiketId: tiket.id,
                                  kodeTiket: tiket.kode,
                                  namaAset: tiket.aset['nama']?.toString() ?? 'Sarana Medis',
                                  unitPelapor: tiket.unit,
                                  prioritas: tiket.prioritas,
                                  keluhan: tiket.deskripsiMasalah,
                                );
                                if (created == true) {
                                  ref.invalidate(detailTiketUnitProvider(tiketId));
                                  ref.invalidate(daftarTiketUnitProvider);
                                  ref.invalidate(spkListProvider);
                                  ref.invalidate(dashboardSummaryProvider);
                                }
                              },
                            ),
                          ],
                        ]
                        else
                          ...tiket.penugasan.map((spk) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SPK: ${spk['kode_spk'] ?? '-'}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        'Teknisi: ${spk['teknisi'] ?? '-'}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  StatusBadge(status: spk['status']?.toString() ?? 'DITUGASKAN'),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Catatan Lembar Kerja Pengerjaan
                  if (tiket.riwayatLog.isNotEmpty) ...[
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
                          const Row(
                            children: [
                              Icon(LucideIcons.clipboardCheck, size: 16, color: AppColors.success),
                              SizedBox(width: 8),
                              Text(
                                'Catatan Pengerjaan Teknisi',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...tiket.riwayatLog.map((log) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${log['tanggal'] ?? '-'} • ${log['teknisi'] ?? '-'}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                      StatusBadge(status: log['hasil']?.toString() ?? 'BERHASIL'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tindakan: ${log['tindakan'] ?? '-'}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Tombol Batalkan Tiket (Hanya jika DILAPORKAN dan canCancel)
                  // Tombol Batalkan Tiket (Hanya jika DILAPORKAN, canCancel dan bukan role teknisi/IPSRS)
                  if (tiket.canCancel && !canDisposisi && !isTeknisi) ...[
                    CustomButton(
                      text: 'Batalkan Tiket Kerusakan',
                      backgroundColor: const Color(0xFFFEF2F2),
                      textColor: AppColors.danger,
                      icon: const Icon(LucideIcons.x, size: 18, color: AppColors.danger),
                      isLoading: actionState.isLoading,
                      onPressed: () async {
                        final ok = await ref.read(tiketActionProvider.notifier).batalkanTiket(tiket.id);
                        if (!context.mounted) return;
                        final s = ref.read(tiketActionProvider);
                        if (ok) {
                          AppToast.success(context, s.successMessage ?? 'Dibatalkan');
                        } else {
                          AppToast.error(context, s.errorMessage ?? 'Gagal');
                        }
                        if (ok) {
                          ref.invalidate(detailTiketUnitProvider(tiketId));
                          ref.invalidate(daftarTiketUnitProvider);
                          ref.invalidate(dashboardSummaryProvider);
                        }
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
          title: 'Gagal Memuat Detail Tiket',
          error: err,
          onRetry: () => ref.invalidate(detailTiketUnitProvider(tiketId)),
        ),
      ),
    );
  }
}
