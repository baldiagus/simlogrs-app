import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/master_barang_model.dart';
import '../../data/models/pr_model.dart';
import '../providers/pengadaan_provider.dart';
import '../widgets/barang_picker_bottom_sheet.dart';
import '../widgets/pr_cart_item_tile.dart';
import '../widgets/urgensi_selector_widget.dart';

class FormPengajuanPrScreen extends ConsumerStatefulWidget {
  final MasterBarangModel? initialBarang;

  const FormPengajuanPrScreen({
    super.key,
    this.initialBarang,
  });

  @override
  ConsumerState<FormPengajuanPrScreen> createState() => _FormPengajuanPrScreenState();
}
class _FormPengajuanPrScreenState extends ConsumerState<FormPengajuanPrScreen> {
  String _urgensi = 'REGULER';
  final List<PrCartItemModel> _cartItems = [];
  final _catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialBarang != null) {
      _cartItems.add(PrCartItemModel(barang: widget.initialBarang!, jumlah: 1));
    }
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  void _openBarangPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarangPickerBottomSheet(
        onBarangSelected: (MasterBarangModel barang) {
          setState(() {
            final existingIndex = _cartItems.indexWhere((item) => item.barang.id == barang.id);
            if (existingIndex >= 0) {
              _cartItems[existingIndex].jumlah += 1;
            } else {
              _cartItems.add(PrCartItemModel(barang: barang));
            }
          });
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 barang dari katalog terlebih dahulu.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final user = ref.read(authStateProvider).user;
    final notifier = ref.read(prSubmissionProvider.notifier);

    final success = await notifier.submitPr(
      unitId: user?.unit?.id,
      urgensi: _urgensi,
      catatan: _catatanController.text.trim(),
      items: _cartItems,
    );

    if (!mounted) return;

    final state = ref.read(prSubmissionProvider);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage ?? 'Permintaan Pengadaan berhasil diajukan.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Gagal mengajukan PR.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(prSubmissionProvider);
    final user = ref.watch(authStateProvider).user;
    final totalQty = _cartItems.fold<int>(0, (sum, item) => sum + item.jumlah);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Pengajuan PR Baru'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Unit Info Pill Card
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
                                  'Unit Pemohon',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                Text(
                                  user?.unit?.nama ?? 'Unit Terdaftar',
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

                    // Urgensi Selector
                    UrgensiSelectorWidget(
                      selectedUrgensi: _urgensi,
                      onChanged: (u) => setState(() => _urgensi = u),
                    ),
                    const SizedBox(height: 22),

                    // Add Barang Button & Cart Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  'Daftar Barang',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
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
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryPurple,
                                    ),
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

                    // Empty cart notice or Items List
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
                            const Icon(
                              LucideIcons.packagePlus,
                              size: 36,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum Ada Barang Dipilih',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tekan tombol "+ Tambah Barang" untuk memilih dari katalog master.',
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
                      ..._cartItems.map(
                        (cartItem) => PrCartItemTile(
                          item: cartItem,
                          onQuantityChanged: (qty) {
                            setState(() {
                              cartItem.jumlah = qty;
                            });
                          },
                          onRemove: () {
                            setState(() {
                              _cartItems.remove(cartItem);
                            });
                          },
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Catatan Pengajuan
                    const Text(
                      'Catatan / Alasan Kebutuhan:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _catatanController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Tuliskan deskripsi kebutuhan pengadaan atau peruntukan operasional...',
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
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
                          const Text(
                            'Total:',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          Text(
                            '$totalQty Unit',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Kirim Pengajuan PR',
                          isLoading: submissionState.isLoading,
                          icon: const Icon(LucideIcons.send, size: 16, color: Colors.white),
                          onPressed: _cartItems.isEmpty ? null : _submit,
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
