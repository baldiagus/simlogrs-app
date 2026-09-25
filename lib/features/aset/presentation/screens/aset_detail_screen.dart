import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/aset_detail_model.dart';
import '../providers/aset_provider.dart';

class AsetDetailScreen extends ConsumerStatefulWidget {
  final AsetDetailModel? initialAset;
  final int? asetId;

  const AsetDetailScreen({
    super.key,
    this.initialAset,
    this.asetId,
  }) : assert(initialAset != null || asetId != null, 'Either initialAset or asetId must be provided');

  @override
  ConsumerState<AsetDetailScreen> createState() => _AsetDetailScreenState();
}

class _AsetDetailScreenState extends ConsumerState<AsetDetailScreen> {
  AsetDetailModel? _aset;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialAset != null) {
      _aset = widget.initialAset;
    } else {
      _fetchAset();
    }
  }

  Future<void> _fetchAset() async {
    if (widget.asetId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ref.read(asetRepositoryProvider).getDetailAset(widget.asetId!);
      if (mounted) {
        setState(() {
          _aset = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showPengembalianModal() {
    if (_aset == null) return;
    final currentAset = _aset!;
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
                          '${currentAset.kodeAset} • ${currentAset.namaKomoditas}',
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
                  final peminjamanId = currentAset.peminjamanAktif?.peminjamanId;
                  if (peminjamanId == null) return;

                  final notifier = ref.read(asetActionProvider.notifier);
                  final ok = await notifier.konfirmasiPengembalian(
                    peminjamanId: peminjamanId,
                    inspeksi: [
                      {
                        'permintaan_peminjaman_detail_id': peminjamanId, // backend map
                        'aset_id': currentAset.id,
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Profil Aset Fisik')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _aset == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Profil Aset Fisik')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.circleAlert, size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Data aset tidak ditemukan',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _fetchAset,
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentAset = _aset!;
    final actionState = ref.watch(asetActionProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Profil Aset Fisik'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () async {
              final updated = await ref.read(asetActionProvider.notifier).scanAset(currentAset.kodeAset);
              if (updated != null && mounted) {
                setState(() {
                  _aset = updated;
                });
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
                            currentAset.kodeAset,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        StatusBadge(status: currentAset.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      currentAset.namaKomoditas,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentAset.kategori} • Nomor Seri: ${currentAset.nomorSeri}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Overdue Alert Banner if active
              if (currentAset.peminjamanAktif != null && currentAset.peminjamanAktif!.isOverdue) ...[
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
                              'Rencana kembali: ${currentAset.peminjamanAktif!.tanggalKembaliRencana ?? '-'}. Mohon segera lakukan pengembalian fisik.',
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
                      value: currentAset.lokasiTercatat,
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    _buildInfoRow(
                      icon: LucideIcons.userCheck,
                      label: 'Penanggung Jawab / Peminjam',
                      value: currentAset.penanggungJawab,
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    _buildInfoRow(
                      icon: LucideIcons.activity,
                      label: 'Kondisi Fisik',
                      value: currentAset.kondisi.replaceAll('_', ' '),
                      badge: StatusBadge(status: currentAset.kondisi),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Active Loan Details if DIPINJAM
              if (currentAset.peminjamanAktif != null) ...[
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
                        value: currentAset.peminjamanAktif!.kodePinjam,
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      _buildInfoRow(
                        icon: LucideIcons.building,
                        label: 'Unit Peminjam',
                        value: currentAset.peminjamanAktif!.unitPeminjam,
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      _buildInfoRow(
                        icon: LucideIcons.calendar,
                        label: 'Batas Rencana Kembali',
                        value: currentAset.peminjamanAktif!.tanggalKembaliRencana ?? '-',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              if (currentAset.isDipinjam && currentAset.peminjamanAktif != null) ...[
                CustomButton(
                  text: 'Kembalikan & Cek Fisik',
                  icon: const Icon(LucideIcons.packageCheck, size: 18, color: Colors.white),
                  isLoading: actionState.isLoading,
                  onPressed: _showPengembalianModal,
                ),
              ] else if (currentAset.isTersedia) ...[
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
