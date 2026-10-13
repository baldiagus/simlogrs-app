import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../providers/aset_provider.dart';
import '../widgets/input_manual_kode_dialog.dart';
import 'aset_detail_screen.dart';

/// Layar pindai QR aset fisik; di web memakai input kode manual.
class QrScannerScreen extends ConsumerStatefulWidget {
  /// Membuat QrScannerScreen.
  const QrScannerScreen({super.key});

  /// Membuat state layar pindai QR.
  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

/// State layar pindai QR: menjaga status proses dan jeda antar pindai.
class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _isProcessing = false;
  DateTime? _lastScannedTime;

  /// Memproses kode hasil pindai/input: throttle 1,2 detik, cari aset ke server, lalu buka detail atau tampilkan error.
  Future<void> _handleBarcodeDetected(String rawCode) async {
    final now = DateTime.now();
    if (_lastScannedTime != null &&
        now.difference(_lastScannedTime!) < const Duration(milliseconds: 1200)) {
      return;
    }
    _lastScannedTime = now;

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final cleanCode = rawCode.trim();
    final notifier = ref.read(asetActionProvider.notifier);
    final detail = await notifier.scanAset(cleanCode);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (detail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AsetDetailScreen(initialAset: detail),
        ),
      );
    } else {
      final error = ref.read(asetActionProvider).errorMessage ?? 'Aset tidak ditemukan';
      AppToast.error(context, error);
    }
  }

  /// Menampilkan dialog input kode manual lalu memproses kode yang dimasukkan.
  Future<void> _showManualInputDialog() async {
    final code = await InputManualKodeDialog.show(context);
    if (code != null && code.isNotEmpty) {
      _handleBarcodeDetected(code);
    }
  }

  /// Membangun layar pindai: placeholder web, bingkai panduan, dan tombol input kode manual.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Material(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.arrowLeft,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Pindai QR Aset Fisik',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: const [SizedBox(width: 8)],
      ),
      body: Stack(
        children: [
          // Web: kamera tidak dipasang langsung; pengguna memakai input kode manual
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.qrCode, color: Colors.white, size: 64),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mode Simulator / Web Browser',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gunakan tombol "Input Kode Manual" di bawah untuk memindai.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Central Guide Frame Overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryLight, width: 2.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  if (_isProcessing)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                ],
              ),
            ),
          ),

          // Bottom Controls & Manual Input Option
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Posisikan QR Code stiker aset di dalam kotak panduan',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Input Kode Aset Manual',
                  icon: const Icon(LucideIcons.keyboard, size: 18, color: Colors.white),
                  onPressed: _showManualInputDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
