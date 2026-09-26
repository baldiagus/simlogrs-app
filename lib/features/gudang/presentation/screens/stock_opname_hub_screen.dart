import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/stock_opname_model.dart';
import '../../data/repositories/persediaan_repository.dart';
import '../providers/persediaan_providers.dart';

class StockOpnameHubScreen extends ConsumerStatefulWidget {
  const StockOpnameHubScreen({super.key});

  @override
  ConsumerState<StockOpnameHubScreen> createState() => _StockOpnameHubScreenState();
}

class _StockOpnameHubScreenState extends ConsumerState<StockOpnameHubScreen> {
  void _openInisiasiModal() {
    final user = ref.read(authStateProvider).user;
    int? selectedGudangId = user?.gudang?.id;
    final tanggalController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final catatanController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
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
                const Text(
                  'Inisiasi Sesi Stock Opname',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sistem akan mengunci snapshot saldo seluruh batch aktif di fasilitas gudang ini.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Pilih Gudang
                const Text('Fasilitas Gudang:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedGudangId ?? 1,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Gudang Sentral Farmasi & Medis')),
                        DropdownMenuItem(value: 2, child: Text('Gudang Logistik Non-Medis')),
                      ],
                      onChanged: (val) {
                        setModalState(() => selectedGudangId = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tanggal Opname
                const Text('Tanggal Opname:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: tanggalController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    suffixIcon: Icon(LucideIcons.calendar, size: 18),
                  ),
                ),
                const SizedBox(height: 12),

                // Catatan
                const Text('Catatan Sesi (Opsional):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: catatanController,
                  decoration: const InputDecoration(hintText: 'Misal: Opname Rutin Akhir Bulan...'),
                ),
                const SizedBox(height: 20),

                CustomButton(
                  text: 'Buka Sesi Opname Sekarang',
                  isLoading: isSubmitting,
                  icon: const Icon(LucideIcons.playCircle, size: 18, color: Colors.white),
                  onPressed: () async {
                    setModalState(() => isSubmitting = true);
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(ctx);
                    try {
                      await ref.read(persediaanRepositoryProvider).inisiasiOpname(
                            gudangId: selectedGudangId ?? 1,
                            tanggalOpname: tanggalController.text.trim(),
                            catatan: catatanController.text.trim(),
                          );
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Sesi Stock Opname berhasil diinisiasi.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    } catch (e) {
                      setModalState(() => isSubmitting = false);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openHitungFisikScreen(StokOpnameSesiModel opname) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HitungFisikOpnameScreen(opname: opname),
      ),
    ).then((_) => ref.refresh(stockOpnameListProvider));
  }

  @override
  Widget build(BuildContext context) {
    final opnameAsync = ref.watch(stockOpnameListProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Stock Opname Gudang'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.refresh(stockOpnameListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: const Text('Inisiasi Opname', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: _openInisiasiModal,
      ),
      body: SafeArea(
        child: opnameAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.circleAlert, size: 48, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(stockOpnameListProvider),
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return const EmptyStateView(
                icon: LucideIcons.clipboardList,
                title: 'Belum Ada Sesi Opname',
                message: 'Tekan tombol "Inisiasi Opname" di bawah untuk membuka sesi perhitungan fisik di rak gudang.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final op = sessions[index];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.clipboardCheck, color: AppColors.primaryPurple, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                op.kode,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          StatusBadge(status: op.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        op.gudangNama,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tanggal: ${op.tanggalOpname} • Inisiasi: ${op.petugasInisiasi}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      if (op.catatan != '-') ...[
                        const SizedBox(height: 4),
                        Text(
                          op.catatan,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      ],
                      const Divider(color: AppColors.border, height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.boxes, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${op.totalItem} Item (${op.totalTerhitung} Terhitung)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          if (op.totalSelisih > 0)
                            Text(
                              '${op.totalSelisih} Batch Selisih',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.danger),
                            )
                          else
                            const Text(
                              'Cocok (0 Selisih)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                            ),
                        ],
                      ),
                      if (op.isBerjalan) ...[
                        const SizedBox(height: 14),
                        CustomButton(
                          text: 'Buka Hitung Fisik (Blind Count)',
                          height: 40,
                          icon: const Icon(LucideIcons.scanLine, size: 16, color: Colors.white),
                          onPressed: () => _openHitungFisikScreen(op),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class HitungFisikOpnameScreen extends StatefulWidget {
  final StokOpnameSesiModel opname;

  const HitungFisikOpnameScreen({super.key, required this.opname});

  @override
  State<HitungFisikOpnameScreen> createState() => _HitungFisikOpnameScreenState();
}

class _HitungFisikOpnameScreenState extends State<HitungFisikOpnameScreen> {
  final Map<int, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final d in widget.opname.details) {
      _controllers[d.id] = TextEditingController(
        text: d.jumlahFisik != null ? d.jumlahFisik.toString() : '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitCount(bool finalisasi) async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final List<Map<String, dynamic>> items = [];
    for (final d in widget.opname.details) {
      final text = _controllers[d.id]?.text.trim() ?? '';
      final fisik = int.tryParse(text) ?? 0;
      items.add({
        'detail_id': d.id,
        'jumlah_fisik': fisik,
        'catatan': d.catatan,
      });
    }

    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container.read(persediaanRepositoryProvider).simpanHitungFisik(
            opnameId: widget.opname.id,
            items: items,
            finalisasi: finalisasi,
          );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(finalisasi
              ? 'Sesi opname telah difinalisasi dan diterbitkan ke otorisasi penyesuaian.'
              : 'Hasil hitung fisik berhasil disimpan sementara.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Hitung: ${widget.opname.kode}'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surface,
              child: const Row(
                children: [
                  Icon(LucideIcons.info, size: 16, color: AppColors.tintBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Masukkan jumlah fisik riil di rak untuk setiap batch komoditas.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: widget.opname.details.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final d = widget.opname.details[idx];
                  final controller = _controllers[d.id]!;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Batch: ${d.nomorBatch}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                color: AppColors.primaryPurple,
                              ),
                            ),
                            Text(
                              'Rak: ${d.lokasiRak}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.namaBarang,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Buku: ${d.jumlahSistem} ${d.satuan}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Fisik Riil (${d.satuan})',
                                  hintText: '0',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Sticky Bar - Full Width White Background
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => _submitCount(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Simpan Draf'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Finalisasi Sesi',
                          isLoading: _isSaving,
                          onPressed: () => _submitCount(true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
