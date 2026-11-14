import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../data/models/po_model.dart';
import '../providers/pengadaan_provider.dart';

/// Pemilih vendor aktif dengan pencarian lokal; pembatalan tidak mengubah draft PO.
class PemasokPickerBottomSheet extends ConsumerStatefulWidget {
  final int? selectedPemasokId;

  const PemasokPickerBottomSheet({super.key, this.selectedPemasokId});

  @override
  ConsumerState<PemasokPickerBottomSheet> createState() =>
      _PemasokPickerBottomSheetState();
}

class _PemasokPickerBottomSheetState
    extends ConsumerState<PemasokPickerBottomSheet> {
  String _query = '';

  void _selectPemasok(int id) {
    final current = ref.read(pemasokListProvider);
    if (current.isLoading || current.hasError || id <= 0) return;
    if (current.asData?.value.any((vendor) => vendor.id == id) ?? false) {
      Navigator.of(context).pop(id);
    }
  }

  Widget _buildOptions(AsyncValue<List<PemasokOptionModel>> vendors) {
    if (vendors.isLoading) {
      return const AppLoadingView(message: 'Memuat vendor...');
    }
    if (vendors.hasError) {
      return SingleChildScrollView(
        child: AppErrorView(
          title: 'Gagal Memuat Vendor',
          error: vendors.error,
          onRetry: () => ref.invalidate(pemasokListProvider),
        ),
      );
    }
    final all = vendors.asData?.value ?? const <PemasokOptionModel>[];
    if (all.isEmpty) {
      return const SingleChildScrollView(
        child: EmptyStateView(
          title: 'Belum ada vendor aktif',
          message: 'Rekanan pemasok aktif belum tersedia.',
        ),
      );
    }
    // ponytail: daftar lengkap difilter lokal; pindah ke API jika daftar membesar.
    final filtered = all
        .where((vendor) =>
            vendor.nama.toLowerCase().contains(_query) ||
            vendor.kode.toLowerCase().contains(_query))
        .toList();
    if (filtered.isEmpty) {
      return const SingleChildScrollView(
        child: EmptyStateView(
          title: 'Vendor tidak ditemukan',
          message: 'Hapus atau ganti kata kunci pencarian.',
          icon: LucideIcons.search,
        ),
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: filtered.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final vendor = filtered[index];
          final selected = vendor.id == widget.selectedPemasokId;
          return ListTile(
            key: ValueKey('pemasok-${vendor.id}'),
            selected: selected,
            title: Text(vendor.nama),
            subtitle: Text(vendor.kode),
            trailing: selected
                ? const Tooltip(
                    message: 'Vendor terpilih',
                    child:
                        Icon(LucideIcons.check, color: AppColors.primaryPurple),
                  )
                : null,
            onTap: vendor.id > 0 ? () => _selectPemasok(vendor.id) : null,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(pemasokListProvider);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Pilih Rekanan / Vendor',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        tooltip: 'Tutup',
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppSearchBar(
                    hint: 'Cari nama atau kode vendor...',
                    onChanged: (value) {
                      if (!mounted ||
                          ModalRoute.of(context)?.isCurrent == false) {
                        return;
                      }
                      setState(() => _query = value.trim().toLowerCase());
                    },
                    onClear: () => setState(() => _query = ''),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                Expanded(child: _buildOptions(vendors)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
