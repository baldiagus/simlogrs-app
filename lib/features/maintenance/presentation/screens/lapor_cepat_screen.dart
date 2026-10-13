import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../../../core/offline/offline_queue.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../aset/presentation/screens/qr_scanner_screen.dart';
import '../widgets/aset_unit_picker_sheet.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/tiket_maintenance_provider.dart';

/// Layar pelaporan cepat kerusakan sarana, dengan opsi kode aset awal.
class LaporCepatScreen extends ConsumerStatefulWidget {
  final String? initialKodeAset;

  /// Membuat LaporCepatScreen dengan kode aset awal opsional.
  const LaporCepatScreen({
    super.key,
    this.initialKodeAset,
  });

  /// Membuat state layar lapor cepat.
  @override
  ConsumerState<LaporCepatScreen> createState() => _LaporCepatScreenState();
}

/// State layar lapor cepat: menyimpan input form, prioritas, dan foto terpilih.
class _LaporCepatScreenState extends ConsumerState<LaporCepatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kodeAsetController = TextEditingController();
  final _deskripsiController = TextEditingController();
  String _prioritas = 'SEDANG';
  XFile? _pickedImage;
  bool _isSending = false;
  final ImagePicker _picker = ImagePicker();

  /// Mengisi kode aset awal dari parameter widget jika ada (mis. hasil scan QR).
  @override
  void initState() {
    super.initState();
    if (widget.initialKodeAset != null) {
      _kodeAsetController.text = widget.initialKodeAset!;
    }
  }

  /// Membersihkan controller input saat widget dibuang.
  @override
  void dispose() {
    _kodeAsetController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  /// Mengambil foto dari kamera/galeri (ukuran dibatasi) dan menyimpannya sebagai lampiran laporan.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _pickedImage = photo;
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Gagal mengambil foto: $e');
    }
  }

  /// Memvalidasi form lalu mengirim laporan; sukses menutup layar, gagal jaringan diantrekan (teks saja), gagal lain menampilkan toast error.
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final kodeAset = _kodeAsetController.text.trim();
    final deskripsi = _deskripsiController.text.trim();
    final punyaFoto = _pickedImage != null;
    setState(() => _isSending = true);

    try {
      final res = await ref.read(maintenanceRepositoryProvider).submitLaporCepat(
            kodeAset: kodeAset,
            deskripsiMasalah: deskripsi,
            prioritas: _prioritas,
            foto: _pickedImage,
          );
      ref.invalidate(daftarTiketUnitProvider);
      ref.invalidate(dashboardSummaryProvider);
      if (!mounted) return;
      final kode = res['kode']?.toString() ?? 'MNT';
      AppToast.success(context, 'Laporan kerusakan $kode berhasil diterbitkan ke IPSRS.');
      Navigator.pop(context, true);
    } catch (e) {
      if (e is ApiException && e.isNetworkError) {
        await ref.read(offlineQueueCountProvider.notifier).enqueue(
          OfflineMutation.jenisLaporCepat,
          {
            'kode_aset': kodeAset,
            'deskripsi': deskripsi,
            'prioritas': _prioritas,
          },
        );
        if (!mounted) return;
        AppToast.info(
          context,
          'Tidak ada koneksi. Disimpan, akan dikirim otomatis saat online.'
          '${punyaFoto ? ' Foto tidak ikut terkirim.' : ''}',
        );
        Navigator.pop(context, true);
        return;
      }
      if (!mounted) return;
      setState(() => _isSending = false);
      AppToast.error(context, e.toString().replaceAll('ApiException: ', ''));
    }
  }

  /// Membangun form laporan cepat kerusakan: kode aset, deskripsi, prioritas, foto, dan tombol kirim.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Lapor Rusak Sarana'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Guidance Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tintTealBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.wrench, color: AppColors.tintTeal, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'IPSRS Quick Fieldwork',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tintTeal,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Laporkan kerusakan fisik sarana atau fasilitas rumah sakit secara instan ke tim teknisi.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Kode Aset Field with Scanner Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Identitas Sarana / Kode Aset *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => AsetUnitPickerSheet(
                            onAsetSelected: (aset) {
                              setState(() => _kodeAsetController.text = aset.kodeAset);
                            },
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.list, size: 14),
                      label: const Text('Pilih dari Ruangan', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryPurple,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _kodeAsetController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'misal: AST-2026-001',
                    prefixIcon: const Icon(LucideIcons.qrCode, size: 18, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: const Icon(LucideIcons.camera, size: 20, color: AppColors.primaryPurple),
                      tooltip: 'Pindai QR Aset',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                        );
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Kode atau nomor aset wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Prioritas Selector
                const Text(
                  'Tingkat Urgensi Kerusakan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPrioritasChip('RENDAH', 'Rendah', AppColors.primaryPurple, AppColors.tintVioletBg),
                    const SizedBox(width: 6),
                    _buildPrioritasChip('SEDANG', 'Sedang', AppColors.tintBlue, AppColors.tintBlueBg),
                    const SizedBox(width: 6),
                    _buildPrioritasChip('TINGGI', 'Tinggi', AppColors.warning, const Color(0xFFFFFBEB)),
                    const SizedBox(width: 6),
                    _buildPrioritasChip('CITO', 'CITO', AppColors.danger, const Color(0xFFFEF2F2)),
                  ],
                ),
                const SizedBox(height: 18),

                // Deskripsi Masalah
                const Text(
                  'Deskripsi Kerusakan Fisik *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _deskripsiController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Jelaskan tanda-tanda kerusakan, bunyi aneh, bau gosong, atau bagian fisik yang patah...',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 5) {
                      return 'Deskripsi masalah minimal 5 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Foto Bukti Kerusakan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Foto Bukti Fisik Kerusakan',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_pickedImage != null)
                      TextButton(
                        onPressed: () => setState(() => _pickedImage = null),
                        child: const Text('Hapus Foto', style: TextStyle(color: AppColors.danger, fontSize: 11)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_pickedImage == null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.image, size: 36, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        const Text(
                          'Unggah Bukti Foto Kamera',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Membantu teknisi mendiagnosa suku cadang yang diperlukan',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(LucideIcons.camera, size: 16),
                              label: const Text('Buka Kamera'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(LucideIcons.folder, size: 16),
                              label: const Text('Galeri'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: kIsWeb
                        ? Image.network(_pickedImage!.path, fit: BoxFit.cover, width: double.infinity)
                        : Image.file(File(_pickedImage!.path), fit: BoxFit.cover, width: double.infinity),
                  ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'Kirim Laporan Kerusakan',
                  isLoading: _isSending,
                  icon: const Icon(LucideIcons.send, size: 18, color: Colors.white),
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Chip pilihan prioritas laporan; menandai pilihan aktif dan mengubah _prioritas saat diketuk.
  Widget _buildPrioritasChip(String value, String label, Color color, Color bg) {
    final isSelected = _prioritas == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _prioritas = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? bg : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
