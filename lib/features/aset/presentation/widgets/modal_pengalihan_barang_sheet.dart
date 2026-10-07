import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../master/presentation/providers/master_barang_provider.dart';
import '../providers/pengalihan_provider.dart';

class ModalPengalihanBarangSheet extends ConsumerStatefulWidget {
  const ModalPengalihanBarangSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ModalPengalihanBarangSheet(),
    );
  }

  @override
  ConsumerState<ModalPengalihanBarangSheet> createState() => _ModalPengalihanBarangSheetState();
}

class _ModalPengalihanBarangSheetState extends ConsumerState<ModalPengalihanBarangSheet> {
  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();
  final _catatanController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  int? _selectedBarangId;
  int? _selectedGudangAsalId;

  @override
  void dispose() {
    _alasanController.dispose();
    _catatanController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(authStateProvider).user;
    final gudangTujuanId = user?.gudang?.id;

    if (_selectedGudangAsalId == null) {
      AppToast.error(context, 'Pilih fasilitas gudang asal penyedia barang.');
      return;
    }

    if (gudangTujuanId != null && _selectedGudangAsalId == gudangTujuanId) {
      AppToast.error(context, 'Gudang asal dan gudang tujuan pengalihan tidak boleh sama.');
      return;
    }

    final jumlah = int.tryParse(_quantityController.text.trim()) ?? 1;

    final payload = {
      'barang_id': _selectedBarangId,
      'gudang_asal_id': _selectedGudangAsalId,
      'gudang_tujuan_id': gudangTujuanId,
      'jumlah': jumlah,
      'tanggal_pengalihan': DateTime.now().toIso8601String().substring(0, 10),
      'alasan': _alasanController.text.trim(),
      if (_catatanController.text.trim().isNotEmpty) 'catatan': _catatanController.text.trim(),
    };

    final notifier = ref.read(pengalihanActionProvider.notifier);
    final ok = await notifier.ajukanPengalihanBarang(payload);

    if (!mounted) return;
    final state = ref.read(pengalihanActionProvider);

    if (ok) {
      AppToast.success(context, state.successMessage ?? 'Pengalihan barang berhasil diajukan.');
      Navigator.pop(context, true);
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal mengajukan pengalihan barang.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final gudangTujuanNama = user?.gudang?.nama ?? 'Fasilitas Gudang Pengguna';
    final barangAsync = ref.watch(masterBarangListProvider);
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
                      decoration: const BoxDecoration(
                        color: AppColors.tintBlueBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.boxes, color: AppColors.tintBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengalihan Barang Gudang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Transfer persediaan logistik & BHP antar fasilitas gudang',
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
                        'Tahap 1: Komoditas & Fasilitas Asal',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),

                      // Locked Gudang Tujuan
                      Row(
                        children: [
                          const Icon(LucideIcons.lock, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          const Text(
                            'Gudang Tujuan (Terkunci): ',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                          ),
                          Expanded(
                            child: Text(
                              gudangTujuanNama,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dropdown Komoditas Barang
                      barangAsync.when(
                        data: (items) {
                          final consumableItems = items.where((b) => b.tipe != 'ASET').toList();
                          return DropdownButtonFormField<int>(
                            key: const Key('dropdown_barang_logistik'),
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Komoditas Barang (BHP/Logistik) *',
                              prefixIcon: Icon(LucideIcons.package, size: 18),
                            ),
                            items: consumableItems.map((b) {
                              return DropdownMenuItem<int>(
                                value: b.id,
                                child: Text(
                                  '${b.nama} (${b.kode})',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedBarangId = val),
                            validator: (v) => v == null ? 'Pilih komoditas barang' : null,
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Gagal memuat daftar barang'),
                      ),
                      const SizedBox(height: 12),

                      // Dropdown Gudang Asal Penyedia (Eksklusi Gudang Sendiri)
                      gudangsAsync.when(
                        data: (gudangs) {
                          final userGudangId = user?.gudang?.id;
                          final availableGudangs = gudangs.where((g) => g.id != userGudangId).toList();
                          return DropdownButtonFormField<int>(
                            key: const Key('dropdown_gudang_asal_barang'),
                            isExpanded: true,
                            initialValue: _selectedGudangAsalId,
                            decoration: const InputDecoration(
                              labelText: 'Gudang Asal Penyedia (Sumber) *',
                              prefixIcon: Icon(LucideIcons.warehouse, size: 18),
                            ),
                            items: availableGudangs.map((g) {
                              return DropdownMenuItem<int>(
                                value: g.id,
                                child: Text(
                                  g.nama,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedGudangAsalId = val),
                            validator: (v) => v == null ? 'Pilih gudang asal penyedia' : null,
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Gagal memuat gudang asal'),
                      ),
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

                      // Jumlah Unit
                      TextFormField(
                        key: const Key('field_jumlah_barang'),
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Kuantitas Dialihkan *',
                          prefixIcon: Icon(LucideIcons.hash, size: 18),
                        ),
                        validator: (v) {
                          final parsed = int.tryParse(v?.trim() ?? '');
                          if (parsed == null || parsed < 1) {
                            return 'Jumlah kuantitas minimal 1';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Alasan
                      TextFormField(
                        key: const Key('field_alasan_barang'),
                        controller: _alasanController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Alasan / Dasar Pengalihan (Wajib) *',
                          hintText: 'Jelaskan kebutuhan pengalihan persediaan logistik ini...',
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

                      // Catatan Opsional
                      TextFormField(
                        controller: _catatanController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Tambahan (Opsional)',
                          hintText: 'Nomor batch, kondisi kemasan, instruksi pengiriman...',
                          prefixIcon: Icon(LucideIcons.messageSquare, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                CustomButton(
                  text: 'Ajukan Pengalihan Barang',
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
