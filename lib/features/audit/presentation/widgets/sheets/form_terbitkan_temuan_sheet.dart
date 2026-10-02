import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/shared/widgets/app_toast.dart';
import 'package:simlog_mobile/features/audit/data/repositories/audit_repository.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';
import 'package:simlog_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:simlog_mobile/features/master/presentation/providers/master_barang_provider.dart';

class FormTerbitkanTemuanSheet extends ConsumerStatefulWidget {
  const FormTerbitkanTemuanSheet({super.key});

  @override
  ConsumerState<FormTerbitkanTemuanSheet> createState() => _FormTerbitkanTemuanSheetState();
}

class _FormTerbitkanTemuanSheetState extends ConsumerState<FormTerbitkanTemuanSheet> {
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
      AppToast.error(context, 'Batas waktu (due date) tidak boleh mendahului tanggal audit.');
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
        AppToast.success(context, 'Temuan audit berhasil didaftarkan ke sistem CAPA!');
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
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Text(
                'Catat ketidaksesuaian tata kelola logistik hasil uji petik SPI ke dalam sistem CAPA.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              // 1. Objek Pemeriksaan Audit
              RichText(
                text: const TextSpan(
                  text: 'Objek Pemeriksaan Audit ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
                  children: [
                    TextSpan(text: '*', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _objekCtrl,
                maxLength: 150,
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.danger),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
                  ),
                  hintText: 'Contoh: Gudang Sentral Logistik / Pengadaan PO-2026-003...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              RichText(
                text: const TextSpan(
                  text: 'Tingkat Risiko ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
                  children: [
                    TextSpan(text: '*', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _risiko,
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'Mayor',
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        const Text('Mayor (Risiko Kritis / Keuangan)', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Moderat',
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        const Text('Moderat (Ketidakpatuhan SOP)', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Minor',
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.tintBlue, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        const Text('Minor (Administratif Ringan)', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _risiko = val);
                },
              ),
              const SizedBox(height: 12),

              // 3. Tanggal Audit & Due Date CAPA
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            text: 'Tanggal Audit ',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
                            children: [
                              TextSpan(text: '*', style: TextStyle(color: AppColors.danger)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _pickTanggalAudit,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_formatDate(_tanggalAudit),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                        RichText(
                          text: const TextSpan(
                            text: 'Batas Waktu (Due Date) ',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
                            children: [
                              TextSpan(text: '*', style: TextStyle(color: AppColors.danger)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _pickDueDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendarCheck, size: 14, color: AppColors.primaryPurple),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_formatDate(_dueDate),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
              const SizedBox(height: 12),

              // 4. Unit Terperiksa (Opsional) & Gudang Terperiksa (Opsional)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Unit Terperiksa (Opsional)',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            if (_selectedUnitId != null)
                              GestureDetector(
                                onTap: () => setState(() => _selectedUnitId = null),
                                child: const Text('Reset', style: TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        unitsAsync.when(
                          data: (units) => DropdownButtonFormField<int?>(
                            // ignore: deprecated_member_use
                            value: _selectedUnitId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('-- Pilih Unit --',
                                      style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
                              ...units.map((u) => DropdownMenuItem<int?>(
                                  value: u.id,
                                  child: Text(u.nama,
                                      style: const TextStyle(fontSize: 11),
                                      overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (val) => setState(() => _selectedUnitId = val),
                          ),
                          loading: () => const SizedBox(
                              height: 40,
                              child: Center(
                                  child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2)))),
                          error: (_, __) => const Text('Gagal memuat unit',
                              style: TextStyle(fontSize: 10, color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Gudang Terperiksa (Opsional)',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            if (_selectedGudangId != null)
                              GestureDetector(
                                onTap: () => setState(() => _selectedGudangId = null),
                                child: const Text('Reset', style: TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        gudangsAsync.when(
                          data: (gudangs) => DropdownButtonFormField<int?>(
                            // ignore: deprecated_member_use
                            value: _selectedGudangId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('-- Pilih Gudang --',
                                      style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
                              ...gudangs.map((g) => DropdownMenuItem<int?>(
                                  value: g.id,
                                  child: Text(g.nama,
                                      style: const TextStyle(fontSize: 11),
                                      overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (val) => setState(() => _selectedGudangId = val),
                          ),
                          loading: () => const SizedBox(
                              height: 40,
                              child: Center(
                                  child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2)))),
                          error: (_, __) => const Text('Gagal memuat gudang',
                              style: TextStyle(fontSize: 10, color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Uraian Ringkasan Temuan Ketidaksesuaian
              RichText(
                text: const TextSpan(
                  text: 'Uraian Ringkasan Temuan Ketidaksesuaian ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
                  children: [
                    TextSpan(text: '*', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _ringkasanCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.danger),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
                  ),
                  hintText:
                      'Uraikan temuan ketidaksesuaian, pasal SOP yang dilanggar, dan dampak operasionalnya...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(LucideIcons.send, size: 16, color: Colors.white),
                  label: Text(_isLoading ? 'Mendaftarkan Temuan...' : 'Daftarkan Temuan ke SPI',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
