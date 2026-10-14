import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

/// State layar pindai QR: mengelola kamera, siklus hidup aplikasi, status proses, dan jeda antar pindai.
class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _laserController;
  late final Animation<double> _laserAnimation;

  bool _isProcessing = false;
  bool _isTorchOn = false;
  DateTime? _lastScannedTime;

  /// Menyiapkan observer siklus hidup, controller kamera, dan animasi garis laser pindai.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 1000,
      facing: CameraFacing.back,
      torchEnabled: false,
      autoStart: true,
    );
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _laserAnimation = CurvedAnimation(
      parent: _laserController,
      curve: Curves.easeInOut,
    );
  }

  /// Menghentikan kamera saat aplikasi tidak aktif/di-pause dan menyalakannya lagi saat kembali (non-web).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || kIsWeb) return;
    if (state == AppLifecycleState.resumed) {
      _controller.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  /// Melepas observer dan membuang controller kamera saat widget dibuang.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _laserController.dispose();
    super.dispose();
  }

  /// Memproses kode hasil pindai/input: throttle 1,2 detik, cari aset ke server, lalu buka detail atau tampilkan error.
  Future<void> _handleBarcodeDetected(String rawCode) async {
    final now = DateTime.now();
    if (_lastScannedTime != null &&
        now.difference(_lastScannedTime!) <
            const Duration(milliseconds: 1200)) {
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
      await _controller.stop();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AsetDetailScreen(initialAset: detail),
        ),
      );
      if (!mounted) return;
      _lastScannedTime = null;
      await _controller.start();
    } else {
      final error =
          ref.read(asetActionProvider).errorMessage ?? 'Aset tidak ditemukan';
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

  /// Membangun layar pindai: preview kamera (placeholder di web), bingkai panduan, dan tombol input kode manual.
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
        actions: [
          _buildAppBarButton(
            tooltip: _isTorchOn ? 'Matikan Senter' : 'Nyalakan Senter',
            backgroundColor: _isTorchOn
                ? Colors.amber.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.18),
            borderColor: _isTorchOn
                ? Colors.amber.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.35),
            icon: Icon(
              LucideIcons.zap,
              color: _isTorchOn ? Colors.black : Colors.white,
              size: 20,
            ),
            onTap: () async {
              await _controller.toggleTorch();
              if (mounted) {
                setState(() => _isTorchOn = !_isTorchOn);
              }
            },
          ),
          const SizedBox(width: 8),
          _buildAppBarButton(
            tooltip: 'Ganti Kamera',
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            icon: const Icon(
              LucideIcons.refreshCcw,
              color: Colors.white,
              size: 20,
            ),
            onTap: () => _controller.switchCamera(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Camera scanner preview
          if (!kIsWeb)
            Positioned.fill(
              child: MobileScanner(
                controller: _controller,
                fit: BoxFit.cover,
                placeholderBuilder: (context, child) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Menyiapkan sensor kamera...',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, child) {
                  final isPermission = error.errorCode ==
                      MobileScannerErrorCode.permissionDenied;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPermission
                                ? LucideIcons.shieldAlert
                                : LucideIcons.cameraOff,
                            color: AppColors.danger,
                            size: 48,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isPermission
                                ? 'Izin Kamera Diperlukan'
                                : 'Sensor Kamera Tidak Siap',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isPermission
                                ? 'Aplikasi memerlukan izin akses kamera untuk memindai QR Code aset fisik.'
                                : (error.errorDetails?.message ??
                                    error.errorCode.name),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: () => _controller.start(),
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: const Text('Aktifkan Sensor Kamera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _handleBarcodeDetected(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
            )
          else
            // Web fallback placeholder when desktop web does not attach mobile camera directly
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
                    child: const Icon(LucideIcons.qrCode,
                        color: Colors.white, size: 64),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Mode Simulator / Web Browser',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Gunakan tombol "Input Kode Manual" di bawah untuk memindai.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Scrim overlay with viewfinder cutout and corner brackets
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScannerOverlayPainter(),
              ),
            ),
          ),

          // Central Guide Frame Overlay & scanning laser
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    _buildScanningLaser(),
                    if (_isProcessing)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                  ],
                ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  icon: const Icon(LucideIcons.keyboard,
                      size: 18, color: Colors.white),
                  onPressed: _showManualInputDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun tombol aksi di AppBar dengan wadah glassmorphism rounded 12 dan border transparan.
  Widget _buildAppBarButton({
    required Widget icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor ?? Colors.white.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: icon,
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun garis laser horizontal beranimasi dengan gradien neon dan bayangan glow.
  Widget _buildScanningLaser() {
    return AnimatedBuilder(
      animation: _laserAnimation,
      builder: (context, child) {
        final double topPosition =
            12.0 + (_laserAnimation.value * (260.0 - 24.0 - 3.0));
        return Positioned(
          top: topPosition,
          left: 14.0,
          right: 14.0,
          child: child!,
        );
      },
      child: Container(
        height: 3.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2.0),
          gradient: const LinearGradient(
            colors: [
              Colors.transparent,
              Color(0x808B80F9),
              Color(0xFFB8A9FC),
              Color(0xFFFFFFFF),
              Color(0xFFB8A9FC),
              Color(0x808B80F9),
              Colors.transparent,
            ],
            stops: [0.0, 0.15, 0.4, 0.5, 0.6, 0.85, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.8),
              blurRadius: 8.0,
              spreadRadius: 1.0,
            ),
            BoxShadow(
              color: const Color(0xFF9B8FFB).withValues(alpha: 0.6),
              blurRadius: 16.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter untuk menggambar lapisan gelap (scrim) dengan cutout jendela pemindai dan 4 siku sudut.
class _ScannerOverlayPainter extends CustomPainter {
  /// Membuat instance [_ScannerOverlayPainter].
  const _ScannerOverlayPainter();

  /// Ukuran kotak bidik tengah pemindai.
  static const double scanWindowSize = 260.0;

  /// Radius sudut lengkung jendela bidik pemindai.
  static const double borderRadius = 24.0;

  /// Panjang lengan siku sudut pemindai.
  static const double cornerLength = 36.0;

  /// Ketebalan garis siku sudut pemindai.
  static const double cornerStrokeWidth = 4.0;

  /// Menggambar scrim overlay dan 4 siku sudut berbentuk L pada canvas.
  @override
  void paint(Canvas canvas, Size size) {
    final double left = (size.width - scanWindowSize) / 2;
    final double top = (size.height - scanWindowSize) / 2;
    final Rect scanRect =
        Rect.fromLTWH(left, top, scanWindowSize, scanWindowSize);
    final RRect scanRRect = RRect.fromRectAndRadius(
      scanRect,
      const Radius.circular(borderRadius),
    );

    // 1. Lapisan gelap (scrim ~55% opacity) di seluruh layar kecuali kotak bidik tengah
    final Path screenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path cutoutPath = Path()..addRRect(scanRRect);
    final Path overlayPath =
        Path.combine(PathOperation.difference, screenPath, cutoutPath);

    final Paint scrimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, scrimPaint);

    // 2. 4 siku sudut (corner brackets) berbentuk L di keempat sudut jendela scan
    final Paint bracketPaint = Paint()
      ..color = AppColors.primaryPurple
      ..strokeWidth = cornerStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double right = left + scanWindowSize;
    final double bottom = top + scanWindowSize;

    // Sudut kiri atas
    final Path topLeft = Path()
      ..moveTo(left, top + cornerLength)
      ..lineTo(left, top)
      ..lineTo(left + cornerLength, top);
    canvas.drawPath(topLeft, bracketPaint);

    // Sudut kanan atas
    final Path topRight = Path()
      ..moveTo(right - cornerLength, top)
      ..lineTo(right, top)
      ..lineTo(right, top + cornerLength);
    canvas.drawPath(topRight, bracketPaint);

    // Sudut kiri bawah
    final Path bottomLeft = Path()
      ..moveTo(left, bottom - cornerLength)
      ..lineTo(left, bottom)
      ..lineTo(left + cornerLength, bottom);
    canvas.drawPath(bottomLeft, bracketPaint);

    // Sudut kanan bawah
    final Path bottomRight = Path()
      ..moveTo(right - cornerLength, bottom)
      ..lineTo(right, bottom)
      ..lineTo(right, bottom - cornerLength);
    canvas.drawPath(bottomRight, bracketPaint);
  }

  /// Menentukan apakah painter perlu digambar ulang saat state berganti.
  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) => false;
}
