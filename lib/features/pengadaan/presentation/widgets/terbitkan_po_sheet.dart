import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_formatters.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/models/approval_item_model.dart';
import '../providers/approval_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../gudang/presentation/providers/inbound_provider.dart';
import '../providers/pengadaan_provider.dart';

class TerbitkanPoSheet extends ConsumerStatefulWidget {
  final ApprovalItemModel prItem;

  const TerbitkanPoSheet({super.key, required this.prItem});

  /// Menampilkan sheet penerbitan PO sebagai modal bottom sheet untuk PR yang dipilih.
  static Future<void> show(BuildContext context, ApprovalItemModel prItem) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TerbitkanPoSheet(prItem: prItem),
    );
  }

  /// Membuat state untuk sheet penerbitan PO.
  @override
  ConsumerState<TerbitkanPoSheet> createState() => _TerbitkanPoSheetState();
}

class _TerbitkanPoSheetState extends ConsumerState<TerbitkanPoSheet> {
  int? _selectedPemasokId;
  DateTime _estimasiKirim = DateTime.now().add(const Duration(days: 7));
  String _syaratBayar = 'TEMPO_30_HARI';
  final TextEditingController _catatanCtrl = TextEditingController();
  final Map<int, TextEditingController> _priceControllers = {};
  bool _isLoading = false;

  /// Menyiapkan kontroler harga tiap item PR sebagai nilai awal form.
  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.prItem.items.length; i++) {
      final it = widget.prItem.items[i];
      final defaultPrice = (it.hargaBeliTerakhir != null && it.hargaBeliTerakhir! > 0)
          ? it.hargaBeliTerakhir!
          : ((it.hargaEstimasi != null && it.hargaEstimasi! > 0)
              ? it.hargaEstimasi!
              : 0.0);
      final priceText = defaultPrice > 0 ? defaultPrice.toInt().toString() : '';
      _priceControllers[i] = TextEditingController(text: priceText);
    }
  }

  /// Membersihkan semua kontroler teks agar tidak terjadi kebocoran memori.
  @override
  void dispose() {
    _catatanCtrl.dispose();
    for (final ctrl in _priceControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  /// Menghitung total nilai PO dari harga satuan dikali jumlah tiap item.
  double _calculateTotal() {
    double total = 0;
    for (int i = 0; i < widget.prItem.items.length; i++) {
      final it = widget.prItem.items[i];
      final price = double.tryParse(_priceControllers[i]?.text.replaceAll('.', '') ?? '0') ?? 0;
      total += it.jumlah * price;
    }
    return total;
  }

  /// Memvalidasi form lalu mengirim permintaan penerbitan PO ke server
  /// dan menutup sheet bila berhasil.
  Future<void> _submitPo() async {
    if (_selectedPemasokId == null) {
      AppToast.error(context, 'Pilih rekanan / vendor pemasok terlebih dahulu.');
      return;
    }

    for (final it in widget.prItem.items) {
      if (it.barangId == null || it.barangId! <= 0) {
        AppToast.error(context, 'Item "${it.namaBarang}" tidak memiliki ID barang yang valid.');
        return;
      }
    }

    final itemsPayload = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.prItem.items.length; i++) {
      final it = widget.prItem.items[i];
      final price = double.tryParse(_priceControllers[i]?.text.replaceAll('.', '') ?? '0') ?? 0;
      if (price <= 0) {
        AppToast.error(context, 'Harga satuan untuk "${it.namaBarang}" wajib lebih dari 0.');
        return;
      }
      itemsPayload.add({
        'barang_id': it.barangId!,
        'jumlah': it.jumlah,
        'harga_satuan': price,
      });
    }

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(poActionProvider.notifier);
      final ok = await notifier.terbitkanPo(
        prId: widget.prItem.id,
        pemasokId: _selectedPemasokId!,
        estimasiTanggalKirim: _estimasiKirim.toIso8601String().substring(0, 10),
        syaratPembayaran: _syaratBayar,
        catatan: _catatanCtrl.text.trim(),
        items: itemsPayload,
      );

      if (mounted) {
        final state = ref.read(poActionProvider);
        if (ok) {
          AppToast.success(context, state.successMessage ?? 'PO Berhasil Diterbitkan!');
          Navigator.pop(context, true);
          ref.invalidate(approvalPendingProvider);
          ref.invalidate(poListProvider);
          ref.invalidate(daftarPrProvider);
          ref.invalidate(daftarPoInboundProvider);
          ref.invalidate(dashboardSummaryProvider);
        } else {
          AppToast.error(context, state.errorMessage ?? 'Gagal menerbitkan PO');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Membangun form penerbitan PO: pemilihan pemasok, harga item, syarat bayar, dan total.
  @override
  Widget build(BuildContext context) {
    final pemasokAsync = ref.watch(pemasokListProvider);


    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terbitkan Pesanan Pembelian (PO)',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Dasar PR: ${widget.prItem.kode} • ${widget.prItem.unit ?? "-"}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(tooltip: 'Tutup', icon: const Icon(LucideIcons.x, size: 18), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rekanan / Vendor Pemasok *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 6),
                  pemasokAsync.when(
                    // Membangun dropdown pilihan pemasok dari daftar vendor.
                    data: (vendors) {
                      return DropdownButtonFormField<int>(
                        initialValue: _selectedPemasokId,
                        isExpanded: true,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Pilih vendor rekanan...'),
                        items: vendors.map((v) {
                          return DropdownMenuItem(
                            value: v.id,
                            child: Text('${v.nama} (${v.kode})', style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedPemasokId = val),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text('Gagal memuat vendor: $err', style: const TextStyle(color: AppColors.danger)),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimasi Tgl Kirim', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(height: 6),
                            InkWell(
                              // Membuka pemilih tanggal untuk estimasi tanggal kirim.
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _estimasiKirim,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 180)),
                                );
                                if (d != null) setState(() => _estimasiKirim = d);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(AppFormatters.tanggal(_estimasiKirim), style: const TextStyle(fontSize: 12)),
                                    const Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                                  ],
                                ),
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
                            const Text('Syarat Bayar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _syaratBayar,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'TUNAI', child: Text('Tunai / Cash', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'TEMPO_30_HARI', child: Text('Tempo 30 Hari', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'TEMPO_60_HARI', child: Text('Tempo 60 Hari', style: TextStyle(fontSize: 12))),
                              ],
                              onChanged: (v) => setState(() => _syaratBayar = v ?? 'TEMPO_30_HARI'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const Text('Catatan / Instruksi Pengiriman:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _catatanCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Misal: Dikirim ke Gudang Sentral Lt.1...', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Daftar Barang & Negosiasi Harga', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      Text('${widget.prItem.items.length} Item', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...List.generate(widget.prItem.items.length, (idx) {
                    final it = widget.prItem.items[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(it.namaBarang, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
                              ),
                              Text('Qty: ${it.jumlah} ${it.satuan ?? "Pcs"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryPurple)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Harga Satuan: Rp ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Expanded(
                                child: TextField(
                                  controller: _priceControllers[idx],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    border: OutlineInputBorder(),
                                    hintText: '0',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          if (it.hargaBeliTerakhir != null && it.hargaBeliTerakhir! > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Harga beli terakhir: ${AppFormatters.rupiah(it.hargaBeliTerakhir!)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.tintVioletBg, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimasi Nilai Total PO:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryPurple)),
                        Text(AppFormatters.rupiah(_calculateTotal()), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primaryPurple)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          CustomButton(
            text: 'Konfirmasi Terbitkan PO',
            height: 46,
            backgroundColor: AppColors.primaryPurple,
            textColor: Colors.white,
            isLoading: _isLoading,
            icon: const Icon(LucideIcons.checkCheck, size: 18, color: Colors.white),
            onPressed: _submitPo,
          ),
        ],
      ),
    );
  }
}
