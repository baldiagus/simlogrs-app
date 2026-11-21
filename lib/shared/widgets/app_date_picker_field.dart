import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_formatters.dart';

/// Field pemilih tanggal yang tampil seperti input teks dan membuka dialog kalender saat diketuk.
class AppDatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String? label;
  final String hint;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  const AppDatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.label,
    this.hint = 'Pilih Tanggal',
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  /// Membuka dialog pemilih tanggal dengan rentang default 2020 hingga 5 tahun ke depan, lalu meneruskan hasilnya ke onDateSelected.
  Future<void> _pick(BuildContext context) async {
    if (!enabled) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(now.year + 5),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  /// Membangun label opsional dan kotak field yang menampilkan tanggal terpilih atau teks hint; nonaktif bila enabled=false.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 6),
        ],
        InkWell(
          onTap: enabled ? () => _pick(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? AppColors.surface : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const icon = Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: AppColors.primaryPurple,
                );
                final value = Text(
                  selectedDate != null
                      ? AppFormatters.tanggal(selectedDate)
                      : hint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selectedDate != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
                final scaledWidth = MediaQuery.textScalerOf(context).scale(120);
                if (constraints.maxWidth < scaledWidth + 26) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [icon, const SizedBox(height: 6), value],
                  );
                }
                return Row(
                  children: [
                    icon,
                    const SizedBox(width: 10),
                    Expanded(child: value),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
