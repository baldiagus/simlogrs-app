import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/aset_tersedia_model.dart';
import '../providers/peminjaman_provider.dart';
import '../widgets/aset_picker_bottom_sheet.dart';

class FormPeminjamanAsetScreen extends ConsumerStatefulWidget {
  final AsetTersediaModel? preselectedAset;

  const FormPeminjamanAsetScreen({
    super.key,
    this.preselectedAset,
  });

  @override
  ConsumerState<FormPeminjamanAsetScreen> createState() => _FormPeminjamanAsetScreenState();
}

class _FormPeminjamanAsetScreenState extends ConsumerState<FormPeminjamanAsetScreen> {
  final _formKey = GlobalKey<FormState>();
  AsetTersediaModel? _selectedAset;

  DateTime _tanggalPinjam = DateTime.now();
  DateTime _tanggalKembaliRencana = DateTime.now().add(const Duration(days: 3));

  final _keperluanController = TextEditingController();
  final _catatanController = TextEditingController();

  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _selectedAset = widget.preselectedAset;
  }

  @override
  void dispose() {
    _keperluanController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _openAsetPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AsetPickerBottomSheet(
        onAsetSelected: (aset) {
          setState(() {
            _selectedAset = aset;
          });
        },
      ),
    );
  }

  Future<void> _pickDate({required bool isTanggalPinjam}) async {
    final initialDate = isTanggalPinjam ? _tanggalPinjam : _tanggalKembaliRencana;
    final firstDate = isTanggalPinjam ? DateTime.now().subtract(const Duration(days: 1)) : _tanggalPinjam;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );

    if (picked != null) {
      setState(() {
        if (isTanggalPinjam) {
          _tanggalPinjam = picked;
          if (_tanggalKembaliRencana.isBefore(_tanggalPinjam)) {
            _tanggalKembaliRencana = _tanggalPinjam.add(const Duration(days: 1));
          }
        } else {
          _tanggalKembaliRencana = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedAset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih sarana / aset yang ingin dipinjam terlebih dahulu.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final notifier = ref.read(peminjamanActionProvider.notifier);
    final ok = await notifier.ajukanPeminjaman(
      asetId: _selectedAset!.id,
      tanggalPinjam: _dateFormat.format(_tanggalPinjam),
      tanggalKembaliRencana: _dateFormat.format(_tanggalKembaliRencana),
      keperluan: _keperluanController.text.trim(),
      catatan: _catatanController.text.trim(),
    );

    if (!mounted) return;
    final state = ref.read(peminjamanActionProvider);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage ?? 'Peminjaman berhasil diajukan.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Gagal mengajukan peminjaman.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(peminjamanActionProvider);
    final user = ref.watch(authStateProvider).user;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Pengajuan Pinjam Aset'),
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
                      // Unit Peminjam Card
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
                                    'Unit Peminjam',
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

                      // Selected Aset Card / Picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Aset yang Dipinjam',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _openAsetPicker,
                            icon: const Icon(LucideIcons.search, size: 15),
                            label: Text(_selectedAset == null ? 'Pilih Aset' : 'Ganti Aset'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryPurple,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      if (_selectedAset == null)
                        InkWell(
                          onTap: _openAsetPicker,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                            ),
                            child: const Column(
                              children: [
                                Icon(LucideIcons.armchair, size: 32, color: AppColors.primaryPurple),
                                SizedBox(height: 8),
                                Text(
                                  'Tekan untuk Memilih Aset Siap Pinjam',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryPurple),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Pilih dari ruangan lain atau gudang sentral',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primaryPurple, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.tintOrangeBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(LucideIcons.armchair, size: 22, color: AppColors.tintOrange),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedAset!.namaKomoditas,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_selectedAset!.kodeAset} • SN: ${_selectedAset!.nomorSeri}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Penyedia: ${_selectedAset!.namaPenyedia}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.primaryPurple, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _selectedAset = null),
                                icon: const Icon(LucideIcons.x, size: 18, color: AppColors.danger),
                                tooltip: 'Batalkan Pilihan',
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Dates Pickers Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tanggal Pinjam',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _pickDate(isTanggalPinjam: true),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.calendar, size: 16, color: AppColors.primaryPurple),
                                        const SizedBox(width: 8),
                                        Text(
                                          _dateFormat.format(_tanggalPinjam),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
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
                                const Text(
                                  'Rencana Kembali',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _pickDate(isTanggalPinjam: false),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.calendarCheck, size: 16, color: AppColors.primaryPurple),
                                        const SizedBox(width: 8),
                                        Text(
                                          _dateFormat.format(_tanggalKembaliRencana),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Keperluan Peminjaman
                      const Text(
                        'Keperluan Peminjaman *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _keperluanController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Tuliskan alasan peruntukan alat atau pelayanan pasien...',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Keperluan peminjaman wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Catatan Tambahan
                      const Text(
                        'Catatan Tambahan (Opsional):',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _catatanController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Kelengkapan atau petunjuk penggunaan khusus...',
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Sticky Bar - Full Width White Background
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: CustomButton(
                    width: double.infinity,
                    text: 'Kirim Permohonan Pinjam',
                    isLoading: actionState.isLoading,
                    icon: const Icon(LucideIcons.send, size: 18, color: Colors.white),
                    onPressed: _submit,
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
