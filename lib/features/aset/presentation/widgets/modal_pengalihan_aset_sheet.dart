import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/app_quantity_stepper.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/aset_tersedia_model.dart';
import '../providers/peminjaman_provider.dart';
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
  int _quantity = 1;

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

    final isRuangan = user?.unit != null;
    final unitTujuanId = isRuangan ? user?.unit?.id : null;
    final gudangTujuanId = !isRuangan ? user?.gudang?.id : null;
    final tipeTujuan = isRuangan ? 'RUANGAN' : 'GUDANG';

    final unitAsalId = _chosenAset!.tipePenyedia == 'RUANGAN' ? _chosenAset!.penyediaId : null;
    final gudangAsalId = _chosenAset!.tipePenyedia == 'GUDANG' ? _chosenAset!.penyediaId : null;
    final tipeAsal = _chosenAset!.tipePenyedia;

    // Anti self-transfer guard
    if (tipeAsal == 'RUANGAN' && tipeTujuan == 'RUANGAN' && unitAsalId == unitTujuanId) {
      AppToast.error(context, 'Unit asal dan unit tujuan pengalihan tidak boleh sama. Aset sudah berada di unit Anda.');
      return;
    }
    if (tipeAsal == 'GUDANG' && tipeTujuan == 'GUDANG' && gudangAsalId == gudangTujuanId) {
      AppToast.error(context, 'Gudang asal dan gudang tujuan pengalihan tidak boleh sama.');
      return;
    }

    final katalogList = ref.read(katalogAsetPengalihanProvider('')).valueOrNull ?? [];
    final matchingAssets = katalogList.where((a) =>
      a.namaKomoditas.trim().toLowerCase() == _chosenAset!.namaKomoditas.trim().toLowerCase() &&
      a.tipePenyedia == _chosenAset!.tipePenyedia &&
      a.penyediaId == _chosenAset!.penyediaId
    ).toList();

    final List<int> selectedAsetIds = [_chosenAset!.id];
    for (final extra in matchingAssets) {
      if (selectedAsetIds.length >= _quantity) break;
      if (!selectedAsetIds.contains(extra.id)) {
        selectedAsetIds.add(extra.id);
      }
    }

    final payload = {
      'tipe_tujuan': tipeTujuan,
      'unit_tujuan_id': unitTujuanId,
      'gudang_tujuan_id': gudangTujuanId,
      'unit_asal_id': unitAsalId,
      'gudang_asal_id': gudangAsalId,
      'tipe_asal': tipeAsal,
      'aset_ids': selectedAsetIds,
      'jumlah': selectedAsetIds.length,
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
    final lokasiTujuanUser = user?.unit?.nama ?? (user?.gudang?.nama ?? 'Fasilitas Kerja Anda');
    final katalogAsync = ref.watch(katalogAsetPengalihanProvider(''));
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Form Pengalihan Aset RS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ajukan mutasi permanen aset dari fasilitas lain ke unit kerja Anda',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ================= Tahap 1: Komoditas & Fasilitas Asal =================
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
                        'Tahap 1: Komoditas & Fasilitas Asal (Sumber)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.lock, size: 13, color: AppColors.textMuted),
                              SizedBox(width: 5),
                              Text(
                                'Lokasi Tujuan (Terkunci):',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            lokasiTujuanUser,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Pilihan Aset Sumber
                      if (widget.aset != null && _chosenAset != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _chosenAset!.namaKomoditas,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.tintVioletBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _chosenAset!.tipePenyedia,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryPurple),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kode: ${_chosenAset!.kodeAset} • SN: ${_chosenAset!.nomorSeri}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fasilitas Asal (Sumber): ${_chosenAset!.namaPenyedia}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        katalogAsync.when(
                          data: (asets) {
                            if (asets.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Tidak ada aset fisik tersedia dari fasilitas lain yang siap dialihkan.',
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
                                    labelText: 'Pilih Aset dari Fasilitas Lain (Sumber) *',
                                    prefixIcon: Icon(LucideIcons.armchair, size: 18),
                                  ),
                                  selectedItemBuilder: (context) {
                                    return asets.map((a) {
                                      return Text(
                                        '${a.namaKomoditas} (${a.kodeAset}) - ${a.namaPenyedia}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }).toList();
                                  },
                                  items: asets.map((a) {
                                    return DropdownMenuItem<int>(
                                      value: a.id,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    a.namaKomoditas,
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.tintVioletBg,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    a.tipePenyedia,
                                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primaryPurple),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${a.kodeAset} • ${a.namaPenyedia}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _chosenAset = asets.firstWhere((a) => a.id == val);
                                      final count = asets.where((a) =>
                                        a.namaKomoditas.trim().toLowerCase() == _chosenAset!.namaKomoditas.trim().toLowerCase() &&
                                        a.tipePenyedia == _chosenAset!.tipePenyedia &&
                                        a.penyediaId == _chosenAset!.penyediaId
                                      ).length;
                                      _quantity = _quantity.clamp(1, count > 0 ? count : 1);
                                    });
                                  },
                                ),
                                if (_chosenAset != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _chosenAset!.namaKomoditas,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.tintVioletBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _chosenAset!.tipePenyedia,
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryPurple),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Kode: ${_chosenAset!.kodeAset} • SN: ${_chosenAset!.nomorSeri}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Fasilitas Asal (Sumber): ${_chosenAset!.namaPenyedia} • Kondisi: ${_chosenAset!.kondisi}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('Gagal memuat katalog aset tersedia'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ================= Tahap 2: Kuantitas & Alasan =================
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
                        'Tahap 2: Kuantitas & Alasan',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),

                      // Stepper Kuantitas
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Jumlah Unit Dialihkan *',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Builder(
                                    builder: (context) {
                                      final list = katalogAsync.valueOrNull ?? [];
                                      final count = _chosenAset != null
                                          ? list.where((a) =>
                                              a.namaKomoditas.trim().toLowerCase() == _chosenAset!.namaKomoditas.trim().toLowerCase() &&
                                              a.tipePenyedia == _chosenAset!.tipePenyedia &&
                                              a.penyediaId == _chosenAset!.penyediaId
                                            ).length
                                          : 1;
                                      final maxAvailable = count > 0 ? count : 1;
                                      return Text(
                                        _chosenAset != null && maxAvailable > 1
                                            ? 'Tersedia: $maxAvailable unit di ${_chosenAset!.namaPenyedia}'
                                            : '1 unit per nomor inventaris fisik',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Builder(
                              builder: (context) {
                                final list = katalogAsync.valueOrNull ?? [];
                                final count = _chosenAset != null
                                    ? list.where((a) =>
                                        a.namaKomoditas.trim().toLowerCase() == _chosenAset!.namaKomoditas.trim().toLowerCase() &&
                                        a.tipePenyedia == _chosenAset!.tipePenyedia &&
                                        a.penyediaId == _chosenAset!.penyediaId
                                      ).length
                                    : 1;
                                final maxAvailable = count > 0 ? count : 1;
                                return AppQuantityStepper(
                                  key: const Key('stepper_jumlah_aset'),
                                  value: _quantity.clamp(1, maxAvailable),
                                  min: 1,
                                  max: maxAvailable,
                                  onChanged: (val) => setState(() => _quantity = val),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Alasan
                      TextFormField(
                        key: const Key('field_alasan_pengalihan'),
                        controller: _alasanController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Alasan / Dasar Pengalihan (Wajib) *',
                          hintText: 'Jelaskan kebutuhan mutasi permanen ke unit kerja Anda...',
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

                      // Catatan
                      TextFormField(
                        controller: _catatanController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Tambahan (Opsional)',
                          hintText: 'Kondisi fisik awal, kelengkapan kabel, aksesoris...',
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
