import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/data/repositories/audit_repository.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';

class FormCapaFromPoSheet extends ConsumerStatefulWidget {
  final KepatuhanPoModel po;

  const FormCapaFromPoSheet({super.key, required this.po});

  @override
  ConsumerState<FormCapaFromPoSheet> createState() => _FormCapaFromPoSheetState();
}

class _FormCapaFromPoSheetState extends ConsumerState<FormCapaFromPoSheet> {
  String _risiko = 'Mayor';
  final TextEditingController _ringkasanCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final po = widget.po;
    if (po.anomaliTags.contains('TANPA_PR')) {
      _ringkasanCtrl.text =
          'Penerbitan PO ${po.kode} senilai Rp ${po.totalBiaya.toStringAsFixed(0)} tanpa dokumen PR resmi dari unit.';
    } else if (po.anomaliTags.contains('TERLAMBAT')) {
      _ringkasanCtrl.text =
          'Pengiriman barang PO ${po.kode} dari vendor ${po.pemasok} terlambat melewati estimasi kirim.';
    } else {
      _ringkasanCtrl.text =
          'Ditemukan selisih kuantitas barang yang diterima di gudang pada dokumen PO ${po.kode}.';
    }
  }

  @override
  void dispose() {
    _ringkasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(auditRepositoryProvider);
      await repo.buatTemuanKepatuhan(
        widget.po.id,
        tingkatRisiko: _risiko,
        dueDateCapa: _dueDate.toIso8601String().substring(0, 10),
        ringkasan: _ringkasanCtrl.text.trim(),
        tipeAnomali: widget.po.anomaliTags.isNotEmpty ? widget.po.anomaliTags.first : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Temuan CAPA berhasil diterbitkan ke register!'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(auditSummaryProvider);
        ref.invalidate(registerTemuanProvider);
        ref.invalidate(kepatuhanPengadaanProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menerbitkan CAPA: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Terbitkan Temuan CAPA',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Objek Audit: PO ${widget.po.kode} - ${widget.po.pemasok}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 12),
          const Text('Tingkat Risiko *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: _risiko,
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'Mayor', child: Text('Mayor (14 Hari)')),
              DropdownMenuItem(value: 'Moderat', child: Text('Moderat (30 Hari)')),
              DropdownMenuItem(value: 'Minor', child: Text('Minor (60 Hari)')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _risiko = val;
                  _dueDate = DateTime.now().add(
                    Duration(days: val == 'Mayor' ? 14 : (val == 'Moderat' ? 30 : 60)),
                  );
                });
              }
            },
          ),
          const SizedBox(height: 12),
          const Text('Ringkasan Temuan & Ketidaksesuaian *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: _ringkasanCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), hintText: 'Uraikan ketidakpatuhan prosedur...'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan ke Register CAPA',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
