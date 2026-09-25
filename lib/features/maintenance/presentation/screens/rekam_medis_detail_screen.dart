import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/rekam_medis_aset_model.dart';
import '../../data/repositories/ipsrs_repository.dart';
import '../providers/ipsrs_providers.dart';

class RekamMedisDetailScreen extends ConsumerStatefulWidget {
  final int asetId;
  final String? initialNama;

  const RekamMedisDetailScreen({
    super.key,
    required this.asetId,
    this.initialNama,
  });

  @override
  ConsumerState<RekamMedisDetailScreen> createState() => _RekamMedisDetailScreenState();
}

class _RekamMedisDetailScreenState extends ConsumerState<RekamMedisDetailScreen> {
  int _selectedTab = 0; // 0 = Rekam Servis, 1 = Jadwal Preventif

  void _confirmEksekusiJadwal(Map<String, dynamic> j) {
    final jId = j['id'] as int?;
    if (jId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terbitkan SPK Servis Preventif'),
        content: Text(
          'Terbitkan Surat Perintah Kerja (SPK) untuk agenda servis berkala "${j['jenis_maintenance']}" dan tugaskan ke ${j['teknisi']}?',
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
              try {
                final res = await ref.read(ipsrsRepositoryProvider).eksekusiPreventif(jId);
                ref.invalidate(rekamMedisDetailProvider(widget.asetId));
                ref.invalidate(jadwalPreventifListProvider);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('SPK ${res['kode_spk'] ?? ''} berhasil diterbitkan dan ditugaskan.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                );
              }
            },
            child: const Text('Terbitkan SPK Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(rekamMedisDetailProvider(widget.asetId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(widget.initialNama != null ? 'Rekam Medis: ${widget.initialNama}' : 'Rekam Medis & Preventif'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.refresh(rekamMedisDetailProvider(widget.asetId)),
          ),
        ],
      ),
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
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
                    onPressed: () => ref.refresh(rekamMedisDetailProvider(widget.asetId)),
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            final id = data.identitas;
            final riwayat = data.riwayatServis;
            final jadwal = data.jadwalPreventif;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Identitas Aset Card (Header Hero)
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                id['kode_aset']?.toString() ?? '-',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            StatusBadge(status: id['status']?.toString() ?? 'TERSEDIA'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          id['nama_sarana']?.toString() ?? 'Sarana Medis',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No. Seri: ${id['nomor_seri']} • Merek: ${id['merek']}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Lokasi: ${id['lokasi']}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${id['total_servis']}x Servis Dicatat',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2-Tab Segmented Selector
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTab = 0),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? AppColors.primaryPurple : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.activity,
                                    size: 15,
                                    color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Rekam Servis (${riwayat.length})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTab = 1),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? AppColors.primaryPurple : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.calendarClock,
                                    size: 15,
                                    color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Preventif (${jadwal.length})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Berdasarkan Tab Terpilih
                  if (_selectedTab == 0)
                    _buildRiwayatServisView(riwayat)
                  else
                    _buildJadwalPreventifView(jadwal),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRiwayatServisView(List<RekamMedisServisEntryModel> riwayat) {
    if (riwayat.isEmpty) {
      return const EmptyStateView(
        icon: LucideIcons.heartPulse,
        title: 'Sarana Dalam Kondisi Prima',
        message: 'Belum ada riwayat kerusakan fisik atau tiket perbaikan yang pernah dilaporkan untuk alat ini.',
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
                  Row(
                    children: [
                      Text(
                        item.kodeTiket,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      if (item.kodeSpk != '-') ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${item.kodeSpk})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  StatusBadge(status: item.statusTiket),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.deskripsiMasalah,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.tintTeal),
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

  Widget _buildJadwalPreventifView(List<Map<String, dynamic>> jadwalList) {
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
                  Row(
                    children: [
                      const Icon(LucideIcons.calendarClock, size: 16, color: AppColors.primaryPurple),
                      const SizedBox(width: 6),
                      Text(
                        j['kode']?.toString() ?? 'PRV',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(status: j['status']?.toString() ?? 'AKTIF'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                j['jenis_maintenance']?.toString() ?? 'Servis Berkala',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Interval: ${j['interval']}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryPurple),
              ),
              const Divider(color: AppColors.border, height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Jatuh Tempo: ${j['tanggal_berikutnya']}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(LucideIcons.user, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        j['teknisi']?.toString() ?? 'Teknisi IPSRS',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Terbitkan SPK Servis Rutin',
                height: 38,
                backgroundColor: AppColors.primaryPurple,
                icon: const Icon(LucideIcons.playCircle, size: 16, color: Colors.white),
                onPressed: () => _confirmEksekusiJadwal(j),
              ),
            ],
          ),
        );
      },
    );
  }

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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
