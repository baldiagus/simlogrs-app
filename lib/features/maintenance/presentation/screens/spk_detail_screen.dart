import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/spk_model.dart';
import '../providers/maintenance_provider.dart';
import 'lembar_kerja_screen.dart';

class SpkDetailScreen extends ConsumerWidget {
  final int spkId;
  final String kodeSpk;

  const SpkDetailScreen({
    super.key,
    required this.spkId,
    required this.kodeSpk,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(spkDetailProvider(spkId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('SPK: $kodeSpk'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.invalidate(spkDetailProvider(spkId)),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (spk) {
          final isSelesai = spk.status.toUpperCase() == 'SELESAI';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
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
                                    spk.kodeSpk,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                StatusBadge(status: spk.status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              spk.aset.nama,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kode Aset: ${spk.aset.kodeAset} • Lokasi: ${spk.aset.lokasi}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Ticket Info Card
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tiket: ${spk.tiket.kode}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: spk.tiket.isCito
                                        ? const Color(0xFFFEF2F2)
                                        : (spk.tiket.isTinggi ? const Color(0xFFFFFBEB) : AppColors.tintBlueBg),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    spk.tiket.prioritas,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: spk.tiket.isCito
                                          ? AppColors.danger
                                          : (spk.tiket.isTinggi ? AppColors.warning : AppColors.tintBlue),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              spk.tiket.deskripsiMasalah,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                            ),
                            if (spk.tiket.pelapor != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Pelapor: ${spk.tiket.pelapor}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                            if (spk.tiket.fotoUrl != null && spk.tiket.fotoUrl!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  spk.tiket.fotoUrl!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                            ],
                            if (spk.instruksiKhusus != null && spk.instruksiKhusus!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.info, size: 14, color: AppColors.primaryPurple),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Instruksi: ${spk.instruksiKhusus}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Work Logs Section
                      Row(
                        children: [
                          const Icon(LucideIcons.clipboardList, size: 18, color: AppColors.primaryPurple),
                          const SizedBox(width: 8),
                          Text(
                            'Riwayat Pengerjaan & Suku Cadang (${spk.riwayatLog.length})',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (spk.riwayatLog.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Text(
                              'Belum ada lembar kerja yang dicatat untuk SPK ini.',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      else
                        ...spk.riwayatLog.map((log) => _buildLogCard(log)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom Button if not Selesai
              if (!isSelesai)
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: CustomButton(
                        width: double.infinity,
                        text: 'Catat Lembar Kerja / Suku Cadang',
                        icon: const Icon(LucideIcons.penTool, size: 18, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LembarKerjaScreen(spk: spk)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
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
                  onPressed: () => ref.invalidate(spkDetailProvider(spkId)),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(SpkLogModel log) {
    Color hasilBg = const Color(0xFFECFDF5);
    Color hasilColor = AppColors.success;
    if (log.hasil == 'PENDING') {
      hasilBg = const Color(0xFFFFFBEB);
      hasilColor = AppColors.warning;
    } else if (log.hasil == 'GAGAL') {
      hasilBg = const Color(0xFFFEF2F2);
      hasilColor = AppColors.danger;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Oleh: ${log.teknisi ?? 'Teknisi'}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: hasilBg, borderRadius: BorderRadius.circular(6)),
                child: Text(log.hasil, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: hasilColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Diagnosa: ${log.diagnosa}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Tindakan: ${log.tindakan}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          if (log.sukuCadang.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Suku Cadang Terpakai (FEFO):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  ...log.sukuCadang.map(
                    (sc) => Text(
                      '• ${sc.barang} (x${sc.jumlah})',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
