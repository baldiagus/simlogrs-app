import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';

/// Dropdown opsional (unit / gudang terperiksa) dengan tombol Reset dan
/// penanganan state loading/error dari data master.
class FormTerbitkanTemuanLookupDropdown<T> extends StatelessWidget {
  const FormTerbitkanTemuanLookupDropdown({
    super.key,
    required this.label,
    required this.placeholder,
    required this.errorText,
    required this.itemsAsync,
    required this.selectedId,
    required this.idOf,
    required this.namaOf,
    required this.onChanged,
  });

  final String label;
  final String placeholder;
  final String errorText;
  final AsyncValue<List<T>> itemsAsync;
  final int? selectedId;
  final int Function(T item) idOf;
  final String Function(T item) namaOf;
  final ValueChanged<int?> onChanged;

  /// Membangun dropdown master data (opsional) dengan tombol Reset serta tampilan loading/error.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.labelMedium),
            ),
            if (selectedId != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Text('Reset',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.danger)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        itemsAsync.when(
          data: (items) => DropdownButtonFormField<int?>(
            // ignore: deprecated_member_use
            value: selectedId,
            isExpanded: true,
            itemHeight: null,
            decoration: InputDecoration(
              isDense: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            items: [
              DropdownMenuItem<int?>(
                  value: null,
                  child: Text(placeholder,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))),
              ...items.map((item) => DropdownMenuItem<int?>(
                  value: idOf(item),
                  child: Text(namaOf(item),
                      style: Theme.of(context).textTheme.bodySmall))),
            ],
            onChanged: onChanged,
          ),
          loading: () => const SizedBox(
              height: 40,
              child: Center(
                  child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2)))),
          error: (_, __) => Text(errorText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger)),
        ),
      ],
    );
  }
}
