import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Badge jumlah kecil pada label tab hub sirkulasi.
class SirkulasiHubTabBadge extends StatelessWidget {
  /// Membuat badge dengan jumlah [count].
  const SirkulasiHubTabBadge({super.key, required this.count});

  final int count;

  /// Membangun badge jumlah; disembunyikan saat jumlah 0.
  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tintVioletBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple),
      ),
    );
  }
}

/// Tab berisi teks dan [SirkulasiHubTabBadge] pada TabBar hub sirkulasi.
class SirkulasiHubBadgeTab extends StatelessWidget {
  /// Membuat tab berlabel dengan badge jumlah.
  const SirkulasiHubBadgeTab(
      {super.key, required this.label, required this.count});

  final String label;
  final int count;

  /// Membangun Tab berisi label dan badge jumlah.
  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          SirkulasiHubTabBadge(count: count),
        ],
      ),
    );
  }
}

/// Empty state yang tetap dapat di-refresh (pull-to-refresh).
class SirkulasiHubEmptyRefreshView extends StatelessWidget {
  /// Membuat empty state dengan callback refresh dan faktor tinggi layar.
  const SirkulasiHubEmptyRefreshView({
    super.key,
    required this.onRefresh,
    required this.heightFactor,
    required this.child,
  });

  final RefreshCallback onRefresh;
  final double heightFactor;
  final Widget child;

  /// Membangun area scroll yang bisa ditarik untuk refresh dengan tinggi sebagian layar.
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * heightFactor,
          child: child,
        ),
      ),
    );
  }
}

/// Pill sub-tab perspektif pada tab Siap Kembali.
class SirkulasiHubSubTabPill extends StatelessWidget {
  /// Membuat pill sub-tab dengan judul, jumlah, status aktif, dan callback tap.
  const SirkulasiHubSubTabPill({
    super.key,
    required this.title,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  /// Membangun pill sub-tab dengan highlight saat aktif dan badge jumlah bila > 0.
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.tintVioletBg : AppColors.canvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.primaryPurple : AppColors.border,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? AppColors.primaryPurple
                      : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryPurple
                      : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
