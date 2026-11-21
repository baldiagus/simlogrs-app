import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Tombol utama aplikasi dengan varian terisi/outline, ikon opsional, dan status loading.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50,
    this.isOutlined = false,
  });

  /// Memilih OutlinedButton atau ElevatedButton sesuai isOutlined; tombol dinonaktifkan saat isLoading agar tidak terkirim ganda.
  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? AppColors.primaryPurple;
    final effectiveTextColor = textColor ?? Theme.of(context).colorScheme.onPrimary;

    if (isOutlined) {
      return Container(
        width: width,
        constraints: BoxConstraints(minHeight: height),
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: effectiveBgColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _buildChild(context, effectiveBgColor),
        ),
      );
    }

    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: height),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          visualDensity: VisualDensity.compact,
          backgroundColor: effectiveBgColor,
          foregroundColor: effectiveTextColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _buildChild(context, effectiveTextColor),
      ),
    );
  }

  /// Membangun isi tombol: spinner saat loading, ikon + teks bila ada ikon, atau teks saja.
  Widget _buildChild(BuildContext context, Color color) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
    );
  }
}
