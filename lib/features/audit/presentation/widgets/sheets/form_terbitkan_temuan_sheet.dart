import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
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
  final TextEditingController _objekCtrl = TextEditingController();
  final TextEditingController _ringkasanCtrl = TextEditingController();
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
    if (_objekCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Objek pemeriksaan audit minimal 5 karakter.'),
            backgroundColor: AppColors.danger),
      );
      return;
    }
    if (_ringkasanCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Uraian ringkasan temuan minimal 10 karakter.'),
            backgroundColor: AppColors.danger),
      );
      return;
    }
    if (_dueDate.isBefore(_tanggalAudit)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Batas waktu (due date) tidak boleh mendahului tanggal audit.'),
            backgroundColor: AppColors.danger),
      );
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Temuan audit berhasil diterbitkan!'),
              backgroundColor: AppColors.success),
        );
        ref.invalidate(auditSummaryProvider);
        ref.invalidate(registerTemuanProvider);
        ref.invalidate(dashboardSummaryProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mendaftarkan temuan: $e'),
              backgroundColor: AppColors.danger),
        );
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
            const Text('Objek Pemeriksaan Audit *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
              controller: _objekCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Contoh: Gudang Sentral Logistik / Pengadaan PO-2026-003...',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Tingkat Risiko
            const Text('Tingkat Risiko *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _risiko,
              decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: const [
                DropdownMenuItem(value: 'Mayor', child: Text('Mayor (Risiko Kritis / Keuangan)')),
                DropdownMenuItem(value: 'Moderat', child: Text('Moderat (Ketidakpatuhan SOP)')),
                DropdownMenuItem(value: 'Minor', child: Text('Minor (Administratif Ringan)')),
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
                      const Text('Tanggal Audit *',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
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
                              const SizedBox(width: 6),
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
                      const Text('Batas Waktu (Due Date) *',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
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
                              const Icon(LucideIcons.calendarClock, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
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
                      const Text('Unit Terperiksa (Opsional)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 4),
                      unitsAsync.when(
                        data: (units) => DropdownButtonFormField<int?>(
                          initialValue: _selectedUnitId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
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
                      const Text('Gudang Terperiksa (Opsional)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 4),
                      gudangsAsync.when(
                        data: (gudangs) => DropdownButtonFormField<int?>(
                          initialValue: _selectedGudangId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
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
            const Text('Uraian Ringkasan Temuan Ketidaksesuaian *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
              controller: _ringkasanCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    'Uraikan temuan ketidaksesuaian, pasal SOP yang dilanggar, dan dampak operasionalnya...',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Daftarkan Temuan ke SPI',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
