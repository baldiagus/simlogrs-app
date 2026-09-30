import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/core/utils/app_formatters.dart';
import 'package:simlog_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/gudang/data/repositories/persediaan_repository.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/persediaan_providers.dart';
import 'package:simlog_mobile/shared/widgets/app_bottom_sheet_wrapper.dart';
import 'package:simlog_mobile/shared/widgets/app_toast.dart';
import 'package:simlog_mobile/shared/widgets/app_date_picker_field.dart';
import 'package:simlog_mobile/shared/widgets/custom_button.dart';

class InisiasiOpnameSheet extends ConsumerStatefulWidget {
  final int? initialGudangId;
  final VoidCallback? onSuccess;

  const InisiasiOpnameSheet({
    super.key,
    this.initialGudangId,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    int? initialGudangId,
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InisiasiOpnameSheet(
        initialGudangId: initialGudangId,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<InisiasiOpnameSheet> createState() => _InisiasiOpnameSheetState();
}

class _InisiasiOpnameSheetState extends ConsumerState<InisiasiOpnameSheet> {
  int? _selectedGudangId;
  DateTime _tanggalOpname = DateTime.now();
  final TextEditingController _catatanController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedGudangId = widget.initialGudangId;
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<GudangModel> gudangs) async {
    if (_selectedGudangId == null) {
      AppToast.error(context, 'Fasilitas gudang wajib dipilih terlebih dahulu.');
      return;
    }

    final selectedId = _selectedGudangId;
    final selectedGudang = gudangs.firstWhere(
      (g) => g.id == selectedId,
      orElse: () => gudangs.first,
    );
    if (selectedGudang.activeBatchesCount == 0) {
      AppToast.error(context, 'Fasilitas "${selectedGudang.nama}" belum memiliki stok batch aktif untuk dihitung opname.');
      return;
    }
    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);

    try {
      await ref.read(persediaanRepositoryProvider).inisiasiOpname(
            gudangId: _selectedGudangId!,
            tanggalOpname: AppFormatters.tanggalDb(_tanggalOpname),
            catatan: _catatanController.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(stockOpnameListProvider);
      ref.invalidate(dashboardSummaryProvider);
      AppToast.success(context, 'Sesi Stock Opname berhasil diinisiasi.');
      navigator.pop();
      widget.onSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetWrapper(
      title: 'Inisiasi Sesi Stock Opname',
      subtitle: 'Sistem akan mengunci snapshot saldo seluruh batch aktif di fasilitas gudang ini.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Fasilitas Gudang:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ref.watch(masterGudangListProvider).when(
                data: (gudangs) {
                  final availableIds = gudangs.map((g) => g.id).toList();
                  if (_selectedGudangId == null || !availableIds.contains(_selectedGudangId)) {
                    final withStock = gudangs.where((g) => (g.activeBatchesCount ?? 0) > 0);
                    if (withStock.isNotEmpty) {
                      _selectedGudangId = withStock.first.id;
                    } else if (availableIds.contains(1)) {
                      _selectedGudangId = 1;
                    } else {
                      _selectedGudangId = gudangs.isNotEmpty ? gudangs.first.id : 1;
                    }
                  }
                  final selectedGudang = gudangs.firstWhere(
                    (g) => g.id == _selectedGudangId,
                    orElse: () => gudangs.first,
                  );
                  final isEmptyGudang = (selectedGudang.activeBatchesCount ?? 0) == 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isEmptyGudang
                                ? AppColors.danger.withValues(alpha: 0.5)
                                : AppColors.border,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedGudangId,
                            items: gudangs.map((g) {
                              final hasStock = (g.activeBatchesCount ?? 0) > 0;
                              return DropdownMenuItem<int>(
                                value: g.id,
                                 child: Text(
                                  g.activeBatchesCount != null
                                      ? '${g.nama} (${g.activeBatchesCount} Batch Aktif)'
                                      : g.nama,
                                   maxLines: 1,
                                   overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: hasStock ? FontWeight.w600 : FontWeight.normal,
                                    color: hasStock
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                  ),
                                 ),
                               );
                             }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedGudangId = val);
                            },
                          ),
                        ),
                      ),
                      if (isEmptyGudang)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Peringatan: Fasilitas ini tidak memiliki stok batch aktif untuk diopname.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPurple),
                    ),
                  ),
                ),
                error: (_, __) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Gagal memuat fasilitas gudang aktif.',
                    style: TextStyle(fontSize: 12, color: AppColors.danger),
                  ),
                ),
              ),
          const SizedBox(height: 12),
          AppDatePickerField(
            label: 'Tanggal Opname:',
            selectedDate: _tanggalOpname,
            onDateSelected: (picked) => setState(() => _tanggalOpname = picked),
          ),
          const SizedBox(height: 12),
          const Text('Catatan Sesi (Opsional):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _catatanController,
            decoration: const InputDecoration(hintText: 'Misal: Opname Rutin Akhir Bulan...'),
          ),
          const SizedBox(height: 20),
          ref.watch(masterGudangListProvider).maybeWhen(
                data: (gudangs) => CustomButton(
                  text: 'Buka Sesi Opname Sekarang',
                  isLoading: _isSubmitting,
                  icon: const Icon(LucideIcons.playCircle, size: 18, color: Colors.white),
                  onPressed: () => _submit(gudangs),
                ),
                orElse: () => CustomButton(
                  text: 'Buka Sesi Opname Sekarang',
                  isLoading: _isSubmitting,
                  icon: const Icon(LucideIcons.playCircle, size: 18, color: Colors.white),
                  onPressed: null,
                ),
              ),
        ],
      ),
    );
  }
}
