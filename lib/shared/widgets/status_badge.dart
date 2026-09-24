import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color? customColor;

  const StatusBadge({
    super.key,
    required this.status,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, text) = _resolveColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: customColor?.withValues(alpha: 0.12) ?? bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatStatus(status),
        style: TextStyle(
          color: customColor ?? text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  (Color bg, Color text) _resolveColors(String s) {
    final upper = s.toUpperCase();
    if (upper.contains('SETUJU') ||
        upper.contains('SELESAI') ||
        upper.contains('TERSEDIA') ||
        upper.contains('BERHASIL') ||
        upper.contains('VALID') ||
        upper == 'BAIK') {
      return (const Color(0xFFECFDF5), AppColors.success);
    }

    if (upper.contains('TOLAK') ||
        upper.contains('GAGAL') ||
        upper.contains('RUSAK') ||
        upper.contains('CITO') ||
        upper.contains('OVERDUE')) {
      return (const Color(0xFFFEF2F2), AppColors.danger);
    }

    if (upper.contains('DIAJUKAN') ||
        upper.contains('MENUNGGU') ||
        upper.contains('PENDING') ||
        upper.contains('PROSES') ||
        upper.contains('PINJAM') ||
        upper.contains('MAINTENANCE')) {
      return (const Color(0xFFFFFBEB), AppColors.warning);
    }

    return (AppColors.surfaceSecondary, AppColors.textSecondary);
  }

  String _formatStatus(String s) {
    return s.replaceAll('_', ' ');
  }
}
