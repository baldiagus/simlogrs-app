import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/app_quantity_stepper.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../gudang/presentation/providers/persediaan_providers.dart';
import '../../../pengadaan/presentation/widgets/urgensi_selector_widget.dart';
import '../../data/models/amprah_model.dart';
import '../providers/distribusi_provider.dart';
import '../widgets/barang_amprah_picker_sheet.dart';
import '../../../../shared/widgets/empty_state_view.dart';

class FormPengajuanAmprahScreen extends ConsumerStatefulWidget {
  final BarangAmprahKatalogModel? initialBarang;

  const FormPengajuanAmprahScreen({
    super.key,
    this.initialBarang,
  });

  /// Membuat state form pengajuan amprah.
  @override
  ConsumerState<FormPengajuanAmprahScreen> createState() => _FormPengajuanAmprahScreenState();
}
class _FormPengajuanAmprahScreenState extends ConsumerState<FormPengajuanAmprahScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedGudangId;
  int _gudangDropdownVersion = 0;
  String _urgensi = 'REGULER';
  final List<AmprahCartDraftItem> _cartItems = [];
  final _catatanController = TextEditingController();
  /// Mengisi keranjang dengan barang awal (bila ada) agar pengguna tidak perlu memilih ulang.
  @override
  void initState() {
    super.initState();
    if (widget.initialBarang != null) {
      _cartItems.add(
        AmprahCartDraftItem(
          barang: widget.initialBarang!,
          jumlah: 1,
        ),
      );
    }
  }

  /// Membuang controller catatan agar tidak bocor memori saat form ditutup.
  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  /// Membuka bottom sheet katalog barang; barang yang dipilih ditambahkan ke keranjang atau jumlahnya bertambah bila sudah ada.
  void _openBarangPicker() {
    final gudangs = ref.read(masterGudangListProvider).asData?.value;
    final selectedGudang = gudangs?.where((g) => g.id == _selectedGudangId).firstOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarangAmprahPickerSheet(
        gudangId: _selectedGudangId,
        namaGudang: selectedGudang?.nama,
        onBarangSelected: (barang) async {
          final targetGudang = (barang.bestGudangId != null &&
                  barang.bestGudangStok != null &&
                  barang.bestGudangStok! > 0)
              ? barang.bestGudangId
              : _selectedGudangId;
          final resolvedBarang = (barang.bestGudangId == targetGudang &&
                  barang.bestGudangStok != null)
              ? barang.copyWith(stokTersedia: barang.bestGudangStok)
              : barang;
          if (barang.bestGudangId != null &&
              barang.bestGudangStok != null &&
              barang.bestGudangStok! > 0 &&
              barang.bestGudangId != _selectedGudangId) {
            if (_cartItems.isEmpty) {
              setState(() {
                _selectedGudangId = barang.bestGudangId;
                _gudangDropdownVersion++;
                _cartItems.add(AmprahCartDraftItem(barang: resolvedBarang));
              });
              AppToast.info(context, 'Gudang tujuan otomatis dialihkan ke ${barang.bestGudangNama ?? "gudang penyedia"}.');
            } else {
              final confirmed = await AppConfirmDialog.show(
                context,
                title: 'Ganti Gudang Tujuan?',
                message:
                    'Komoditas ${barang.nama} tersedia di ${barang.bestGudangNama}. Pengajuan amprah dalam satu dokumen harus ditujukan ke satu gudang yang sama. Ganti gudang tujuan dan mulai daftar baru?',
                confirmLabel: 'Ya, Ganti Gudang',
                confirmColor: AppColors.primaryPurple,
                icon: LucideIcons.arrowRightLeft,
              );
              if (confirmed && mounted) {
                setState(() {
                  _cartItems.clear();
                  _selectedGudangId = barang.bestGudangId;
                  _gudangDropdownVersion++;
                  _cartItems.add(AmprahCartDraftItem(barang: resolvedBarang));
                });
                AppToast.info(context, 'Gudang tujuan dialihkan ke ${barang.bestGudangNama}.');
              }
            }
          } else {
            setState(() {
              final idx = _cartItems.indexWhere((e) => e.barang.id == barang.id);
              if (idx >= 0) {
                _cartItems[idx].jumlah += 1;
              } else {
                _cartItems.add(AmprahCartDraftItem(barang: resolvedBarang));
              }
            });
          }
        },
      ),
    );
  }

  /// Memvalidasi form lalu mengirim pengajuan amprah; menutup layar dengan hasil true bila berhasil.
  Future<void> _submit() async {
    final user = ref.read(authStateProvider).user;
    if (user?.canAjukanAmprah != true) {
      AppToast.error(context, 'Akun Anda belum terhubung dengan unit ruangan atau gudang');
      return;
    }
    if (_cartItems.isEmpty) {
      AppToast.error(context, 'Pilih minimal 1 komoditas barang dari katalog amprah.');
      return;
    }
    // Tidak memblokir stok kosong atau melebihi stok: selisih otomatis menjadi backorder
    final notifier = ref.read(amprahActionProvider.notifier);

    final ok = await notifier.submitAmprah(
      gudangId: _selectedGudangId,
      urgensi: _urgensi,
      catatan: _catatanController.text.trim(),
      items: _cartItems,
    );

    if (!mounted) return;
    final state = ref.read(amprahActionProvider);

    if (ok) {
      AppToast.success(context, state.successMessage ?? 'Permintaan amprah berhasil diajukan.');
      Navigator.pop(context, true);
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal mengajukan amprah.');
    }
  }

  /// Membangun form pengajuan amprah: urgensi, keranjang barang, catatan, dan tombol kirim.
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final canAjukan = user?.canAjukanAmprah ?? false;
    final actionState = ref.watch(amprahActionProvider);
    final totalQty = _cartItems.fold<int>(0, (sum, i) => sum + i.jumlah);
    final gudangListAsync = ref.watch(masterGudangListProvider);
    final gudangs = gudangListAsync.asData?.value;
    if (gudangs != null && _selectedGudangId == null && gudangs.isNotEmpty) {
      _selectedGudangId = gudangs.first.id;
    }
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Pengajuan Amprah Ruangan'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: !canAjukan
                  ? const Center(
                      child: EmptyStateView(
                        icon: LucideIcons.building,
                        title: 'Tidak Dapat Mengajukan Amprah',
                        message: 'Akun Anda belum terhubung dengan unit ruangan atau gudang',
                      ),
                    )
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Unit Info Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.tintVioletBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.building, size: 18, color: AppColors.primaryPurple),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Unit Ruangan Pemohon',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    user?.unit?.nama ?? 'Ruangan Pengguna',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Warehouse Selection Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gudang Tujuan Logistik *',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            gudangListAsync.when(
                              data: (gudangList) {
                                return DropdownButtonFormField<int>(
                                  key: ValueKey('gudang_dropdown_${_selectedGudangId}_$_gudangDropdownVersion'),
                                  initialValue: _selectedGudangId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    prefixIcon: const Icon(LucideIcons.warehouse, size: 18, color: AppColors.primaryPurple),
                                  ),
                                  hint: const Text('Pilih gudang logistik...', style: TextStyle(fontSize: 13)),
                                  items: gudangList.map((g) {
                                    return DropdownMenuItem<int>(
                                      value: g.id,
                                      child: Text(
                                        g.nama,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newVal) async {
                                    if (newVal == null || newVal == _selectedGudangId) return;
                                    if (_cartItems.isNotEmpty) {
                                      final confirmed = await AppConfirmDialog.show(
                                        context,
                                        title: 'Konfirmasi Ubah Gudang',
                                        message:
                                            'Mengubah gudang logistik akan mengosongkan keranjang barang karena ketersediaan stok terikat pada gudang pilihan. Lanjutkan?',
                                        confirmLabel: 'Ya, Lanjutkan',
                                      );
                                      if (!mounted) return;
                                      if (confirmed) {
                                        setState(() {
                                          _cartItems.clear();
                                          _selectedGudangId = newVal;
                                          _gudangDropdownVersion++;
                                        });
                                      } else {
                                        setState(() {
                                          _gudangDropdownVersion++;
                                        });
                                      }
                                    } else {
                                      setState(() {
                                        _selectedGudangId = newVal;
                                        _gudangDropdownVersion++;
                                      });
                                    }
                                  },
                                  validator: (v) => v == null ? 'Pilih gudang tujuan logistik' : null,
                                );
                              },
                              loading: () => DropdownButtonFormField<int>(
                                items: const [],
                                onChanged: null,
                                isExpanded: true,
                                hint: const Text('Memuat daftar gudang...', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  prefixIcon: const Icon(LucideIcons.warehouse, size: 18, color: AppColors.primaryPurple),
                                ),
                              ),
                              error: (err, _) => Text(
                                'Gagal memuat daftar gudang: $err',
                                style: const TextStyle(fontSize: 12, color: AppColors.danger),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Urgensi Selector
                      UrgensiSelectorWidget(
                        selectedUrgensi: _urgensi,
                        onChanged: (u) => setState(() => _urgensi = u),
                      ),
                      const SizedBox(height: 22),

                      // Cart Header & Add Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Komoditas Diminta',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_cartItems.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.tintVioletBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_cartItems.length} SKU',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryPurple),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _openBarangPicker,
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text('Tambah'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryPurple,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_cartItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              const Icon(LucideIcons.packagePlus, size: 36, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum Ada Barang Dipilih',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Pilih komoditas barang habis pakai atau suku cadang dari katalog.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _openBarangPicker,
                                icon: const Icon(LucideIcons.plus, size: 16),
                                label: const Text('Pilih dari Katalog'),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._cartItems.map((cartItem) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cartItem.barang.nama,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${cartItem.barang.kode} • Stok Gudang: ${cartItem.barang.stokTersedia} ${cartItem.barang.satuan}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: cartItem.barang.stokTersedia > 0 ? AppColors.textSecondary : AppColors.danger,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                                      tooltip: 'Hapus',
                                      onPressed: () {
                                        setState(() => _cartItems.remove(cartItem));
                                      },
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Satuan: ${cartItem.barang.satuan}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            'Stok Gudang: ${cartItem.barang.stokTersedia} ${cartItem.barang.satuan}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: cartItem.barang.stokTersedia > 0
                                                  ? AppColors.textSecondary
                                                  : const Color(0xFFEA580C),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AppQuantityStepper(
                                      key: const Key('stepper_amprah_item'),
                                      value: cartItem.jumlah,
                                      min: 1,
                                      max: 9999,
                                      onChanged: (val) {
                                        if (val < 1) {
                                          setState(() => _cartItems.remove(cartItem));
                                        } else {
                                          setState(() => cartItem.jumlah = val);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                if (cartItem.barang.stokTersedia <= 0) ...[
                                  Container(
                                    margin: const EdgeInsets.only(top: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFDBA74).withValues(alpha: 0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.clock, size: 13, color: Color(0xFFEA580C)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Stok Gudang 0 • Permintaan ${cartItem.jumlah} ${cartItem.barang.satuan} akan dicatat sebagai Backorder (Hutang Gudang)',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFC2410C)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (cartItem.jumlah > cartItem.barang.stokTersedia) ...[
                                  Container(
                                    margin: const EdgeInsets.only(top: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFDBA74).withValues(alpha: 0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.info, size: 13, color: Color(0xFFEA580C)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Stok Gudang: ${cartItem.barang.stokTersedia} • Selisih ${cartItem.jumlah - cartItem.barang.stokTersedia} ${cartItem.barang.satuan} otomatis dicatat sebagai Backorder',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFC2410C)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 20),

                      // Catatan Pengajuan
                      const Text(
                        'Catatan Kebutuhan Ruangan:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _catatanController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Tuliskan peruntukan operasional atau catatan tambahan...',
                        ),
                      ),
                      const SizedBox(height: 24),
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
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Total Kebutuhan:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            '$totalQty Barang (${_cartItems.length} Jenis)',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Kirim Pengajuan Amprah',
                          isLoading: actionState.isLoading,
                          icon: const Icon(LucideIcons.send, size: 16, color: Colors.white),
                          onPressed: (_cartItems.isEmpty || !canAjukan) ? null : _submit,
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
