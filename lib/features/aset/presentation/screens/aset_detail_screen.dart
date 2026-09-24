import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/aset_detail_model.dart';
import '../providers/aset_provider.dart';

class AsetDetailScreen extends ConsumerStatefulWidget {
  final AsetDetailModel initialAset;

  const AsetDetailScreen({
    super.key,
    required this.initialAset,
  });

  @override
  ConsumerState<AsetDetailScreen> createState() => _AsetDetailScreenState();
}

class _AsetDetailScreenState extends ConsumerState<AsetDetailScreen> {
  late AsetDetailModel _aset;

  @override
  void initState() {
    super.initState();
    _aset = widget.initialAset;
  }

  void _showPengembalianModal() {
    String kondisiKembali = 'BAIK';
    final catatanController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.tintOrangeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.packageCheck, size: 22, color: AppColors.tintOrange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inspeksi Fisik Pengembalian',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${_aset.kodeAset} • ${_aset.namaKomoditas}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Kondisi fisik selector
              const Text(
                'Kondisi Fisik Saat Kembali:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildKondisiChip('BAIK', 'Baik', kondisiKembali, (v) {
                    setModalState(() => kondisiKembali = v);
                  }),
                  const SizedBox(width: 8),
                  _buildKondisiChip('RUSAK_RINGAN', 'Rusak Ringan', kondisiKembali, (v) {
                    setModalState(() => kondisiKembali = v);
                  }),
                  const SizedBox(width: 8),
                  _buildKondisiChip('RUSAK_BERAT', 'Rusak Berat', kondisiKembali, (v) {
                    setModalState(() => kondisiKembali = v);
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Catatan
              const Text(
                'Catatan Hasil Pemeriksaan:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: catatanController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Kelengkapan aksesoris, kebersihan, atau keluhan fisik...',
                ),
              ),
              const SizedBox(height: 20),

              CustomButton(
                text: 'Konfirmasi Pengembalian Selesai',
                icon: const Icon(LucideIcons.checkCheck, size: 18, color: Colors.white),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  final peminjamanId = _aset.peminjamanAktif?.peminjamanId;
                  if (peminjamanId == null) return;

                  final notifier = ref.read(asetActionProvider.notifier);
                  final ok = await notifier.konfirmasiPengembalian(
                    peminjamanId: peminjamanId,
                    inspeksi: [
                      {
                        'permintaan_peminjaman_detail_id': peminjamanId, // backend map
                        'aset_id': _aset.id,
                        'kondisi_saat_kembali': kondisiKembali,
                        'catatan': catatanController.text.trim(),
                      }
                    ],
                    catatan: catatanController.text.trim(),
                  );

                  if (!mounted) return;
                  final state = ref.read(asetActionProvider);
                  if (ok) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(state.successMessage ?? 'Pengembalian aset berhasil diproses.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    if (state.aset != null) {
                      setState(() {
                        _aset = state.aset!;
                      });
                    }
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage ?? 'Gagal memproses pengembalian.'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKondisiChip(
    String val,
    String label,
    String currentVal,
    ValueChanged<String> onSelect,
  ) {
    final isSelected = currentVal == val;
    Color color = AppColors.success;
    if (val == 'RUSAK_RINGAN') color = AppColors.warning;
    if (val == 'RUSAK_BERAT') color = AppColors.danger;

    return Expanded(
      child: InkWell(
        onTap: () => onSelect(val),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(asetActionProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Profil Aset Fisik'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () async {
              final updated = await ref.read(asetActionProvider.notifier).scanAset(_aset.kodeAset);
              if (updated != null && mounted) {
                setState(() => _aset = updated);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Asset Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryHeroGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _aset.kodeAset,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        StatusBadge(status: _aset.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _aset.namaKomoditas,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_aset.kategori} • Nomor Seri: ${_aset.nomorSeri}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Overdue Alert Banner if active
              if (_aset.peminjamanAktif != null && _aset.peminjamanAktif!.isOverdue) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, size: 22, color: AppColors.danger),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Peminjaman Melebihi Batas Waktu!',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rencana kembali: ${_aset.peminjamanAktif!.tanggalKembaliRencana ?? '-'}. Mohon segera lakukan pengembalian fisik.',
                              style: const TextStyle(fontSize: 11, color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Asset Location & Condition Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: LucideIcons.mapPin,
                      label: 'Lokasi Tercatat Saat Ini',
                      value: _aset.lokasiTercatat,
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    _buildInfoRow(
                      icon: LucideIcons.userCheck,
                      label: 'Penanggung Jawab / Peminjam',
                      value: _aset.penanggungJawab,
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    _buildInfoRow(
                      icon: LucideIcons.activity,
                      label: 'Kondisi Fisik',
                      value: _aset.kondisi.replaceAll('_', ' '),
                      badge: StatusBadge(status: _aset.kondisi),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Active Loan Details if DIPINJAM
              if (_aset.peminjamanAktif != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.repeat, size: 16, color: AppColors.primaryPurple),
                          SizedBox(width: 8),
                          Text(
                            'Transaksi Peminjaman Aktif',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: LucideIcons.fileText,
                        label: 'Kode Peminjaman',
                        value: _aset.peminjamanAktif!.kodePinjam,
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      _buildInfoRow(
                        icon: LucideIcons.building,
                        label: 'Unit Peminjam',
                        value: _aset.peminjamanAktif!.unitPeminjam,
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      _buildInfoRow(
                        icon: LucideIcons.calendar,
                        label: 'Batas Rencana Kembali',
                        value: _aset.peminjamanAktif!.tanggalKembaliRencana ?? '-',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              if (_aset.isDipinjam && _aset.peminjamanAktif != null) ...[
                CustomButton(
                  text: 'Kembalikan & Cek Fisik',
                  icon: const Icon(LucideIcons.packageCheck, size: 18, color: Colors.white),
                  isLoading: actionState.isLoading,
                  onPressed: _showPengembalianModal,
                ),
              ] else if (_aset.isTersedia) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tintVioletBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.checkCircle2, size: 20, color: AppColors.primaryPurple),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Aset ini siap digunakan atau dipinjamkan sesuai SOP sarana rumah sakit.',
                          style: TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? badge,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        if (badge != null) badge,
      ],
    );
  }
}
