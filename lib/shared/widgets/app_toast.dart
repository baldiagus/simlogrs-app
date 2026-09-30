import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

enum AppToastType { success, error, warning, info }

class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;
  static Timer? _currentTimer;

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _dismiss();

    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () {
          if (_currentEntry == entry) {
            _dismiss();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _currentTimer = Timer(duration, () {
      if (_currentEntry == entry) {
        _dismiss();
      }
    });
  }

  static void success(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: AppToastType.success, duration: duration);
  }

  static void error(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: AppToastType.error, duration: duration);
  }

  static void warning(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: AppToastType.warning, duration: duration);
  }

  static void info(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: AppToastType.info, duration: duration);
  }

  static void _dismiss() {
    _currentTimer?.cancel();
    _currentTimer = null;
    if (_currentEntry != null) {
      final entry = _currentEntry!;
      _currentEntry = null;
      if (entry.mounted) {
        entry.remove();
      }
    }
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final AppToastType type;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  Future<void> _handleDismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (Color bg, Color border, Color text, Color iconColor, IconData icon) _resolveTheme() {
    switch (widget.type) {
      case AppToastType.success:
        return (
          const Color(0xFFF0FDF4),
          const Color(0xFF86EFAC),
          const Color(0xFF14532D),
          AppColors.success,
          LucideIcons.circleCheck,
        );
      case AppToastType.error:
        return (
          const Color(0xFFFEF2F2),
          const Color(0xFFFCA5A5),
          const Color(0xFF7F1D1D),
          AppColors.danger,
          LucideIcons.circleAlert,
        );
      case AppToastType.warning:
        return (
          const Color(0xFFFFFBEB),
          const Color(0xFFFDE68A),
          const Color(0xFF78350F),
          AppColors.warning,
          LucideIcons.triangleAlert,
        );
      case AppToastType.info:
        return (
          AppColors.tintBlueBg,
          AppColors.tintBlue.withValues(alpha: 0.3),
          AppColors.textPrimary,
          AppColors.tintBlue,
          LucideIcons.info,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final (bg, border, textColor, iconColor, icon) = _resolveTheme();

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _handleDismiss,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -4) {
                  _handleDismiss();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(LucideIcons.x, size: 14, color: textColor.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
