import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/aset_tersedia_model.dart';
import '../providers/peminjaman_provider.dart';
import '../providers/pengalihan_provider.dart';
import 'modal_pengalihan_aset_tahap1_card.dart';
import 'modal_pengalihan_aset_tahap2_card.dart';

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
  ConsumerState<ModalPengalihanAsetSheet> createState() =>
      _ModalPengalihanAsetSheetState();
}

class _ModalPengalihanAsetSheetState
    extends ConsumerState<ModalPengalihanAsetSheet> {
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

    final unitAsalId =
        _chosenAset!.tipePenyedia == 'RUANGAN' ? _chosenAset!.penyediaId : null;
    final gudangAsalId =
        _chosenAset!.tipePenyedia == 'GUDANG' ? _chosenAset!.penyediaId : null;
    final tipeAsal = _chosenAset!.tipePenyedia;

    // Anti self-transfer guard
    if (tipeAsal == 'RUANGAN' &&
        tipeTujuan == 'RUANGAN' &&
        unitAsalId == unitTujuanId) {
      AppToast.error(context,
          'Unit asal dan unit tujuan pengalihan tidak boleh sama. Aset sudah berada di unit Anda.');
      return;
    }
    if (tipeAsal == 'GUDANG' &&
        tipeTujuan == 'GUDANG' &&
        gudangAsalId == gudangTujuanId) {
      AppToast.error(context,
          'Gudang asal dan gudang tujuan pengalihan tidak boleh sama.');
      return;
    }

    final katalogList =
        ref.read(katalogAsetPengalihanProvider('')).valueOrNull ?? [];
    final matchingAssets = katalogList
        .where((a) =>
            a.namaKomoditas.trim().toLowerCase() ==
                _chosenAset!.namaKomoditas.trim().toLowerCase() &&
            a.tipePenyedia == _chosenAset!.tipePenyedia &&
            a.penyediaId == _chosenAset!.penyediaId)
        .toList();

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
      if (_catatanController.text.trim().isNotEmpty)
        'catatan': _catatanController.text.trim(),
    };
    final notifier = ref.read(pengalihanActionProvider.notifier);
    final ok = await notifier.ajukanPengalihan(payload);

    if (!mounted) return;
    final state = ref.read(pengalihanActionProvider);

    if (ok) {
      AppToast.success(context,
          state.successMessage ?? 'Pengajuan pengalihan berhasil diajukan.');
      Navigator.pop(context, true);
    } else {
      AppToast.error(
          context, state.errorMessage ?? 'Gagal mengajukan pengalihan aset.');
    }
  }

  void _onAsetChanged(List<AsetTersediaModel> asets, int? val) {
    setState(() {
      _chosenAset = asets.firstWhere((a) => a.id == val);
      final count = asets
          .where((a) =>
              a.namaKomoditas.trim().toLowerCase() ==
                  _chosenAset!.namaKomoditas.trim().toLowerCase() &&
              a.tipePenyedia == _chosenAset!.tipePenyedia &&
              a.penyediaId == _chosenAset!.penyediaId)
          .length;
      _quantity = _quantity.clamp(1, count > 0 ? count : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final lokasiTujuanUser =
        user?.unit?.nama ?? (user?.gudang?.nama ?? 'Fasilitas Kerja Anda');
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
                      child: const Icon(LucideIcons.arrowRightLeft,
                          color: AppColors.primaryPurple, size: 22),
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
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                ModalPengalihanAsetTahap1Card(
                  lokasiTujuanUser: lokasiTujuanUser,
                  isAsetPreselected: widget.aset != null,
                  chosenAset: _chosenAset,
                  katalogAsync: katalogAsync,
                  onAsetChanged: _onAsetChanged,
                ),
                const SizedBox(height: 14),

                ModalPengalihanAsetTahap2Card(
                  chosenAset: _chosenAset,
                  katalogAsync: katalogAsync,
                  quantity: _quantity,
                  onQuantityChanged: (val) => setState(() => _quantity = val),
                  alasanController: _alasanController,
                  catatanController: _catatanController,
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
