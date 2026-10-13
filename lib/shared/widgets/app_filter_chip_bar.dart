import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Pasangan label tampilan dan nilai untuk satu pilihan pada AppFilterChipBar.
class AppFilterOption<T> {
  final String label;
  final T value;

  const AppFilterOption({
    required this.label,
    required this.value,
  });
}

/// Baris chip filter yang dapat digulir horizontal; satu chip aktif sesuai nilai selected.
class AppFilterChipBar<T> extends StatelessWidget {
  final List<AppFilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  const AppFilterChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  /// Membangun daftar chip dengan gaya berbeda untuk chip terpilih dan memanggil onSelected saat chip diketuk.
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: options.map((opt) {
          final isSelected = opt.value == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelected(opt.value),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryPurple : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryPurple : AppColors.border,
                  ),
                ),
                child: Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
