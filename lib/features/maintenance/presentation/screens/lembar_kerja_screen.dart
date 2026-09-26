import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../pengadaan/data/models/master_barang_model.dart';
import '../../../pengadaan/presentation/widgets/barang_picker_bottom_sheet.dart';
import '../../data/models/spk_model.dart';
import '../providers/maintenance_provider.dart';

class LembarKerjaScreen extends ConsumerStatefulWidget {
  final SpkDetailModel spk;

  const LembarKerjaScreen({
    super.key,
    required this.spk,
  });

  @override
  ConsumerState<LembarKerjaScreen> createState() => _LembarKerjaScreenState();
}

class _LembarKerjaScreenState extends ConsumerState<LembarKerjaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosaController = TextEditingController();
  final _tindakanController = TextEditingController();
  final _jamMulaiController = TextEditingController(text: '08:30');
  final _jamSelesaiController = TextEditingController(text: '10:00');
  final _catatanController = TextEditingController();

  String _hasil = 'BERHASIL';
  final List<Map<String, dynamic>> _spareparts = [];

  @override
  void dispose() {
    _diagnosaController.dispose();
    _tindakanController.dispose();
    _jamMulaiController.dispose();
    _jamSelesaiController.dispose();
    _catatanController.dispose();
    super.dispose();
  }


  void _openSparepartPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarangPickerBottomSheet(
        filterTipe: 'SPAREPART',
        onBarangSelected: (MasterBarangModel barang) {
          if (barang.tipe.toUpperCase() != 'SPAREPART') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hanya barang dengan tipe SPAREPART yang dapat digunakan.'),
                backgroundColor: AppColors.danger,
              ),
            );
            return;
          }
          setState(() {
            final idx = _spareparts.indexWhere((e) => e['barang_id'] == barang.id);
            if (idx >= 0) {
              _spareparts[idx]['jumlah'] = (_spareparts[idx]['jumlah'] as int) + 1;
            } else {
              _spareparts.add({
                'barang_id': barang.id,
                'nama': barang.nama,
                'satuan': barang.satuan,
                'jumlah': 1,
              });
            }
          });
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(lembarKerjaProvider.notifier);

    final ok = await notifier.submitLog(
      spkId: widget.spk.id,
      diagnosa: _diagnosaController.text.trim(),
      tindakan: _tindakanController.text.trim(),
      hasil: _hasil,
      jamMulai: _jamMulaiController.text.trim(),
      jamSelesai: _jamSelesaiController.text.trim(),
      catatan: _catatanController.text.trim(),
      foto: null,
      spareparts: _spareparts.isEmpty ? null : _spareparts,
    );

    if (!mounted) return;
    final state = ref.read(lembarKerjaProvider);

    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(state.successMessage ?? 'Lembar kerja berhasil disimpan.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Gagal menyimpan lembar kerja.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(lembarKerjaProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Lembar Kerja: ${widget.spk.kodeSpk}'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.spk.aset.nama,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kode: ${widget.spk.aset.kodeAset} • Lokasi: ${widget.spk.aset.lokasi}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Jam Kerja Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Jam Mulai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _jamMulaiController,
                                  decoration: const InputDecoration(
                                    hintText: '08:00',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Jam Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _jamSelesaiController,
                                  decoration: const InputDecoration(
                                    hintText: '10:00',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Hasil Selector
                      const Text(
                        'Hasil Pengerjaan Teknisi',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildHasilChip('BERHASIL', 'Berhasil', AppColors.success, const Color(0xFFECFDF5)),
                          const SizedBox(width: 8),
                          _buildHasilChip('PENDING', 'Pending (Lanjut)', AppColors.warning, const Color(0xFFFFFBEB)),
                          const SizedBox(width: 8),
                          _buildHasilChip('GAGAL', 'Gagal', AppColors.danger, const Color(0xFFFEF2F2)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Diagnosa
                      const Text(
                        'Diagnosa Kerusakan Teknis *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _diagnosaController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'misal: Sekring putus, bearing motor aus, kabel power terkelupas...',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Diagnosa kerusakan wajib diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Tindakan Perbaikan
                      const Text(
                        'Tindakan Perbaikan yang Dilakukan *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _tindakanController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'misal: Pembersihan sirkuit, penggantian sekring 5A, pelumasan bearing...',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Tindakan perbaikan wajib diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Spareparts Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pemakaian Suku Cadang',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          TextButton.icon(
                            onPressed: _openSparepartPicker,
                            icon: const Icon(LucideIcons.plus, size: 15),
                            label: const Text('Tambah Part'),
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      if (_spareparts.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'Tidak ada suku cadang yang digunakan dalam perbaikan ini.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        ..._spareparts.map((p) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${p['nama']} (${p['satuan']})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 16),
                                      onPressed: () {
                                        setState(() {
                                          if ((p['jumlah'] as int) > 1) {
                                            p['jumlah'] = (p['jumlah'] as int) - 1;
                                          } else {
                                            _spareparts.remove(p);
                                          }
                                        });
                                      },
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Text('${p['jumlah']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 16),
                                      onPressed: () {
                                        setState(() => p['jumlah'] = (p['jumlah'] as int) + 1);
                                      },
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Sticky Submit Bar - Full Width White Background
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: CustomButton(
                    width: double.infinity,
                    text: 'Simpan Lembar Kerja',
                    isLoading: actionState.isLoading,
                    icon: const Icon(LucideIcons.checkCheck, size: 18, color: Colors.white),
                    onPressed: _submit,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHasilChip(String val, String label, Color color, Color bg) {
    final isSelected = _hasil == val;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _hasil = val),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? bg : AppColors.surface,
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
}
