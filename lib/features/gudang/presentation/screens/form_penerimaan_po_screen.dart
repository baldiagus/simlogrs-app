import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../widgets/inbound_item_draft_tile.dart';
import '../../data/models/po_inbound_model.dart';
import '../providers/gudang_provider.dart';
import '../providers/inbound_provider.dart';

class FormPenerimaanPoScreen extends ConsumerStatefulWidget {
  final PoInboundHeaderModel po;

  const FormPenerimaanPoScreen({
    super.key,
    required this.po,
  });

  @override
  ConsumerState<FormPenerimaanPoScreen> createState() => _FormPenerimaanPoScreenState();
}

class _FormPenerimaanPoScreenState extends ConsumerState<FormPenerimaanPoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _suratJalanController = TextEditingController();
  final _catatanController = TextEditingController();

  late final List<InboundItemDraft> _itemDrafts;
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _itemDrafts = widget.po.items.map((item) {
      return InboundItemDraft(
        poItem: item,
        jumlahDiterima: item.sisaKebutuhan,
        jumlahRusak: 0,
        nomorBatch: '',
        tanggalKedaluwarsa: null,
        lokasiGudangId: null,
      );
    }).toList();
  }

  @override
  void dispose() {
    _suratJalanController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiredDate(InboundItemDraft draft) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        draft.tanggalKedaluwarsa = _dateFormat.format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!widget.po.canReceive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PO belum dikirim oleh vendor, penerimaan fisik belum dapat diproses.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    for (final draft in _itemDrafts) {
      if (draft.jumlahDiterima > 0) {
        if (draft.nomorBatch.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nomor batch fisik wajib diisi untuk komoditas ${draft.poItem.namaBarang}.'),
              backgroundColor: AppColors.danger,
            ),
          );
          return;
        }
        if (draft.lokasiGudangId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rak simpan gudang wajib dipilih untuk komoditas ${draft.poItem.namaBarang}.'),
              backgroundColor: AppColors.danger,
            ),
          );
          return;
        }
      }
    }

    final notifier = ref.read(inboundActionProvider.notifier);
    final ok = await notifier.submitPenerimaan(
      poId: widget.po.id,
      nomorSuratJalan: _suratJalanController.text.trim(),
      catatan: _catatanController.text.trim(),
      items: _itemDrafts,
    );

    if (!mounted) return;
    final state = ref.read(inboundActionProvider);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage ?? 'Penerimaan berhasil disimpan.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Gagal memproses penerimaan.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rakListAsync = ref.watch(daftarRakProvider);
    final actionState = ref.watch(inboundActionProvider);
    final totalDiterima = _itemDrafts.fold<int>(0, (sum, i) => sum + i.jumlahDiterima);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Terima PO: ${widget.po.kodePo}'),
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
                      // Header PO Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryHeroGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.po.kodePo,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Tgl PO: ${widget.po.tanggalPo}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.po.pemasok,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: ${widget.po.totalItem} Jenis Komoditas Barang',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Surat Jalan Input
                      const Text(
                        'Nomor Surat Jalan Vendor *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _suratJalanController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'misal: SJ/PT-SLM/2026/089',
                          prefixIcon: Icon(LucideIcons.fileText, size: 18, color: AppColors.textSecondary),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nomor surat jalan vendor wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Catatan Umum
                      const Text(
                        'Catatan Inbound (Opsional):',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _catatanController,
                        decoration: const InputDecoration(
                          hintText: 'Kondisi segel kardus, nama kurir, atau ekspedisi...',
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Items Section Header
                      Row(
                        children: [
                          const Icon(LucideIcons.boxes, size: 18, color: AppColors.primaryPurple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pemeriksaan Fisik Barang (${_itemDrafts.length} Item)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // List Items Input
                      ..._itemDrafts.map((draft) {
                        return InboundItemDraftTile(
                          draft: draft,
                          rakListAsync: rakListAsync,
                          onPickExpiredDate: () => _pickExpiredDate(draft),
                          onRakChanged: (val) {
                            setState(() {
                              draft.lokasiGudangId = val;
                            });
                          },
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
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total Diterima:',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          Text(
                            '$totalDiterima Item',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Simpan ke Stok Gudang',
                          isLoading: actionState.isLoading,
                          icon: const Icon(LucideIcons.checkCheck, size: 18, color: Colors.white),
                          onPressed: _submit,
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
