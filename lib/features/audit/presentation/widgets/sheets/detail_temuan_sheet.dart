import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/shared/widgets/app_toast.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/data/repositories/audit_repository.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';

/// Auditee berhak menindaklanjuti temuan: super admin, admin logistik, atau pegawai unit/gudang yang diperiksa.
bool canTindakLanjutTemuan(UserModel? user, TemuanCapaModel t) {
  if (user == null) return false;
  if (user.isSuperAdmin || user.hasRole('admin_logistik')) return true;
  return (t.unitId != null && t.unitId == user.unit?.id) ||
      (t.gudangId != null && t.gudangId == user.gudang?.id);
}

/// Auditor dan super admin boleh mengevaluasi/closing temuan.
bool canEvaluasiTemuan(UserModel? user) => user != null && (user.isAuditor || user.isSuperAdmin);

/// Bottom sheet detail temuan CAPA; auditee mengisi tindak lanjut, auditor mengevaluasi closing.
class DetailTemuanSheet extends ConsumerStatefulWidget {
  final TemuanCapaModel temuan;
  final bool canTindakLanjut;
  final bool canEvaluasi;

  const DetailTemuanSheet({
    super.key,
    required this.temuan,
    required this.canTindakLanjut,
    required this.canEvaluasi,
  });

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
  static const int _maxBerkas = 5;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _picked = [];
  late List<String> _bukti;

  /// Form tindak lanjut hanya aktif untuk auditee berhak saat status In Progress.
  bool get _bisaTindakLanjut => widget.canTindakLanjut && widget.temuan.statusCapa == 'In Progress';

  /// Mengisi controller dengan data tindak lanjut/evaluasi yang sudah ada pada temuan.
  @override
  void initState() {
    super.initState();
    _analisisCtrl.text = widget.temuan.analisisPenyebab ?? '';
    _tindakanCtrl.text = widget.temuan.tindakanPerbaikan ?? '';
    _evaluasiCtrl.text = widget.temuan.catatanEvaluasi ?? '';
    _bukti = List.of(widget.temuan.buktiPerbaikan);
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
      if (_picked.isNotEmpty) {
        final tersimpan = await repo.uploadBuktiTemuan(widget.temuan.id, List.of(_picked));
        _picked.clear();
        if (mounted) setState(() => _bukti = tersimpan);
      }
      await repo.tindakLanjutTemuan(
        widget.temuan.id,
        analisisPenyebab: _analisisCtrl.text.trim(),
        tindakanPerbaikan: _tindakanCtrl.text.trim(),
      );

      if (mounted) {
        AppToast.success(context, 'Tindak lanjut berhasil dikirimkan ke auditor!');
        Navigator.pop(context, true);
        ref.invalidate(registerTemuanProvider);
        ref.invalidate(capaMenungguCountProvider);
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

  /// Memilih foto dari galeri atau kamera sebagai bukti perbaikan (maksimal [_maxBerkas] lampiran).
  Future<void> _pilihBukti() async {
    if (_picked.length >= _maxBerkas) {
      AppToast.error(context, 'Maksimal $_maxBerkas lampiran.');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      if (source == ImageSource.camera) {
        final foto = await _picker.pickImage(
            source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
        if (foto != null && mounted) setState(() => _picked.add(foto));
      } else {
        // Tanpa `limit`: image_picker menolak limit < 2; sisa kuota dipotong dengan take().
        final fotos = await _picker.pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
        if (mounted) {
          setState(() => _picked.addAll(fotos.take(_maxBerkas - _picked.length)));
        }
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Gagal mengambil berkas: $e');
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

            // Bagian Tindak Lanjut Auditee: aktif hanya bagi auditee berhak saat status In Progress.
            const Text('Tindak Lanjut Auditee (Penyebab & Solusi)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            if (t.statusCapa == 'In Progress' && !widget.canTindakLanjut)
              const Text('Menunggu respon auditee',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
            else ...[
              TextField(
                controller: _analisisCtrl,
                maxLines: 2,
                enabled: _bisaTindakLanjut,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Analisis akar penyebab (Root Cause)...'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tindakanCtrl,
                maxLines: 2,
                enabled: _bisaTindakLanjut,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Tindakan perbaikan dan pencegahan (CAPA)...'),
              ),
              if (_bukti.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Bukti Perbaikan Tersimpan',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                for (final b in _bukti)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('• ${b.split('/').last}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
              ],
              if (_bisaTindakLanjut) ...[
                const SizedBox(height: 8),
                for (var i = 0; i < _picked.length; i++)
                  Row(
                    children: [
                      const Icon(LucideIcons.paperclip, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(_picked[i].name,
                              style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 14),
                        tooltip: 'Hapus lampiran',
                        onPressed: _isLoading ? null : () => setState(() => _picked.removeAt(i)),
                      ),
                    ],
                  ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pilihBukti,
                    icon: const Icon(LucideIcons.paperclip, size: 14),
                    label: const Text('Lampirkan Foto/Berkas'),
                  ),
                ),
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
            ],

            // Bagian Evaluasi Closing (hanya auditor / super admin)
            if (widget.canEvaluasi) ...[
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
