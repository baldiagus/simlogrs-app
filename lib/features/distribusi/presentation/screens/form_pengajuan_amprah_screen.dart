import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pengadaan/presentation/widgets/urgensi_selector_widget.dart';
import '../../data/models/amprah_model.dart';
import '../providers/distribusi_provider.dart';
import '../widgets/barang_amprah_picker_sheet.dart';

class FormPengajuanAmprahScreen extends ConsumerStatefulWidget {
  final BarangAmprahKatalogModel? initialBarang;

  const FormPengajuanAmprahScreen({
    super.key,
    this.initialBarang,
  });

  @override
  ConsumerState<FormPengajuanAmprahScreen> createState() => _FormPengajuanAmprahScreenState();
}
class _FormPengajuanAmprahScreenState extends ConsumerState<FormPengajuanAmprahScreen> {
  final _formKey = GlobalKey<FormState>();
  String _urgensi = 'REGULER';
  final List<AmprahCartDraftItem> _cartItems = [];
  final _catatanController = TextEditingController();

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
      builder: (ctx) => BarangAmprahPickerSheet(
        onBarangSelected: (barang) {
          if (barang.stokTersedia <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Komoditas di gudang saat ini kosong (0). Tidak dapat diajukan amprah.'),
                backgroundColor: AppColors.danger,
              ),
            );
            return;
          }

          setState(() {
            final idx = _cartItems.indexWhere((e) => e.barang.id == barang.id);
            if (idx >= 0) {
              if (_cartItems[idx].jumlah < barang.stokTersedia) {
                _cartItems[idx].jumlah += 1;
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kuantitas "${barang.nama}" telah mencapai batas maksimal stok tersedia (${barang.stokTersedia} ${barang.satuan}).'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            } else {
              _cartItems.add(AmprahCartDraftItem(barang: barang));
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
          content: Text('Pilih minimal 1 komoditas barang dari katalog amprah.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    for (final item in _cartItems) {
      if (item.barang.stokTersedia <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Komoditas "${item.barang.nama}" di gudang saat ini kosong (0). Hapus barang ini sebelum mengirim.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      if (item.jumlah > item.barang.stokTersedia) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jumlah diminta untuk "${item.barang.nama}" (${item.jumlah} ${item.barang.satuan}) melebihi stok gudang (${item.barang.stokTersedia} ${item.barang.satuan}).'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(amprahActionProvider.notifier);

    final ok = await notifier.submitAmprah(
      urgensi: _urgensi,
      catatan: _catatanController.text.trim(),
      items: _cartItems,
    );

    if (!mounted) return;
    final state = ref.read(amprahActionProvider);

    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(state.successMessage ?? 'Permintaan amprah berhasil diajukan.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Gagal mengajukan amprah.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final actionState = ref.watch(amprahActionProvider);
    final totalQty = _cartItems.fold<int>(0, (sum, i) => sum + i.jumlah);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Pengajuan Amprah Ruangan'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Satuan: ${cartItem.barang.satuan}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Maksimal: ${cartItem.barang.stokTersedia} ${cartItem.barang.satuan}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: cartItem.jumlah >= cartItem.barang.stokTersedia
                                                ? AppColors.warning
                                                : AppColors.textMuted,
                                            fontWeight: cartItem.jumlah >= cartItem.barang.stokTersedia
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            if (cartItem.jumlah > 1) {
                                              setState(() => cartItem.jumlah--);
                                            } else {
                                              setState(() => _cartItems.remove(cartItem));
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(8)),
                                            child: const Icon(Icons.remove, size: 16),
                                          ),
                                        ),
                                        Container(
                                          constraints: const BoxConstraints(minWidth: 36),
                                          alignment: Alignment.center,
                                          child: Text('${cartItem.jumlah}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            if (cartItem.jumlah < cartItem.barang.stokTersedia) {
                                              setState(() => cartItem.jumlah++);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Kuantitas "${cartItem.barang.nama}" telah mencapai batas stok maksimal (${cartItem.barang.stokTersedia} ${cartItem.barang.satuan}).'),
                                                  backgroundColor: AppColors.warning,
                                                ),
                                              );
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: cartItem.jumlah >= cartItem.barang.stokTersedia
                                                  ? AppColors.surfaceSecondary.withValues(alpha: 0.5)
                                                  : AppColors.surfaceSecondary,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.add,
                                              size: 16,
                                              color: cartItem.jumlah >= cartItem.barang.stokTersedia
                                                  ? AppColors.textMuted
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

            // Bottom Sticky Submit Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total Kebutuhan:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text('$totalQty Unit', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Kirim Pengajuan Amprah',
                      isLoading: actionState.isLoading,
                      icon: const Icon(LucideIcons.send, size: 16, color: Colors.white),
                      onPressed: _cartItems.isEmpty ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
