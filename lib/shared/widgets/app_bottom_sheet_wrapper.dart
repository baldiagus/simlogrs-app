import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Pembungkus seragam untuk bottom sheet: handle, judul opsional, dan konten anak.
class AppBottomSheetWrapper extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final double? maxHeightFactor;
  final bool fixedHeader;

  const AppBottomSheetWrapper({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    this.maxHeightFactor,
    this.fixedHeader = false,
  });

  /// Membatasi sheet ke ruang di atas keyboard; seluruh isi tetap dapat digulir.
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    // Existing forms pass a top-level Flexible around their scroll view.
    // This wrapper now owns the height/scroll constraint, not the caller's flex.
    final body = switch (child) {
      Flexible(:final child) => child,
      _ => child,
    };
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text(title!, style: Theme.of(context).textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );

    if (fixedHeader) {
      final contentPadding = padding ?? EdgeInsets.fromLTRB(
        20, 16, 20, 20 + mediaQuery.padding.bottom,
      );
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (mediaQuery.size.height - bottomInset - mediaQuery.padding.top)
                .clamp(0.0, mediaQuery.size.height).toDouble() *
                (maxHeightFactor ?? 1),
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),
                      const SizedBox(height: 16),
                      if (trailing == null) heading else Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Expanded(child: heading), trailing!],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    primary: false,
                    padding: contentPadding,
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: (mediaQuery.size.height - bottomInset - mediaQuery.padding.top)
              .clamp(0.0, mediaQuery.size.height).toDouble() *
              (maxHeightFactor ?? 1),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            primary: false,
            padding: padding ?? EdgeInsets.fromLTRB(
              20, 12, 20, 20 + mediaQuery.padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (title != null || subtitle != null || trailing != null) ...[
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (trailing == null) return heading;
                      if (constraints.maxWidth < 360 ||
                          mediaQuery.textScaler.scale(14) > 18) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            heading,
                            const SizedBox(height: 8),
                            trailing!,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: heading),
                          const SizedBox(width: 12),
                          Flexible(child: trailing!),
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
