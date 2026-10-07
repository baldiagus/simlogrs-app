import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../master/presentation/providers/master_barang_provider.dart';
import '../../data/models/aset_tersedia_model.dart';
import '../providers/pengalihan_provider.dart';

class ModalPengalihanAsetSheet extends ConsumerStatefulWidget {
  final AsetTersediaModel? aset;

  const ModalPengalihanAsetSheet({
    super.key,
    this.aset,
  });

  static Future<bool?> show(BuildContext context, {AsetTersediaModel? aset}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalPengalihanAsetSheet(aset: aset),
    );
  }

  @override
  ConsumerState<ModalPengalihanAsetSheet> createState() => _ModalPengalihanAsetSheetState();
}

class _ModalPengalihanAsetSheetState extends ConsumerState<ModalPengalihanAsetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();
  final _catatanController = TextEditingController();
  AsetTersediaModel? _chosenAset;

  String _tipeTujuan = 'RUANGAN'; // 'RUANGAN' | 'GUDANG'
  int? _selectedUnitTujuanId;
  int? _selectedGudangTujuanId;

  @override
  void initState() {
    super.initState();
    _chosenAset = widget.aset;
  }

  @override
  void dispose() {
    _alasanController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(authStateProvider).user;
    if (_chosenAset == null) {
      AppToast.error(context, 'Pilih aset fisik yang ingin dialihkan.');
      return;
    }

    final unitAsalId = user?.unit?.id ?? (_chosenAset!.tipePenyedia == 'RUANGAN' ? _chosenAset!.penyediaId : null);
    final gudangAsalId = user?.gudang?.id ?? (_chosenAset!.tipePenyedia == 'GUDANG' ? _chosenAset!.penyediaId : null);
    // Anti self-transfer guard
    if (_tipeTujuan == 'RUANGAN' && _selectedUnitTujuanId != null && unitAsalId != null) {
      if (_selectedUnitTujuanId == unitAsalId) {
        AppToast.error(context, 'Unit tujuan tidak boleh sama dengan unit asal aset.');
        return;
      }
    }

    final payload = {
      'tipe_tujuan': _tipeTujuan,
      'unit_tujuan_id': _tipeTujuan == 'RUANGAN' ? _selectedUnitTujuanId : null,
      'gudang_tujuan_id': _tipeTujuan == 'GUDANG' ? _selectedGudangTujuanId : null,
      'unit_asal_id': unitAsalId,
      'gudang_asal_id': gudangAsalId,
      'tipe_asal': unitAsalId != null ? 'RUANGAN' : 'GUDANG',
      'aset_ids': [_chosenAset!.id],
      'tanggal_pengalihan': DateTime.now().toIso8601String().substring(0, 10),
      'alasan': _alasanController.text.trim(),
      if (_catatanController.text.trim().isNotEmpty) 'catatan': _catatanController.text.trim(),
    };

    final notifier = ref.read(pengalihanActionProvider.notifier);
    final ok = await notifier.ajukanPengalihan(payload);

    if (!mounted) return;
    final state = ref.read(pengalihanActionProvider);

    if (ok) {
      AppToast.success(context, state.successMessage ?? 'Pengajuan pengalihan berhasil diajukan.');
      Navigator.pop(context, true);
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal mengajukan pengalihan aset.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final unitAsalNama = user?.unit?.nama ?? _chosenAset?.namaPenyedia ?? 'Fasilitas Anda';
    final unitsAsync = ref.watch(masterUnitListProvider);
    final gudangsAsync = ref.watch(masterGudangListProvider);
    final actionState = ref.watch(pengalihanActionProvider);

    return AppBottomSheetWrapper(
      maxHeightFactor: 0.9,
      child: Flexible(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.arrowRightLeft, color: AppColors.primaryPurple, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pengalihan / Mutasi Aset',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mutasi kepemilikan dan penanggung jawab fisik secara permanen',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ================= Tahap 1: Aset & Fasilitas Asal =================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tahap 1: Aset & Fasilitas Asal',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(LucideIcons.lock, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        const Text(
                          'Unit Asal (Terkunci): ',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                        ),
                        Expanded(
                          child: Text(
                            unitAsalNama,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.aset != null && _chosenAset != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _chosenAset!.namaKomoditas,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Kode: ${_chosenAset!.kodeAset} • SN: ${_chosenAset!.nomorSeri}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kondisi: ${_chosenAset!.kondisi} • Satuan: ${_chosenAset!.satuan}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ref.watch(daftarAsetAsalProvider).when(
                        data: (asets) {
                          if (asets.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Tidak ada aset fisik di fasilitas Anda yang siap dialihkan.',
                                style: TextStyle(fontSize: 12, color: AppColors.warning),
                              ),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<int>(
                                key: const Key('dropdown_aset_asal'),
                                isExpanded: true,
                                initialValue: _chosenAset?.id,
                                decoration: const InputDecoration(
                                  labelText: 'Pilih Aset Fisik Inventaris *',
                                  prefixIcon: Icon(LucideIcons.armchair, size: 18),
                                ),
                                items: asets.map((a) {
                                  return DropdownMenuItem<int>(
                                    value: a.id,
                                    child: Text(
                                      '${a.namaKomoditas} (${a.kodeAset})',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _chosenAset = asets.firstWhere((a) => a.id == val);
                                  });
                                },
                                validator: (v) => _chosenAset == null ? 'Pilih aset inventaris' : null,
                              ),
                              if (_chosenAset != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _chosenAset!.namaKomoditas,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Kode: ${_chosenAset!.kodeAset} • SN: ${_chosenAset!.nomorSeri}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Kondisi: ${_chosenAset!.kondisi} • Satuan: ${_chosenAset!.satuan}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Gagal memuat inventaris aset'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ================= Tahap 2: Fasilitas Tujuan & Alasan =================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tahap 2: Fasilitas Tujuan & Alasan',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),

                    // Toggle Tipe Tujuan
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Ruangan / Unit')),
                            selected: _tipeTujuan == 'RUANGAN',
                            onSelected: (val) {
                              if (val) setState(() => _tipeTujuan = 'RUANGAN');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Gudang Logistik')),
                            selected: _tipeTujuan == 'GUDANG',
                            onSelected: (val) {
                              if (val) setState(() => _tipeTujuan = 'GUDANG');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Selector Unit Tujuan
                    if (_tipeTujuan == 'RUANGAN') ...[
                      unitsAsync.when(
                        data: (units) {
                          final userUnitId = user?.unit?.id;
                          final filteredUnits = units.where((u) => u.id != userUnitId).toList();
                          if (_selectedUnitTujuanId == null && filteredUnits.isNotEmpty) {
                            _selectedUnitTujuanId = filteredUnits.first.id;
                          }
                          return DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: _selectedUnitTujuanId,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Ruangan Tujuan (Permanen) *',
                              prefixIcon: Icon(LucideIcons.building2, size: 18),
                            ),
                            items: filteredUnits.map((u) {
                              return DropdownMenuItem<int>(
                                value: u.id,
                                child: Text(
                                  u.nama,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedUnitTujuanId = val),
                            validator: (v) => v == null ? 'Pilih ruangan tujuan' : null,
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Gagal memuat unit'),
                      ),
                    ] else ...[
                      gudangsAsync.when(
                        data: (gudangs) {
                          if (_selectedGudangTujuanId == null && gudangs.isNotEmpty) {
                            _selectedGudangTujuanId = gudangs.first.id;
                          }
                          return DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: _selectedGudangTujuanId,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Gudang Logistik Tujuan *',
                              prefixIcon: Icon(LucideIcons.warehouse, size: 18),
                            ),
                            items: gudangs.map((g) {
                              return DropdownMenuItem<int>(
                                value: g.id,
                                child: Text(
                                  g.nama,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedGudangTujuanId = val),
                            validator: (v) => v == null ? 'Pilih gudang tujuan' : null,
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Gagal memuat gudang'),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Input Alasan
                    TextFormField(
                      key: const Key('field_alasan_pengalihan'),
                      controller: _alasanController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Alasan / Dasar Pengalihan (Wajib) *',
                        hintText: 'Jelaskan kebutuhan mutasi permanen aset ini...',
                        prefixIcon: Icon(LucideIcons.fileText, size: 18),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 5) {
                          return 'Alasan pengalihan wajib diisi minimal 5 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Input Catatan Opsional
                    TextFormField(
                      controller: _catatanController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Tambahan (Opsional)',
                        hintText: 'Kondisi fisik, kelengkapan kabel, aksesoris...',
                        prefixIcon: Icon(LucideIcons.messageSquare, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              CustomButton(
                text: 'Ajukan Pengalihan Aset',
                isLoading: actionState.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
