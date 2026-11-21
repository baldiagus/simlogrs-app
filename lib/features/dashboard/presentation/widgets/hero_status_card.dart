import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../data/models/dashboard_summary_model.dart';

class HeroStatusCard extends StatelessWidget {
  final DashboardSummaryModel summary;
  final VoidCallback onInspectPressed;
  final bool compactManagement;

  const HeroStatusCard({
    super.key,
    required this.summary,
    required this.onInspectPressed,
    this.compactManagement = false,
  });

  /// Membangun kartu utama berisi metrik hero dan sub-metrik ringkasan dashboard.
  @override
  Widget build(BuildContext context) {
    final hero = summary.hero;
    final isCompact = compactManagement && hero.targetAksi == 'pagu_realisasi';
    final titleText = isCompact ? 'Pengeluaran RS' : hero.judul;
    final actionText = isCompact ? 'Rincian' : hero.labelTombol;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryHeroGradient,
        borderRadius: BorderRadius.all(Radius.circular(24)),
        boxShadow: AppShadows.heroCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.surface);
              final actionStyle = Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.surface);
              final scaler = MediaQuery.textScalerOf(context);
              final titlePainter = TextPainter(
                text: TextSpan(text: titleText, style: titleStyle),
                textDirection: Directionality.of(context),
                textScaler: scaler,
              )..layout();
              final actionPainter = TextPainter(
                text: TextSpan(text: actionText, style: actionStyle),
                textDirection: Directionality.of(context),
                textScaler: scaler,
              )..layout();
              final fits = titlePainter.width + actionPainter.width + 58 <= constraints.maxWidth;
              titlePainter.dispose();
              actionPainter.dispose();
              final title = Text(titleText, style: titleStyle);
              final action = InkWell(
                onTap: onInspectPressed,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x22FFFFFF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(actionText, style: actionStyle)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.surface, size: 14),
                    ],
                  ),
                ),
              );
              return fits
                  ? Row(children: [Expanded(child: title), const SizedBox(width: 16), action])
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, const SizedBox(height: 8), action],
                    );
            },
          ),
          const SizedBox(height: 14),

          // Total Number
          Text(
            hero.satuan == 'Rp'
                ? AppFormatters.rupiah(hero.total)
                : '${hero.total} ${hero.satuan}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppColors.surface,
            ),
          ),
          const SizedBox(height: 18),

          // Sub Info breakdown
          if (hero.subMetrik.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x1A000000),
                borderRadius: BorderRadius.circular(14),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final valueStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.surface,
                    fontSize: isCompact ? 14 : null,
                  );
                  final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.surface);
                  final scaler = MediaQuery.textScalerOf(context);
                  var requiredWidth = 0.0;
                  final compactWidths = <double>[];
                  for (final metric in hero.subMetrik) {
                    final valuePainter = TextPainter(
                      text: TextSpan(text: isCompact ? _managementValue(metric) : metric.nilai, style: valueStyle),
                      textDirection: Directionality.of(context),
                      textScaler: scaler,
                    )..layout();
                    final labelPainter = TextPainter(
                      text: TextSpan(text: isCompact ? _managementLabel(metric.label) : metric.label, style: labelStyle),
                      textDirection: Directionality.of(context),
                      textScaler: scaler,
                      maxLines: 2,
                    )..layout(maxWidth: (constraints.maxWidth / hero.subMetrik.length - 8).clamp(0.0, double.infinity));
                    final width = valuePainter.width > labelPainter.width ? valuePainter.width : labelPainter.width;
                    if (isCompact) compactWidths.add(width + 4);
                    if (width + 8 > requiredWidth) requiredWidth = width + 8;
                    valuePainter.dispose();
                    labelPainter.dispose();
                  }
                  if (isCompact) {
                    final minimumWidths = <double>[];
                    for (final metric in hero.subMetrik) {
                      var minimum = 0.0;
                      for (final token in _managementValue(metric).split(' ')) {
                        final painter = TextPainter(
                          text: TextSpan(text: token, style: valueStyle),
                          textDirection: Directionality.of(context),
                          textScaler: scaler,
                        )..layout();
                        if (painter.width > minimum) minimum = painter.width;
                        painter.dispose();
                      }
                      final labelPainter = TextPainter(
                        text: TextSpan(text: _managementLabel(metric.label), style: labelStyle),
                        textDirection: Directionality.of(context),
                        textScaler: scaler,
                      )..layout();
                      if (labelPainter.width > minimum) minimum = labelPainter.width;
                      labelPainter.dispose();
                      minimumWidths.add(minimum + 4);
                    }
                    if (minimumWidths.fold<double>(0, (sum, width) => sum + width) <= constraints.maxWidth) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final (index, metric) in hero.subMetrik.indexed)
                              Expanded(
                                flex: minimumWidths[index].ceil(),
                                child: Column(
                                  children: [
                                    Expanded(child: Align(
                                      alignment: Alignment.topCenter,
                                      child: _metricValue(context, metric, true, valueStyle),
                                    )),
                                    const SizedBox(height: 2),
                                    Text(_managementLabel(metric.label), style: labelStyle, textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }
                  }
                  final neededWidth = isCompact
                      ? compactWidths.fold<double>(0, (sum, width) => sum + width)
                      : requiredWidth * hero.subMetrik.length;
                  if (neededWidth > constraints.maxWidth) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final metric in hero.subMetrik)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _metricValue(context, metric, isCompact, valueStyle),
                                Text(isCompact ? _managementLabel(metric.label) : metric.label, style: labelStyle),
                              ],
                            ),
                          ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (index, metric) in hero.subMetrik.indexed)
                        Expanded(
                          flex: isCompact ? compactWidths[index].ceil() : 1,
                          child: isCompact
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _metricValue(context, metric, true, valueStyle),
                                    const SizedBox(height: 2),
                                    Text(_managementLabel(metric.label), style: labelStyle, textAlign: TextAlign.center),
                                  ],
                                )
                              : _buildSubItem(context, metric.label, metric.nilai),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricValue(BuildContext context, SubMetricModel metric,
      bool compact, TextStyle? style) {
    final text = Text(compact ? _managementValue(metric) : metric.nilai,
        style: style, textAlign: compact ? TextAlign.center : TextAlign.start);
    return compact
        ? Semantics(label: '${metric.label}: ${metric.nilai}', excludeSemantics: true, child: text)
        : text;
  }

  static String _managementLabel(String label) => switch (label) {
    'Amprah Logistik' => 'Amprah',
    'Sparepart Servis' => 'Servis',
    'Unit Terlayani' => 'Ruangan',
    _ => label,
  };

  static String _managementValue(SubMetricModel metric) {
    if (metric.label == 'Unit Terlayani') {
      return RegExp(r'^(\d+) Ruangan$').firstMatch(metric.nilai)?.group(1) ?? metric.nilai;
    }
    // Other monetary metrics may use the same strict Rupiah contract.
    // Only the server's integer Rupiah notation is accepted. Unknown data is
    // displayed verbatim, never coerced to zero or parsed as another currency.
    final match = RegExp(r'^Rp (0|[1-9]\d{0,2}(?:\.\d{3})*|[1-9]\d*)$')
        .firstMatch(metric.nilai);
    if (match == null) return metric.nilai;
    final amount = BigInt.parse(match.group(1)!.replaceAll('.', ''));
    final thousand = BigInt.from(1000);
    var divisor = BigInt.one;
    var unit = 0;
    const units = ['', 'rb', 'jt', 'mlr', 'tr'];
    while (unit < units.length - 1 && amount >= divisor * thousand) {
      divisor *= thousand;
      unit++;
    }
    if (unit == 0) return metric.nilai;
    final hundred = BigInt.from(100);
    var rounded = (amount * hundred + divisor ~/ BigInt.two) ~/ divisor;
    if (rounded >= thousand * hundred && unit < units.length - 1) {
      divisor *= thousand;
      unit++;
      rounded = (amount * hundred + divisor ~/ BigInt.two) ~/ divisor;
    }
    final whole = rounded ~/ hundred;
    final fraction = (rounded % hundred).toString().padLeft(2, '0');
    final decimal = fraction == '00' ? '' : ',${fraction.replaceFirst(RegExp(r'0$'), '')}';
    return 'Rp $whole$decimal ${units[unit]}';
  }

  /// Membangun satu item sub-metrik (nilai di atas, label di bawah) di dalam kartu hero.
  Widget _buildSubItem(BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.surface),
          softWrap: true,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.surface),
          softWrap: true,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
