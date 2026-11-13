import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../data/models/rak_model.dart';
import '../providers/gudang_provider.dart';

/// Pemilih rak aktif dari gudang penerima, dengan pencarian lokal sementara.
class RakPickerBottomSheet extends ConsumerStatefulWidget {
  final int gudangId;
  final String namaGudang;
  final int? selectedRackId;

  const RakPickerBottomSheet({
    super.key,
    required this.gudangId,
    required this.namaGudang,
    this.selectedRackId,
  });

  @override
  ConsumerState<RakPickerBottomSheet> createState() => _RakPickerBottomSheetState();
}

class _RakPickerBottomSheetState extends ConsumerState<RakPickerBottomSheet> {
  String _query = '';

  void _selectRack(int id) {
    final current = ref.read(rakPenerimaanProvider(widget.gudangId));
    if (current.isLoading || current.hasError) return;
    for (final rack in current.asData?.value ?? const <RakModel>[]) {
      if (rack.id == id && rack.gudangId == widget.gudangId && rack.status == 'AKTIF') {
        Navigator.of(context).pop<RakModel>(rack);
        return;
      }
    }
  }

  String _warehouseName(RakModel rack) {
    final name = rack.namaGudang.trim();
    if ((name.isEmpty || name == '-') && rack.gudangId == widget.gudangId) {
      return widget.namaGudang;
    }
    return name;
  }

  Widget _buildOptions(AsyncValue<List<RakModel>> racks) {
    if (racks.isLoading) {
      return const AppLoadingView(message: 'Memuat rak...');
    }
    if (racks.hasError) {
      return SingleChildScrollView(
        child: AppErrorView(
          title: 'Gagal Memuat Rak',
          error: racks.error,
          onRetry: () => ref.invalidate(rakPenerimaanProvider(widget.gudangId)),
        ),
      );
    }
    final all = racks.asData?.value ?? const <RakModel>[];
    if (all.isEmpty) {
      return const SingleChildScrollView(
        child: EmptyStateView(
          title: 'Tidak ada rak aktif di gudang penerima.',
          message: 'Rak aktif untuk gudang ini belum tersedia.',
        ),
      );
    }
    final filtered = all.where((rack) =>
      rack.kode.toLowerCase().contains(_query) ||
      rack.nama.toLowerCase().contains(_query),
    ).toList();
    if (filtered.isEmpty) {
      return const SingleChildScrollView(
        child: EmptyStateView(
          title: 'Rak Tidak Ditemukan',
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
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final rack = filtered[index];
          final selected = rack.id == widget.selectedRackId;
          return ListTile(
            key: ValueKey('rak-${rack.id}'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            selected: selected,
            title: Text('${rack.kode} (${rack.nama})'),
            subtitle: Text('Gudang: ${_warehouseName(rack)}'),
            trailing: selected
                ? const Tooltip(
                    message: 'Rak terpilih',
                    child: Icon(LucideIcons.check, color: AppColors.primaryPurple),
                  )
                : null,
            onTap: () => _selectRack(rack.id),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final racks = ref.watch(rakPenerimaanProvider(widget.gudangId));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pilih Rak Simpan', style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            )),
                            const SizedBox(height: 4),
                            Text('Gudang Penerima: ${widget.namaGudang}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
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
                    hint: 'Cari kode atau nama rak...',
                    onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                    onClear: () => setState(() => _query = ''),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                Expanded(child: _buildOptions(racks)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
