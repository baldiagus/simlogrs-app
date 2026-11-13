import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../master/presentation/providers/master_barang_provider.dart';
import '../../data/models/rak_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../widgets/inbound_item_draft_tile.dart';
import '../widgets/modal_tolak_penerimaan_sheet.dart';
import '../widgets/rak_picker_bottom_sheet.dart';
import '../../data/models/po_inbound_model.dart';
import '../providers/gudang_provider.dart';
import '../providers/inbound_provider.dart';

/// Layar form penerimaan fisik barang untuk satu PO inbound ([po]) di gudang.
class FormPenerimaanPoScreen extends ConsumerStatefulWidget {
  final PoInboundHeaderModel po;

  /// Membuat form penerimaan untuk PO [po].
  const FormPenerimaanPoScreen({
    super.key,
    required this.po,
  });

  /// Membuat state form penerimaan PO.
  @override
  ConsumerState<FormPenerimaanPoScreen> createState() => _FormPenerimaanPoScreenState();
}

/// State form penerimaan PO; menyimpan draft item, input surat jalan/catatan, dan proses kirim penerimaan.
class _FormPenerimaanPoScreenState extends ConsumerState<FormPenerimaanPoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _suratJalanController = TextEditingController();
  final _catatanController = TextEditingController();

  late final List<InboundItemDraft> _itemDrafts;
  final _dateFormat = DateFormat('yyyy-MM-dd');
  int? _selectedGudangId;
  int _rackContextGeneration = 0;

  bool _canChooseGudang(UserModel? user) =>
      user != null && (user.hasRole('super_admin') || user.hasRole('admin_logistik'));

  int? _targetGudangId(UserModel? user) =>
      user?.gudang?.id ?? (_canChooseGudang(user) ? _selectedGudangId : null);

  void _clearRackSelections() {
    _rackContextGeneration++;
    for (final draft in _itemDrafts) {
      draft.lokasiGudangId = null;
    }
  }

  Future<void> _pickRak(InboundItemDraft draft) async {
    final user = ref.read(authStateProvider).user;
    final gudangId = _targetGudangId(user);
    final gudangs = ref.read(masterGudangListProvider);
    if (user == null || !user.canReceiveInbound || gudangId == null ||
        gudangs.isLoading || gudangs.hasError) {
      return;
    }
    final index = gudangs.requireValue.indexWhere((g) => g.id == gudangId);
    if (index < 0) return;
    final racks = ref.read(rakPenerimaanProvider(gudangId));
    if (racks.isLoading || racks.hasError || racks.requireValue.isEmpty) return;
    final generation = _rackContextGeneration;
    final selected = await showModalBottomSheet<RakModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RakPickerBottomSheet(
        gudangId: gudangId,
        namaGudang: gudangs.requireValue[index].nama,
        selectedRackId: draft.lokasiGudangId,
      ),
    );
    if (!mounted || selected == null) return;
    final currentUser = ref.read(authStateProvider).user;
    if (generation != _rackContextGeneration || currentUser?.id != user.id ||
        currentUser?.canReceiveInbound != true || _targetGudangId(currentUser) != gudangId) {
      AppToast.info(context, 'Konteks gudang berubah. Silakan pilih rak kembali.');
      return;
    }
    final currentGudangs = ref.read(masterGudangListProvider);
    final currentRacks = ref.read(rakPenerimaanProvider(gudangId));
    if (currentGudangs.isLoading || currentGudangs.hasError ||
        !(currentGudangs.asData?.value.any((g) => g.id == gudangId) ?? false) ||
        currentRacks.isLoading || currentRacks.hasError ||
        !(currentRacks.asData?.value.any((r) => r.id == selected.id &&
            r.gudangId == gudangId && r.status == 'AKTIF') ?? false)) {
      AppToast.info(context, 'Daftar rak berubah. Silakan pilih rak aktif kembali.');
      return;
    }
    setState(() => draft.lokasiGudangId = selected.id);
  }

  /// Menyiapkan draft penerimaan untuk tiap item PO saat form pertama kali dibuka.
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
    ref.listenManual<AuthState>(authStateProvider, (previous, next) {
      final before = previous?.user;
      final after = next.user;
      if ((before?.id, before?.gudang?.id, _canChooseGudang(before)) ==
          (after?.id, after?.gudang?.id, _canChooseGudang(after))) {
        return;
      }
      ref.invalidate(masterGudangListProvider);
      setState(() {
        _selectedGudangId = null;
        _clearRackSelections();
      });
    });
  }

  /// Membuang controller input agar tidak bocor memori.
  @override
  void dispose() {
    _suratJalanController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  /// Menampilkan pemilih tanggal dan menyimpan tanggal kedaluwarsa terpilih ke [draft].
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

  /// Memvalidasi wewenang, status PO, dan isian item lalu mengirim penerimaan ke server; sukses menutup layar dengan hasil `true`.
  Future<void> _submit() async {
    final user = ref.read(authStateProvider).user;
    if (!(user?.canReceiveInbound ?? false)) {
      AppToast.error(context, 'Anda tidak memiliki wewenang untuk menerima PO gudang.');
      return;
    }
    if (!widget.po.canReceive) {
      AppToast.error(context, 'PO belum dikirim oleh vendor, penerimaan fisik belum dapat diproses.');
      return;
    }
    final gudangId = _targetGudangId(user);
    final gudangs = ref.read(masterGudangListProvider);
    if (gudangId == null || gudangs.isLoading || gudangs.hasError ||
        !(gudangs.asData?.value.any((g) => g.id == gudangId) ?? false)) {
      AppToast.error(context, 'Pilih gudang penerima yang aktif sebelum menyimpan.');
      return;
    }
    final racks = ref.read(rakPenerimaanProvider(gudangId));
    if (racks.isLoading || racks.hasError || (racks.asData?.value.isEmpty ?? true)) {
      AppToast.error(context, 'Opsi rak belum tersedia. Muat ulang rak gudang penerima.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final totalDiterima = _itemDrafts.fold<int>(0, (sum, i) => sum + i.jumlahDiterima);
    if (totalDiterima <= 0) {
      AppToast.error(context, 'Kuantitas barang yang diterima minimal 1 item.');
      return;
    }
    for (final draft in _itemDrafts) {
      if (draft.jumlahDiterima > 0) {
        if (draft.nomorBatch.trim().isEmpty) {
          AppToast.error(context, 'Nomor batch fisik wajib diisi untuk komoditas ${draft.poItem.namaBarang}.');
          return;
        }
        if (!racks.requireValue.any((r) => r.id == draft.lokasiGudangId &&
            r.gudangId == gudangId && r.status == 'AKTIF')) {
          AppToast.error(context, 'Pilih rak aktif di gudang penerima untuk komoditas ${draft.poItem.namaBarang}.');
          return;
        }
      }
    }

    final notifier = ref.read(inboundActionProvider.notifier);
    final ok = await notifier.submitPenerimaan(
      poId: widget.po.id,
      gudangId: gudangId,
      nomorSuratJalan: _suratJalanController.text.trim(),
      catatan: _catatanController.text.trim(),
      items: _itemDrafts,
    );

    if (!mounted) return;
    final state = ref.read(inboundActionProvider);

    if (ok) {
      AppToast.success(context, state.successMessage ?? 'Penerimaan berhasil disimpan.');
      Navigator.pop(context, true);
    } else {
      if (state.statusCode == 422) {
        ref.invalidate(rakPenerimaanProvider(gudangId));
        ref.invalidate(masterGudangListProvider);
      }
      AppToast.error(context, state.errorMessage ?? 'Gagal memproses penerimaan.');
    }
  }

  /// Membuka sheet penolakan kiriman fisik vendor; jika berhasil ditolak, menutup layar dengan hasil `true`.
  Future<void> _tolakKiriman() async {
    final rejected = await ModalTolakPenerimaanSheet.show(
      context,
      po: widget.po,
      nomorSuratJalanAwal: _suratJalanController.text.trim(),
    );
    if (rejected == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _allocationStatus(String message, {VoidCallback? retry, String? retryLabel}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        if (retry != null)
          TextButton(onPressed: retry, child: Text(retryLabel!)),
      ],
    );
  }

  Widget _buildGudangContext(UserModel? user, AsyncValue<List<GudangModel>> gudangs) {
    if (user?.gudang == null && !_canChooseGudang(user)) {
      return _allocationStatus('Penugasan gudang belum tersedia. Hubungi administrator.');
    }
    void retry() => ref.invalidate(masterGudangListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Gudang Penerima', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        if (user?.gudang != null)
          Text('${user!.gudang!.nama} (sesuai penugasan akun)'),
        if (gudangs.isLoading)
          _allocationStatus('Memuat gudang penerima...')
        else if (gudangs.hasError)
          _allocationStatus('Gagal memuat gudang penerima.', retry: retry, retryLabel: 'Coba lagi gudang')
        else if (gudangs.requireValue.isEmpty)
          _allocationStatus('Tidak ada gudang aktif tersedia.', retry: retry, retryLabel: 'Coba lagi gudang')
        else if (user?.gudang != null &&
            !gudangs.requireValue.any((g) => g.id == user!.gudang!.id))
          _allocationStatus('Gudang penugasan tidak aktif atau tidak tersedia. Hubungi administrator.',
              retry: retry, retryLabel: 'Coba lagi gudang')
        else if (user?.gudang == null)
          SizedBox(
            key: const ValueKey('gudang-penerimaan-selector'),
            child: DropdownButtonFormField<int>(
              key: ValueKey('gudang-$_selectedGudangId-${gudangs.requireValue.map((g) => g.id).join(',')}'),
              initialValue: gudangs.requireValue.any((g) => g.id == _selectedGudangId) ? _selectedGudangId : null,
              isExpanded: true,
              hint: const Text('Pilih gudang penerima'),
              items: gudangs.requireValue.map((g) => DropdownMenuItem(
                value: g.id,
                child: Text(g.nama, maxLines: 1, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (value) {
                if (value == _selectedGudangId) return;
                setState(() {
                  _selectedGudangId = value;
                  _clearRackSelections();
                });
              },
            ),
          ),
      ],
    );
  }

  /// Menyusun UI form penerimaan: info PO, surat jalan, daftar draft item (batch, rak, kuantitas), dan tombol simpan/tolak.
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final gudangs = ref.watch(masterGudangListProvider);
    final gudangId = _targetGudangId(user);
    final validGudang = gudangId != null && !gudangs.isLoading && !gudangs.hasError &&
        (gudangs.asData?.value.any((g) => g.id == gudangId) ?? false);
    final rakListAsync = validGudang
        ? ref.watch(rakPenerimaanProvider(gudangId))
        : const AsyncValue<List<RakModel>>.data([]);
    final validRacks = !rakListAsync.isLoading && !rakListAsync.hasError &&
        (rakListAsync.asData?.value.isNotEmpty ?? false);
    final canSave = validGudang && validRacks && _itemDrafts.where((d) => d.jumlahDiterima > 0).every(
      (d) => rakListAsync.requireValue.any((r) =>
          r.id == d.lokasiGudangId && r.gudangId == gudangId && r.status == 'AKTIF'),
    );
    final actionState = ref.watch(inboundActionProvider);
    final totalDiterima = _itemDrafts.fold<int>(0, (sum, i) => sum + i.jumlahDiterima);
    final totalJenisDiterima = _itemDrafts.where((i) => i.jumlahDiterima > 0).length;
    final canReceive = user?.canReceiveInbound ?? false;
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
                                Flexible(
                                  child: Container(
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                      _buildGudangContext(user, gudangs),
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
                          gudangPenerimaId: gudangId,
                          namaGudangPenerima: validGudang
                              ? gudangs.requireValue.firstWhere((g) => g.id == gudangId).nama
                              : null,
                          rakUnavailableMessage: validGudang ? null : 'Pilih gudang penerima yang aktif terlebih dahulu.',
                          onRetryRak: validGudang ? () => ref.invalidate(rakPenerimaanProvider(gudangId)) : null,
                          onPickExpiredDate: () => _pickExpiredDate(draft),
                          onPickRak: () => _pickRak(draft),
                          onQuantityChanged: (val) {
                            setState(() {
                              draft.jumlahDiterima = val;
                              if (draft.jumlahRusak > val) {
                                draft.jumlahRusak = val;
                              }
                            });
                          },
                          onRusakChanged: (val) => setState(() => draft.jumlahRusak = val),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Diterima:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '$totalDiterima Barang ($totalJenisDiterima Jenis)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (canReceive)
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Tolak Kiriman Vendor',
                                isOutlined: true,
                                backgroundColor: AppColors.danger,
                                textColor: AppColors.danger,
                                icon: const Icon(LucideIcons.ban, size: 16, color: AppColors.danger),
                                onPressed: _tolakKiriman,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomButton(
                                text: 'Simpan ke Stok Gudang',
                                isLoading: actionState.isLoading,
                                backgroundColor: AppColors.primaryPurple,
                                icon: const Icon(LucideIcons.checkCheck, size: 16, color: Colors.white),
                                onPressed: canSave ? _submit : null,
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Mode Peninjauan (Hanya Lihat)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
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
