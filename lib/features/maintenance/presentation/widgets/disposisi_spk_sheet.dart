import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/tiket_maintenance_provider.dart';

class DisposisiSpkSheet extends ConsumerStatefulWidget {
  final int tiketId;
  final String kodeTiket;
  final String namaAset;
  final String unitPelapor;
  final String prioritas;
  final String? keluhan;

  const DisposisiSpkSheet({
    super.key,
    required this.tiketId,
    required this.kodeTiket,
    required this.namaAset,
    required this.unitPelapor,
    required this.prioritas,
    this.keluhan,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int tiketId,
    required String kodeTiket,
    required String namaAset,
    required String unitPelapor,
    required String prioritas,
    String? keluhan,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DisposisiSpkSheet(
        tiketId: tiketId,
        kodeTiket: kodeTiket,
        namaAset: namaAset,
        unitPelapor: unitPelapor,
        prioritas: prioritas,
        keluhan: keluhan,
      ),
    );
  }

  @override
  ConsumerState<DisposisiSpkSheet> createState() => _DisposisiSpkSheetState();
}

class _DisposisiSpkSheetState extends ConsumerState<DisposisiSpkSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _instruksiCtrl = TextEditingController();

  int? _selectedTeknisiId;
  DateTime _tanggalPenugasan = DateTime.now();
  DateTime _targetSelesai = DateTime.now().add(const Duration(days: 2));

  @override
  void dispose() {
    _instruksiCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isTarget}) async {
    final initial = isTarget ? _targetSelesai : _tanggalPenugasan;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurple,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isTarget) {
          _targetSelesai = picked;
        } else {
          _tanggalPenugasan = picked;
          if (_targetSelesai.isBefore(_tanggalPenugasan)) {
            _targetSelesai = _tanggalPenugasan.add(const Duration(days: 2));
          }
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedTeknisiId == null) {
      AppToast.error(context, 'Pilih teknisi penanggung jawab terlebih dahulu.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final fmtTglPenugasan =
        '${_tanggalPenugasan.year.toString().padLeft(4, '0')}-${_tanggalPenugasan.month.toString().padLeft(2, '0')}-${_tanggalPenugasan.day.toString().padLeft(2, '0')}';
    final fmtTargetSelesai =
        '${_targetSelesai.year.toString().padLeft(4, '0')}-${_targetSelesai.month.toString().padLeft(2, '0')}-${_targetSelesai.day.toString().padLeft(2, '0')}';

    final ok = await ref.read(tiketActionProvider.notifier).disposisiTiket(
          tiketId: widget.tiketId,
          teknisiId: _selectedTeknisiId!,
          tanggalPenugasan: fmtTglPenugasan,
          targetSelesai: fmtTargetSelesai,
          instruksiKhusus: _instruksiCtrl.text.trim(),
        );

    if (!mounted) return;

    final s = ref.read(tiketActionProvider);
    if (ok) {
      AppToast.success(context, s.successMessage ?? 'SPK berhasil diterbitkan.');
      Navigator.pop(context, true);
    } else {
      AppToast.error(context, s.errorMessage ?? 'Gagal mendisposisikan tiket.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final teknisiListAsync = ref.watch(teknisiListProvider);
    final actionState = ref.watch(tiketActionProvider);

    return AppBottomSheetWrapper(
      maxHeightFactor: 0.90,
      title: 'Disposisi SPK Servis',
      subtitle: '${widget.kodeTiket} • ${widget.unitPelapor}',
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ringkasan Tiket
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.namaAset,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(status: widget.prioritas),
                      ],
                    ),
                    if (widget.keluhan != null && widget.keluhan!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Keluhan: ${widget.keluhan}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. Pilih Teknisi Pelaksana
              const Text(
                'Tugaskan ke Teknisi Pelaksana *',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              teknisiListAsync.when(
                data: (items) {
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedTeknisiId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      hintText: 'Pilih teknisi resmi IPSRS...',
                    ),
                    items: items.map((t) {
                      return DropdownMenuItem<int>(
                        value: t.id,
                        child: Text(
                          '${t.nama} (${t.email})',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTeknisiId = val),
                    validator: (val) => val == null ? 'Teknisi pelaksana wajib dipilih' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text(
                  'Gagal memuat daftar teknisi: $err',
                  style: const TextStyle(color: AppColors.danger, fontSize: 11),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Tanggal Penugasan & Target Selesai
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tgl Penugasan *',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _pickDate(isTarget: false),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendar, size: 14, color: AppColors.primaryPurple),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    AppFormatters.tanggal(_tanggalPenugasan),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Target Selesai *',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _pickDate(isTarget: true),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendarCheck, size: 14, color: AppColors.tintOrange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    AppFormatters.tanggal(_targetSelesai),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Catatan / Instruksi Khusus
              const Text(
                'Instruksi Khusus / Diagnosis Awal (Opsional)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _instruksiCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                  hintText: 'Misal: Periksa kabel data, head pemanas, atau bawa suku cadang cadangan...',
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Konfirmasi Disposisi
              CustomButton(
                width: double.infinity,
                text: 'Terbitkan & Disposisi SPK',
                isLoading: actionState.isLoading,
                icon: const Icon(LucideIcons.send, size: 18, color: Colors.white),
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
