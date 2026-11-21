import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../maintenance/presentation/screens/jadwal_preventif_screen.dart';
import '../../../maintenance/presentation/screens/rekam_medis_katalog_screen.dart';
import '../../../maintenance/presentation/screens/spk_list_screen.dart';
import 'dashboard_shortcut_layout.dart';

class IpsrsShortcutGrid extends ConsumerWidget {
  const IpsrsShortcutGrid({super.key});

  /// Membangun grid pintasan IPSRS; menu disesuaikan dengan peran kepala teknisi.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final isKepalaTeknisi = user?.isKepalaTeknisi ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                isKepalaTeknisi ? 'Komando & Lapangan IPSRS' : 'Tugas Lapangan Teknisi',
                style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              isKepalaTeknisi ? 'Disposisi & Kalender' : 'Pelaksanaan Servis',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.8)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DashboardShortcutLayout(
          children: [
            _buildIpsrsMiniCard(
              context: context,
              title: isKepalaTeknisi ? 'Semua SPK' : 'Tugas SPK',
              subtitle: isKepalaTeknisi ? 'Monitoring SPK Aktif' : 'Surat Perintah Kerja',
              icon: LucideIcons.clipboardCheck,
              iconColor: AppColors.primaryPurple,
              bgColor: AppColors.tintVioletBg,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SpkListScreen(
                    allowedStatuses: isKepalaTeknisi ? null : const ['DITUGASKAN'],
                    customTitle: isKepalaTeknisi ? 'Monitoring SPK IPSRS' : 'Surat Perintah Kerja (SPK)',
                  ),
                ),
              ),
            ),
            _buildIpsrsMiniCard(
              context: context,
              title: 'Lembar Kerja',
              subtitle: 'Log fisik & suku cadang',
              icon: LucideIcons.wrench,
              iconColor: AppColors.tintOrange,
              bgColor: AppColors.tintOrangeBg,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SpkListScreen(
                    allowedStatuses: ['DITERIMA', 'SELESAI'],
                    initialStatus: 'DITERIMA',
                    customTitle: 'Lembar Kerja (SPK Aktif)',
                  ),
                ),
              ),
            ),
            _buildIpsrsMiniCard(
              context: context,
              title: 'Jadwal Preventif',
              subtitle: 'Kalender servis berkala',
              icon: LucideIcons.calendarClock,
              iconColor: AppColors.tintTeal,
              bgColor: AppColors.tintTealBg,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JadwalPreventifScreen()),
              ),
            ),
            _buildIpsrsMiniCard(
              context: context,
              title: 'Rekam Medis Aset',
              subtitle: 'Histori & kelaikan alat',
              icon: LucideIcons.stethoscope,
              iconColor: AppColors.tintBlue,
              bgColor: AppColors.tintBlueBg,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RekamMedisKatalogScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Membangun satu kartu mini pintasan IPSRS berisi ikon, judul, dan subjudul yang dapat diketuk.
  Widget _buildIpsrsMiniCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.02),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
