import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/app_date_picker_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../providers/peminjaman_provider.dart';

class ModalPerpanjangPeminjamanSheet extends ConsumerStatefulWidget {
  final int peminjamanId;
  final String kodeDokumen;
  final String? tanggalKembaliSaatIni;
  final VoidCallback? onSuccess;

  const ModalPerpanjangPeminjamanSheet({
    super.key,
    required this.peminjamanId,
    required this.kodeDokumen,
    this.tanggalKembaliSaatIni,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required int peminjamanId,
    required String kodeDokumen,
    String? tanggalKembaliSaatIni,
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalPerpanjangPeminjamanSheet(
        peminjamanId: peminjamanId,
        kodeDokumen: kodeDokumen,
        tanggalKembaliSaatIni: tanggalKembaliSaatIni,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<ModalPerpanjangPeminjamanSheet> createState() =>
      _ModalPerpanjangPeminjamanSheetState();
}

class _ModalPerpanjangPeminjamanSheetState
    extends ConsumerState<ModalPerpanjangPeminjamanSheet> {
  late DateTime _selectedDate;
  final TextEditingController _alasanController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    DateTime currentRencana;
    try {
      currentRencana = DateTime.parse(widget.tanggalKembaliSaatIni ?? '');
    } catch (_) {
      currentRencana = DateTime.now();
    }
    _selectedDate = currentRencana.add(const Duration(days: 7));
    if (_selectedDate.isBefore(DateTime.now().add(const Duration(days: 1)))) {
      _selectedDate = DateTime.now().add(const Duration(days: 7));
    }
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final alasan = _alasanController.text.trim();
    if (alasan.isEmpty) {
      AppToast.error(context, 'Alasan perpanjangan wajib dicantumkan.');
      return;
    }

    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);

    final notifier = ref.read(peminjamanActionProvider.notifier);
    final ok = await notifier.perpanjangPeminjaman(
      id: widget.peminjamanId,
      tanggalKembaliBaru: AppFormatters.tanggalDb(_selectedDate),
      alasan: alasan,
    );

    if (!mounted) return;
    final state = ref.read(peminjamanActionProvider);
    if (ok) {
      AppToast.success(context, state.successMessage ?? 'Masa pinjam berhasil diperpanjang.');
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal memperpanjang.');
    }
    navigator.pop();

    if (ok) {
      widget.onSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetWrapper(
      title: 'Perpanjang Masa Pinjam',
      subtitle:
          'Dokumen: ${widget.kodeDokumen} • Batas Saat Ini: ${widget.tanggalKembaliSaatIni ?? "-"}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDatePickerField(
            label: 'Tanggal Rencana Kembali Baru:',
            selectedDate: _selectedDate,
            firstDate: DateTime.now().add(const Duration(days: 1)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateSelected: (picked) => setState(() => _selectedDate = picked),
          ),
          const SizedBox(height: 14),
          const Text(
            'Alasan Perpanjangan (Wajib):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _alasanController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Misal: Perpanjangan durasi tindakan, pemeriksaan lanjutan...',
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Konfirmasi Perpanjang Peminjaman',
            isLoading: _isSubmitting,
            icon: const Icon(LucideIcons.check, size: 18, color: Colors.white),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
