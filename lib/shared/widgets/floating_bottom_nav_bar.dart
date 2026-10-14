import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

/// Data satu item navigasi bawah: ikon dan label.
class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.label,
  });
}

/// Bar navigasi bawah melayang dengan tombol scan QR di tengah dan empat tab.
class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isTeknisi;
  final bool isKepalaTeknisi;
  final ValueChanged<int> onTap;
  final VoidCallback onScanPressed;
  final List<BottomNavItem>? items;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    this.isTeknisi = false,
    this.isKepalaTeknisi = false,
    required this.onTap,
    required this.onScanPressed,
    this.items,
  });
  /// Membangun bar dengan tombol scan QR menonjol di tengah; tab dibagi dua sisi (separuh pertama kiri, sisanya kanan) dan jumlahnya mengikuti items (default empat tab).
  @override
  Widget build(BuildContext context) {
    final tabs = items ??
        [
          const BottomNavItem(icon: LucideIcons.home, label: 'Beranda'),
          BottomNavItem(
            icon: (isTeknisi || isKepalaTeknisi) ? LucideIcons.clipboardCheck : LucideIcons.checkSquare,
            label: isKepalaTeknisi ? 'Semua SPK' : (isTeknisi ? 'Tugas SPK' : 'Approval'),
          ),
          const BottomNavItem(icon: LucideIcons.wrench, label: 'IPSRS'),
          const BottomNavItem(icon: LucideIcons.user, label: 'Profil'),
        ];
    final split = tabs.length ~/ 2;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.floatingNav,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < split; i++)
            _buildNavItem(index: i, icon: tabs[i].icon, label: tabs[i].label),
          Transform.translate(
            offset: const Offset(0, -12),
            child: GestureDetector(
              onTap: onScanPressed,
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryHeroGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.heroCard,
                ),
                child: const Icon(
                  LucideIcons.qrCode,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
          for (var i = split; i < tabs.length; i++)
            _buildNavItem(index: i, icon: tabs[i].icon, label: tabs[i].label),
        ],
      ),
    );
  }

  /// Membangun satu tab dengan ikon dan label yang disorot beserta titik penanda saat terpilih.
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primaryPurple,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
