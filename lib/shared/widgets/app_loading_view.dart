import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Indikator loading seragam di tengah layar dengan pesan opsional.
class AppLoadingView extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? message;

  const AppLoadingView({
    super.key,
    this.size = 32,
    this.strokeWidth = 2.5,
    this.color,
    this.message,
  });

  /// Membangun spinner berukuran/berwarna sesuai parameter dan teks pesan bila diberikan.
  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primaryPurple;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: strokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
