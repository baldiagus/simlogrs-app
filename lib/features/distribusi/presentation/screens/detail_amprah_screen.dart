import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/distribusi_provider.dart';

class DetailAmprahScreen extends ConsumerWidget {
  final int amprahId;
  final String kodeAmprah;

  const DetailAmprahScreen({
    super.key,
    required this.amprahId,
    required this.kodeAmprah,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(detailAmprahProvider(amprahId));
    final actionState = ref.watch(amprahActionProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Amprah: $kodeAmprah'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        const SizedBox(height: 4),
                        Text(
                          'Tgl: ${amprah.tanggalPermintaan} • Oleh ${amprah.pengaju}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gudang Tujuan: ${amprah.gudang}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

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
                          'Progres Persetujuan 2 Meja:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        _buildStepRow(
                          title: 'Meja 1: Otorisasi Kepala Ruangan (Karu)',
                          subtitle: amprah.isDiajukan
                              ? 'Menunggu persetujuan Karu'
                              : (amprah.isDitolak ? 'Ditolak' : 'Disetujui Karu'),
                          isPassed: !amprah.isDiajukan && !amprah.isDitolak,
                          isCurrent: amprah.isDiajukan,
                        ),
                        const SizedBox(height: 10),
                        _buildStepRow(
                          title: 'Meja 2: Otorisasi Gudang Logistik',
                          subtitle: amprah.isDisetujuiKaru
                              ? 'Menunggu verifikasi stok gudang'
                              : (amprah.isDisetujuiGudang || amprah.isSelesai
                                  ? 'Disetujui untuk pengeluaran barang'
                                  : '-'),
                          isPassed: amprah.isDisetujuiGudang || amprah.isSelesai,
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
                      Text(
                        'Rincian Komoditas Diminta (${amprah.items.length} Item)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? (s.successMessage ?? 'Dibatalkan') : (s.errorMessage ?? 'Gagal')),
                            backgroundColor: ok ? AppColors.success : AppColors.danger,
                          ),
                        );
                        if (ok) {
                          ref.invalidate(detailAmprahProvider(amprahId));
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
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle, size: 40, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(
                  err.toString().replaceAll('ApiException: ', ''),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => ref.invalidate(detailAmprahProvider(amprahId)),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
