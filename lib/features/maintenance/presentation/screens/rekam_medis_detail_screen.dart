import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../widgets/rekam_medis_tabs.dart';
import '../../data/repositories/ipsrs_repository.dart';
import '../providers/ipsrs_providers.dart';
import '../providers/maintenance_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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

  Future<void> _confirmEksekusiJadwal(Map<String, dynamic> j) async {
    final jId = j['id'] as int?;
    if (jId == null) return;

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Terbitkan SPK Servis Preventif',
      message:
          'Terbitkan Surat Perintah Kerja (SPK) untuk agenda servis berkala "${j['jenis_maintenance']}" dan tugaskan ke ${j['teknisi']}?',
      confirmLabel: 'Terbitkan SPK Sekarang',
      icon: LucideIcons.calendarCheck,
    );
    if (!confirmed || !mounted) return;
    try {
      final res = await ref.read(ipsrsRepositoryProvider).eksekusiPreventif(jId);
      if (!mounted) return;
      ref.invalidate(rekamMedisDetailProvider(widget.asetId));
      ref.invalidate(jadwalPreventifListProvider);
      ref.invalidate(spkListProvider);
      ref.invalidate(dashboardSummaryProvider);
      AppToast.success(context, 'SPK ${res['kode_spk'] ?? ''} berhasil diterbitkan dan ditugaskan.');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(rekamMedisDetailProvider(widget.asetId));
    final user = ref.watch(authStateProvider).user;
    final canTerbitkanSpk = (user?.isTeknisi == true) ||
        (user?.isKepalaTeknisi == true) ||
        (user?.isAdminLogistik == true) ||
        (user?.hasRole('super_admin') == true);
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
          loading: () => const AppLoadingView(),
          error: (err, _) => AppErrorView(
            error: err,
            onRetry: () => ref.refresh(rekamMedisDetailProvider(widget.asetId)),
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
                            Flexible(
                              child: Container(
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
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
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
                                  Flexible(
                                    child: Text(
                                      'Rekam Servis (${riwayat.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                  Flexible(
                                    child: Text(
                                      'Preventif (${jadwal.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                    RekamMedisRiwayatServisList(riwayat: riwayat)
                  else
                    RekamMedisJadwalPreventifList(
                      jadwalList: jadwal,
                      canTerbitkanSpk: canTerbitkanSpk,
                      onEksekusi: _confirmEksekusiJadwal,
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

}
