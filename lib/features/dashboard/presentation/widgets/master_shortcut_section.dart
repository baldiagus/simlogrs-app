import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../master/presentation/screens/master_barang_screen.dart';
import '../../../master/presentation/screens/register_aset_screen.dart';
import 'dashboard_shortcut_layout.dart';

class MasterShortcutSection extends StatelessWidget {
  const MasterShortcutSection({super.key});

  /// Membangun pintasan master dengan kolom sesuai ruang dan pembesaran teks.
  @override
  Widget build(BuildContext context) {
    return DashboardShortcutLayout(
      children: [
        _MasterShortcutCard(
          title: 'Master Barang',
          subtitle: 'Katalog BHP & stok',
          icon: LucideIcons.package,
          iconColor: AppColors.tintBlue,
          backgroundColor: AppColors.tintBlueBg,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MasterBarangScreen()),
          ),
        ),
        _MasterShortcutCard(
          title: 'Register Aset',
          subtitle: 'Inventaris fisik RS',
          icon: LucideIcons.qrCode,
          iconColor: AppColors.tintOrange,
          backgroundColor: AppColors.tintOrangeBg,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterAsetScreen()),
          ),
        ),
      ],
    );
  }
}

class _MasterShortcutCard extends StatelessWidget {
  const _MasterShortcutCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.03),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
