import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
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
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Barang Name & Order Info
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          draft.poItem.namaBarang,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${draft.poItem.kodeBarang} • Pesan: ${draft.poItem.jumlahDipesan} ${draft.poItem.satuan} (Sisa: ${draft.poItem.sisaKebutuhan})',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: 12),

                              // Qty & Batch Inputs Row
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Qty Diterima', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          initialValue: '${draft.jumlahDiterima}',
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) => draft.jumlahDiterima = int.tryParse(v) ?? 0,
                                          decoration: InputDecoration(
                                            suffixText: draft.poItem.satuan,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Nomor Batch Fisik', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          initialValue: draft.nomorBatch,
                                          onChanged: (v) => draft.nomorBatch = v.trim(),
                                          decoration: const InputDecoration(
                                            hintText: 'misal: B-1234',
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Shelf Location Picker & Expired Date Row
                              Row(
                                children: [
                                  // Shelf / Rak Dropdown
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Rak Simpan Gudang *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        rakListAsync.when(
                                          data: (raks) {
                                            if (draft.lokasiGudangId == null && raks.isNotEmpty) {
                                              draft.lokasiGudangId = raks.first.id;
                                            }
                                            return DropdownButtonFormField<int>(
                                              initialValue: draft.lokasiGudangId,
                                              isExpanded: true,
                                              decoration: const InputDecoration(
                                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              ),
                                              items: raks.map((r) {
                                                return DropdownMenuItem<int>(
                                                  value: r.id,
                                                  child: Text(
                                                    '${r.kode} (${r.nama})',
                                                    style: const TextStyle(fontSize: 12),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (val) {
                                                setState(() {
                                                  draft.lokasiGudangId = val;
                                                });
                                              },
                                            );
                                          },
                                          loading: () => const SizedBox(
                                            height: 40,
                                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                          ),
                                          error: (_, __) => const Text('Gagal memuat rak', style: TextStyle(fontSize: 11, color: AppColors.danger)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Expired Date Picker Button
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Tgl Expired (ED)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap: () => _pickExpiredDate(draft),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            height: 44,
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceSecondary,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    draft.tanggalKedaluwarsa ?? 'Non-Exp',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: draft.tanggalKedaluwarsa != null
                                                          ? AppColors.textPrimary
                                                          : AppColors.textMuted,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
