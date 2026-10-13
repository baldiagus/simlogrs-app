import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/rekam_medis_aset_model.dart';

class RekamMedisRiwayatServisList extends StatelessWidget {
  final List<RekamMedisServisEntryModel> riwayat;

  /// Membuat RekamMedisRiwayatServisList.
  const RekamMedisRiwayatServisList({super.key, required this.riwayat});

  /// Baris label-nilai pada timeline riwayat servis.
  Widget _buildTimelineRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  /// Membangun tampilan RekamMedisRiwayatServisList.
  @override
  Widget build(BuildContext context) {
    if (riwayat.isEmpty) {
      return const EmptyStateView(
        icon: LucideIcons.heartPulse,
        title: 'Sarana Dalam Kondisi Prima',
        message:
            'Belum ada riwayat kerusakan fisik atau tiket perbaikan yang pernah dilaporkan untuk alat ini.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: riwayat.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final item = riwayat[idx];

        return Container(
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
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.kodeTiket,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: AppColors.primaryPurple,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.kodeSpk != '-') ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '(${item.kodeSpk})',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: item.statusTiket),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.deskripsiMasalah,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Dilaporkan: ${item.tanggalLapor} oleh ${item.pelapor}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const Divider(color: AppColors.border, height: 18),
              _buildTimelineRow('Teknisi Penanganan', item.teknisi),
              if (item.diagnosa != '-') ...[
                const SizedBox(height: 6),
                _buildTimelineRow('Diagnosa Kerusakan', item.diagnosa),
              ],
              if (item.tindakan != '-') ...[
                const SizedBox(height: 6),
                _buildTimelineRow('Tindakan Perbaikan', item.tindakan),
              ],
              if (item.hasilPengerjaan != '-') ...[
                const SizedBox(height: 6),
                _buildTimelineRow('Hasil Uji Fungsi', item.hasilPengerjaan),
              ],
              if (item.sukuCadang.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.tintTealBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.wrench, size: 14, color: AppColors.tintTeal),
                          SizedBox(width: 6),
                          Text(
                            'Suku Cadang Terpasang:',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.tintTeal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      for (final sc in item.sukuCadang)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '• ${sc.namaBarang} (${sc.jumlah} unit, Batch: ${sc.nomorBatch})',
                            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class RekamMedisJadwalPreventifList extends StatelessWidget {
  final List<Map<String, dynamic>> jadwalList;
  final bool canTerbitkanSpk;
  final ValueChanged<Map<String, dynamic>> onEksekusi;

  /// Membuat RekamMedisJadwalPreventifList.
  const RekamMedisJadwalPreventifList({
    super.key,
    required this.jadwalList,
    required this.canTerbitkanSpk,
    required this.onEksekusi,
  });

  /// Membangun tampilan RekamMedisJadwalPreventifList.
  @override
  Widget build(BuildContext context) {
    if (jadwalList.isEmpty) {
      return const EmptyStateView(
        icon: LucideIcons.calendarCheck,
        title: 'Belum Ada Jadwal Preventif',
        message: 'Alat ini belum memiliki agenda servis preventif berkala terdaftar di sistem.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jadwalList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final j = jadwalList[idx];

        return Container(
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
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendarClock,
                            size: 16, color: AppColors.primaryPurple),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            j['kode']?.toString() ?? 'PRV',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: j['status']?.toString() ?? 'AKTIF'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                j['jenis_maintenance']?.toString() ?? 'Servis Berkala',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Interval: ${j['interval']}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryPurple),
              ),
              const Divider(color: AppColors.border, height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(LucideIcons.clock, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Jatuh Tempo: ${j['tanggal_berikutnya']}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.user, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            j['teknisi']?.toString() ?? 'Teknisi IPSRS',
                            style:
                                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (canTerbitkanSpk) ...[
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Terbitkan SPK Servis Rutin',
                  height: 38,
                  backgroundColor: AppColors.primaryPurple,
                  icon: const Icon(LucideIcons.playCircle, size: 16, color: Colors.white),
                  onPressed: () => onEksekusi(j),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
