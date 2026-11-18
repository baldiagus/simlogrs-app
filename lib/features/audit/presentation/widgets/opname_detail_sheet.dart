import 'package:flutter/material.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/shared/widgets/app_bottom_sheet_wrapper.dart';

/// Rincian baca-saja untuk satu sesi; kuantitas tidak digabung antar satuan.
class OpnameDetailSheet extends StatelessWidget {
  const OpnameDetailSheet({super.key, required this.sesi});

  final SesiOpnameSelisihModel sesi;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetWrapper(
      title: 'Rincian Selisih Opname',
      subtitle: sesi.kode,
      maxHeightFactor: .9,
      fixedHeader: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(sesi.gudang, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('Petugas: ${sesi.petugas}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('${sesi.totalBatchSelisih} batch berselisih',
                    style: Theme.of(context).textTheme.labelMedium),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (sesi.details.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Rincian sesi belum tersedia'),
            )
          else
            for (final detail in sesi.details)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BatchDetail(detail: detail),
              ),
        ],
      ),
    );
  }
}

class _BatchDetail extends StatelessWidget {
  const _BatchDetail({required this.detail});

  final SelisihOpnameDetailModel detail;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(detail.namaBarang,
                style: Theme.of(context).textTheme.titleSmall),
            Text('Batch: ${detail.nomorBatch}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final theme = Theme.of(context).textTheme;
              final systemValue = '${detail.jumlahSistem} ${detail.satuan}';
              final physicalValue = '${detail.jumlahFisik} ${detail.satuan}';
              final system = _Quantity(label: 'Stok tercatat', value: systemValue);
              final physical = _Quantity(label: 'Hitung fisik', value: physicalValue);
              final columnWidth = (constraints.maxWidth - 12) / 2;
              final texts = [
                ('Stok tercatat', theme.bodySmall),
                ('Hitung fisik', theme.bodySmall),
                (systemValue, theme.titleSmall),
                (physicalValue, theme.titleSmall),
              ];
              final fits = texts.every((entry) {
                final painter = TextPainter(
                  text: TextSpan(text: entry.$1, style: entry.$2),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  maxLines: 1,
                )..layout(maxWidth: columnWidth);
                final fits = !painter.didExceedMaxLines;
                painter.dispose();
                return fits;
              });
              if (!fits) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [system, const SizedBox(height: 12), physical]);
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: system), const SizedBox(width: 12), Expanded(child: physical)]);
            }),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
            Semantics(
              label: 'Selisih: ${detail.selisih > 0 ? '+' : ''}${detail.selisih} ${detail.satuan}',
              child: Text(
                detail.selisih == 0 ? 'Tidak ada selisih: 0 ${detail.satuan}' :
                    '${detail.selisih < 0 ? 'Kekurangan' : 'Kelebihan'} ${detail.selisih.abs()} ${detail.satuan}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: detail.selisih < 0 ? AppColors.danger : detail.selisih > 0 ? AppColors.warning : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Quantity extends StatelessWidget {
  const _Quantity({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: theme.titleSmall),
      ],
    );
  }
}
