import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/shared/widgets/app_toast.dart';
import 'package:simlog_mobile/features/audit/data/repositories/audit_repository.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';
import 'package:simlog_mobile/features/audit/presentation/widgets/sheets/form_terbitkan_temuan_fields.dart';
import 'package:simlog_mobile/features/audit/presentation/widgets/sheets/form_terbitkan_temuan_lookup_dropdown.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:simlog_mobile/features/master/presentation/providers/master_barang_provider.dart';

class FormTerbitkanTemuanSheet extends ConsumerStatefulWidget {
  const FormTerbitkanTemuanSheet({super.key});

  @override
  ConsumerState<FormTerbitkanTemuanSheet> createState() =>
      _FormTerbitkanTemuanSheetState();
}

class _FormTerbitkanTemuanSheetState
    extends ConsumerState<FormTerbitkanTemuanSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _objekCtrl = TextEditingController();
  final TextEditingController _ringkasanCtrl = TextEditingController();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  String _risiko = 'Moderat';
  DateTime _tanggalAudit = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  int? _selectedUnitId;
  int? _selectedGudangId;
  bool _isLoading = false;

  @override
  void dispose() {
    _objekCtrl.dispose();
    _ringkasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    if (_dueDate.isBefore(_tanggalAudit)) {
      AppToast.error(context,
          'Batas waktu (due date) tidak boleh mendahului tanggal audit.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(auditRepositoryProvider);
      final fmtTanggal =
          '${_tanggalAudit.year.toString().padLeft(4, '0')}-${_tanggalAudit.month.toString().padLeft(2, '0')}-${_tanggalAudit.day.toString().padLeft(2, '0')}';
      final fmtDueDate =
          '${_dueDate.year.toString().padLeft(4, '0')}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}';
      await repo.simpanTemuan(
        objekAudit: _objekCtrl.text.trim(),
        ringkasan: _ringkasanCtrl.text.trim(),
        tingkatRisiko: _risiko,
        tanggalAudit: fmtTanggal,
        dueDateCapa: fmtDueDate,
        unitId: _selectedUnitId,
        gudangId: _selectedGudangId,
      );

      if (mounted) {
        AppToast.success(
            context, 'Temuan audit berhasil didaftarkan ke sistem CAPA!');
        Navigator.pop(context, true);
        ref.invalidate(auditSummaryProvider);
        ref.invalidate(registerTemuanProvider);
        ref.invalidate(dashboardSummaryProvider);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Gagal mendaftarkan temuan: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickTanggalAudit() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalAudit,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _tanggalAudit = picked;
        if (_dueDate.isBefore(_tanggalAudit)) {
          _dueDate = _tanggalAudit.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(_tanggalAudit) ? _tanggalAudit : _dueDate,
      firstDate: _tanggalAudit,
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(masterUnitListProvider);
    final gudangsAsync = ref.watch(masterGudangListProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Registrasi Temuan Audit Baru',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Text(
                'Catat ketidaksesuaian tata kelola logistik hasil uji petik SPI ke dalam sistem CAPA.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              // 1. Objek Pemeriksaan Audit
              const FormTerbitkanTemuanRequiredLabel(
                  'Objek Pemeriksaan Audit '),
              const SizedBox(height: 4),
              TextFormField(
                controller: _objekCtrl,
                maxLength: 150,
                decoration: formTerbitkanTemuanTextDecoration(
                  counterText: '',
                  hintText:
                      'Contoh: Gudang Sentral Logistik / Pengadaan PO-2026-003...',
                ),
                style: const TextStyle(fontSize: 13),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Objek pemeriksaan audit wajib diisi.';
                  }
                  if (text.length < 5) {
                    return 'Objek audit minimal 5 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 2. Tingkat Risiko
              const FormTerbitkanTemuanRequiredLabel('Tingkat Risiko '),
              const SizedBox(height: 4),
              FormTerbitkanTemuanRisikoDropdown(
                value: _risiko,
                onChanged: (val) => setState(() => _risiko = val),
              ),
              const SizedBox(height: 12),

              // 3. Tanggal Audit & Due Date CAPA
              Row(
                children: [
                  Expanded(
                    child: FormTerbitkanTemuanDateField(
                      label: 'Tanggal Audit ',
                      icon: LucideIcons.calendar,
                      iconColor: AppColors.textSecondary,
                      valueText: _formatDate(_tanggalAudit),
                      onTap: _pickTanggalAudit,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FormTerbitkanTemuanDateField(
                      label: 'Batas Waktu (Due Date) ',
                      icon: LucideIcons.calendarCheck,
                      iconColor: AppColors.primaryPurple,
                      valueText: _formatDate(_dueDate),
                      onTap: _pickDueDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Unit Terperiksa (Opsional) & Gudang Terperiksa (Opsional)
              Row(
                children: [
                  Expanded(
                    child: FormTerbitkanTemuanLookupDropdown<UnitModel>(
                      label: 'Unit Terperiksa (Opsional)',
                      placeholder: '-- Pilih Unit --',
                      errorText: 'Gagal memuat unit',
                      itemsAsync: unitsAsync,
                      selectedId: _selectedUnitId,
                      idOf: (u) => u.id,
                      namaOf: (u) => u.nama,
                      onChanged: (val) => setState(() => _selectedUnitId = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FormTerbitkanTemuanLookupDropdown<GudangModel>(
                      label: 'Gudang Terperiksa (Opsional)',
                      placeholder: '-- Pilih Gudang --',
                      errorText: 'Gagal memuat gudang',
                      itemsAsync: gudangsAsync,
                      selectedId: _selectedGudangId,
                      idOf: (g) => g.id,
                      namaOf: (g) => g.nama,
                      onChanged: (val) =>
                          setState(() => _selectedGudangId = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Uraian Ringkasan Temuan Ketidaksesuaian
              const FormTerbitkanTemuanRequiredLabel(
                  'Uraian Ringkasan Temuan Ketidaksesuaian '),
              const SizedBox(height: 4),
              TextFormField(
                controller: _ringkasanCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: formTerbitkanTemuanTextDecoration(
                  hintText:
                      'Uraikan temuan ketidaksesuaian, pasal SOP yang dilanggar, dan dampak operasionalnya...',
                ),
                style: const TextStyle(fontSize: 13),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Uraian ringkasan temuan wajib diisi.';
                  }
                  if (text.length < 10) {
                    return 'Uraian ringkasan temuan minimal 10 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FormTerbitkanTemuanSubmitButton(
                  isLoading: _isLoading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
