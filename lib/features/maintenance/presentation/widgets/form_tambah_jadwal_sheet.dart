import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/repositories/ipsrs_repository.dart';
import '../providers/ipsrs_providers.dart';

class FormTambahJadwalSheet extends ConsumerStatefulWidget {
  /// Membuat FormTambahJadwalSheet.
  const FormTambahJadwalSheet({super.key});

  /// Tampilkan sheet sebagai bottom sheet; hasilnya true jika data tersimpan.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FormTambahJadwalSheet(),
    );
  }

  /// Membuat state mutable untuk widget ini.
  @override
  ConsumerState<FormTambahJadwalSheet> createState() => _FormTambahJadwalSheetState();
}

class _FormTambahJadwalSheetState extends ConsumerState<FormTambahJadwalSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jenisCtrl = TextEditingController(text: 'Servis Pemeliharaan Berkala');
  final TextEditingController _intervalNilaiCtrl = TextEditingController(text: '1');
  final TextEditingController _catatanCtrl = TextEditingController();

  int? _selectedAsetId;
  String _intervalTipe = 'BULAN';
  DateTime _tanggalBerikutnya = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  /// Bersihkan controller dan resource saat widget dilepas.
  @override
  void dispose() {
    _jenisCtrl.dispose();
    _intervalNilaiCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  /// Tampilkan date picker dan simpan tanggal terpilih ke form.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalBerikutnya,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurple,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _tanggalBerikutnya = picked);
    }
  }

  /// Validasi form lalu kirim data ke server dan tampilkan hasilnya.
  Future<void> _submit() async {
    if (_selectedAsetId == null) {
      AppToast.error(context, 'Pilih sarana / aset yang akan dijadwalkan servis.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final intervalNilai = int.tryParse(_intervalNilaiCtrl.text.trim()) ?? 1;
    if (intervalNilai <= 0) {
      AppToast.error(context, 'Interval waktu pemeliharaan minimal 1.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(ipsrsRepositoryProvider);
      final fmtTanggal =
          '${_tanggalBerikutnya.year.toString().padLeft(4, '0')}-${_tanggalBerikutnya.month.toString().padLeft(2, '0')}-${_tanggalBerikutnya.day.toString().padLeft(2, '0')}';

      final res = await repo.simpanJadwalPreventif(
        asetId: _selectedAsetId!,
        jenisMaintenance: _jenisCtrl.text.trim(),
        intervalNilai: intervalNilai,
        intervalTipe: _intervalTipe,
        tanggalBerikutnya: fmtTanggal,
        catatan: _catatanCtrl.text.trim(),
      );

      if (mounted) {
        final kode = res['kode']?.toString() ?? 'Jadwal';
        AppToast.success(context, 'Jadwal preventif $kode berhasil ditambahkan.');
        ref.invalidate(jadwalPreventifListProvider);
        ref.invalidate(dashboardSummaryProvider);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e.toString().replaceAll('ApiException: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Membangun tampilan _FormTambahJadwalSheetState.
  @override
  Widget build(BuildContext context) {
    final katalogAsetAsync = ref.watch(rekamMedisKatalogProvider);

    return AppBottomSheetWrapper(
      maxHeightFactor: 0.88,
      title: 'Tambah Jadwal Preventif',
      subtitle: 'Khusus Kepala / Koordinator Teknisi IPSRS',
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pilih Sarana / Aset
              const Text(
                'Pilih Sarana / Aset Fisik *',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              katalogAsetAsync.when(
                data: (items) {
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedAsetId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      hintText: 'Pilih aset rumah sakit...',
                    ),
                    items: items.map((a) {
                      return DropdownMenuItem<int>(
                        value: a.id,
                        child: Text(
                          '${a.kodeAset} • ${a.namaSarana} (${a.lokasi})',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedAsetId = val),
                    validator: (val) => val == null ? 'Sarana / aset wajib dipilih' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text(
                  'Gagal memuat katalog aset: $err',
                  style: const TextStyle(color: AppColors.danger, fontSize: 11),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Jenis Pekerjaan Maintenance
              const Text(
                'Jenis Pekerjaan Pemeliharaan *',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _jenisCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  hintText: 'Misal: Servis AC Rutin, Kalibrasi Sensor O2...',
                ),
                validator: (val) => (val == null || val.trim().length < 3) ? 'Jenis pekerjaan minimal 3 karakter' : null,
              ),
              const SizedBox(height: 14),

              // 3. Frekuensi & Interval Waktu
              const Text(
                'Frekuensi Servis Berkala *',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('Setiap ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  SizedBox(
                    width: 70,
                    child: TextFormField(
                      controller: _intervalNilaiCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Wajib' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _intervalTipe,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'HARI', child: Text('Hari')),
                        DropdownMenuItem(value: 'MINGGU', child: Text('Minggu')),
                        DropdownMenuItem(value: 'BULAN', child: Text('Bulan')),
                        DropdownMenuItem(value: 'TAHUN', child: Text('Tahun')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _intervalTipe = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Tanggal Servis Berikutnya
              const Text(
                'Tanggal Servis Perdana / Berikutnya *',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 16, color: AppColors.primaryPurple),
                          const SizedBox(width: 8),
                          Text(
                            AppFormatters.tanggal(_tanggalBerikutnya),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const Text(
                        'Pilih Tanggal',
                        style: TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 5. Catatan / Instruksi
              const Text(
                'Catatan / Instruksi Kerja (Opsional)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _catatanCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                  hintText: 'Petunjuk khusus teknisi saat servis preventif...',
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Simpan
              CustomButton(
                width: double.infinity,
                text: 'Simpan Jadwal Preventif',
                isLoading: _isLoading,
                icon: const Icon(LucideIcons.check, size: 18, color: Colors.white),
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
