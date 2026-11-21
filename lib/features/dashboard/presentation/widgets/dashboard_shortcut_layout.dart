import 'package:flutter/material.dart';

/// Keeps shortcuts compact on phones and gives enlarged text a full-width card.
class DashboardShortcutLayout extends StatelessWidget {
  const DashboardShortcutLayout({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        // Reserve card padding plus readable text space, not a viewport cutoff.
        final minimumCardWidth = 32 + 112 * textScale;
        const spacing = 12.0;
        final columns = constraints.maxWidth >= minimumCardWidth * 2 + spacing
            ? 2
            : 1;
        final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: cardWidth, child: child),
          ],
        );
      },
    );
  }
}
