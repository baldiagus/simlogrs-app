import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

/// Kolom pencarian seragam dengan ikon cari dan tombol hapus yang muncul saat ada teks.
class AppSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  /// Jeda sebelum onChanged dipanggil setelah pengetikan berhenti; Duration.zero berarti langsung.
  final Duration debounce;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hint = 'Cari...',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.debounce = const Duration(milliseconds: 300),
  });

  /// Membuat state yang mengelola controller pencarian.
  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

/// State yang memakai controller dari luar bila ada, atau membuat dan membuang controller sendiri.
class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _ctrl;
  bool _ownsController = false;
  Timer? _debounceTimer;

  /// Menentukan controller: pakai milik parent bila diberikan, jika tidak buat sendiri dan tandai sebagai miliknya.
  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _ctrl = widget.controller!;
    } else {
      _ctrl = TextEditingController();
      _ownsController = true;
    }
  }

  /// Membuang controller hanya bila dibuat sendiri; controller dari parent menjadi tanggung jawab parent.
  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_ownsController) {
      _ctrl.dispose();
    }
    super.dispose();
  }

  /// Menunda pemanggilan onChanged sebesar debounce; timer sebelumnya dibatalkan. Duration.zero memanggil langsung.
  void _handleChanged(String text) {
    _debounceTimer?.cancel();
    if (widget.debounce == Duration.zero) {
      widget.onChanged?.call(text);
      return;
    }
    _debounceTimer = Timer(widget.debounce, () => widget.onChanged?.call(text));
  }

  /// Mengosongkan teks, membatalkan debounce tertunda, lalu memanggil onChanged('') dan onClear segera.
  void _handleClear() {
    _debounceTimer?.cancel();
    _ctrl.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  /// Membangun TextField yang rebuild saat teks berubah agar tombol hapus tampil/hilang; tombol hapus mengosongkan teks dan memanggil onChanged/onClear.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _ctrl,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;
        return TextField(
          controller: _ctrl,
          autofocus: widget.autofocus,
          onChanged: _handleChanged,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 40),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            suffixIcon: hasText
                ? IconButton(
                    icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
                    tooltip: 'Hapus teks',
                    onPressed: _handleClear,
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
            ),
          ),
        );
      },
    );
  }
}
