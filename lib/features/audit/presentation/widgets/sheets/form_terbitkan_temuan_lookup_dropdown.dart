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
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            if (selectedId != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Text('Reset',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        itemsAsync.when(
          data: (items) => DropdownButtonFormField<int?>(
            // ignore: deprecated_member_use
            value: selectedId,
            isExpanded: true,
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
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted))),
              ...items.map((item) => DropdownMenuItem<int?>(
                  value: idOf(item),
                  child: Text(namaOf(item),
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis))),
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
              style: const TextStyle(fontSize: 10, color: AppColors.danger)),
        ),
      ],
    );
  }
}
