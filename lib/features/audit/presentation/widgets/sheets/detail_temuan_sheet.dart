import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/shared/widgets/app_toast.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/data/repositories/audit_repository.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';

/// Bottom sheet detail temuan CAPA; auditee mengisi tindak lanjut, auditor mengevaluasi closing.
class DetailTemuanSheet extends ConsumerStatefulWidget {
  final TemuanCapaModel temuan;
  final bool isAuditor;

  const DetailTemuanSheet({super.key, required this.temuan, required this.isAuditor});

  /// Membuat state sheet detail temuan.
  @override
  ConsumerState<DetailTemuanSheet> createState() => _DetailTemuanSheetState();
}

/// State sheet detail temuan: mengelola input tindak lanjut/evaluasi dan status loading.
class _DetailTemuanSheetState extends ConsumerState<DetailTemuanSheet> {
  final TextEditingController _analisisCtrl = TextEditingController();
  final TextEditingController _tindakanCtrl = TextEditingController();
  final TextEditingController _evaluasiCtrl = TextEditingController();
  String _hasilEvaluasi = 'Closed';
  bool _isLoading = false;

  /// Mengisi controller dengan data tindak lanjut/evaluasi yang sudah ada pada temuan.
  @override
  void initState() {
    super.initState();
    _analisisCtrl.text = widget.temuan.analisisPenyebab ?? '';
    _tindakanCtrl.text = widget.temuan.tindakanPerbaikan ?? '';
    _evaluasiCtrl.text = widget.temuan.catatanEvaluasi ?? '';
  }

  /// Membuang semua [TextEditingController] agar tidak bocor memori.
  @override
  void dispose() {
    _analisisCtrl.dispose();
    _tindakanCtrl.dispose();
    _evaluasiCtrl.dispose();
    super.dispose();
  }

  /// Auditee mengirim analisis penyebab dan tindakan perbaikan (min. 10 karakter) ke auditor lalu menyegarkan data.
  Future<void> _submitTindakLanjut() async {
    if (_analisisCtrl.text.trim().length < 10 || _tindakanCtrl.text.trim().length < 10) {
      AppToast.error(context, 'Analisis dan tindakan perbaikan minimal 10 karakter.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(auditRepositoryProvider);
      await repo.tindakLanjutTemuan(
        widget.temuan.id,
        analisisPenyebab: _analisisCtrl.text.trim(),
        tindakanPerbaikan: _tindakanCtrl.text.trim(),
      );

      if (mounted) {
        AppToast.success(context, 'Tindak lanjut berhasil dikirimkan ke auditor!');
        Navigator.pop(context, true);
        ref.invalidate(registerTemuanProvider);
        ref.invalidate(auditSummaryProvider);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Gagal mengirimkan tindak lanjut: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Auditor menyimpan hasil evaluasi closing (validasi catatan min. 5 karakter) lalu menyegarkan register dan ringkasan.
  Future<void> _submitEvaluasi() async {
    if (_evaluasiCtrl.text.trim().length < 5) {
      AppToast.error(context, 'Catatan evaluasi minimal 5 karakter.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(auditRepositoryProvider);
      await repo.evaluasiTemuan(
        widget.temuan.id,
        hasilEvaluasi: _hasilEvaluasi,
        catatanEvaluasi: _evaluasiCtrl.text.trim(),
      );

      if (mounted) {
        AppToast.success(context, 'Evaluasi closing berhasil disimpan ($_hasilEvaluasi)!');
        Navigator.pop(context, true);
        ref.invalidate(registerTemuanProvider);
        ref.invalidate(auditSummaryProvider);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Gagal menyimpan evaluasi: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Membangun sheet detail temuan: info temuan, form tindak lanjut auditee, atau form evaluasi auditor.
  @override
  Widget build(BuildContext context) {
    final t = widget.temuan;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    t.kode,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(LucideIcons.x, size: 18), tooltip: 'Tutup', onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 6),
            Text(t.objekAudit, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              '${t.unit != '-' ? 'Unit: ${t.unit}' : ''}${t.unit != '-' && t.gudang != null && t.gudang != '-' ? ' • ' : ''}${t.gudang != null && t.gudang != '-' ? 'Gudang: ${t.gudang}' : ''}${t.unit == '-' && (t.gudang == null || t.gudang == '-') ? 'Lokasi: Sentral' : ''} • Auditor: ${t.auditor}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(10)),
              child: Text(t.ringkasan, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Bagian Tindak Lanjut Auditee
            const Text('Tindak Lanjut Auditee (Penyebab & Solusi)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _analisisCtrl,
              maxLines: 2,
              enabled: t.statusCapa != 'Closed',
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: 'Analisis akar penyebab (Root Cause)...'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tindakanCtrl,
              maxLines: 2,
              enabled: t.statusCapa != 'Closed',
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Tindakan perbaikan dan pencegahan (CAPA)...'),
            ),
            if (t.statusCapa != 'Closed') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitTindakLanjut,
                  icon: const Icon(LucideIcons.send, size: 14, color: Colors.white),
                  label: const Text('Kirim Tindak Lanjut',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.tintBlue),
                ),
              ),
            ],

            // Bagian Evaluasi Closing (Khusus Auditor)
            if (widget.isAuditor) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Evaluasi Closing Auditor SPI',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryPurple)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _hasilEvaluasi,
                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Closed', child: Text('Closed (Puas & Masalah Selesai)')),
                  DropdownMenuItem(
                      value: 'In Progress', child: Text('In Progress (Tolak / Perlu Perbaikan Lanjut)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _hasilEvaluasi = val);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _evaluasiCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Catatan rekomendasi evaluator...'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitEvaluasi,
                  icon: const Icon(LucideIcons.checkCheck, size: 14, color: Colors.white),
                  label: const Text('Simpan Evaluasi Auditor',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
