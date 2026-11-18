import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:simlog_mobile/core/network/user_error_message.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/data/repositories/audit_repository.dart';
import 'package:simlog_mobile/features/audit/presentation/utils/audit_presentation.dart';
import 'package:simlog_mobile/shared/widgets/app_bottom_sheet_wrapper.dart';
import 'package:simlog_mobile/shared/widgets/app_loading_view.dart';

/// Read-only activity detail. Keep the request stable while disclosures rebuild.
class TrailDetailSheet extends ConsumerStatefulWidget {
  const TrailDetailSheet({super.key, required this.logId});
  final int logId;

  @override
  ConsumerState<TrailDetailSheet> createState() => _TrailDetailSheetState();
}

class _TrailDetailSheetState extends ConsumerState<TrailDetailSheet> {
  late Future<AuditTrailItemModel> _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void didUpdateWidget(covariant TrailDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logId != widget.logId) _loadDetail();
  }

  void _loadDetail() {
    _detail = ref.read(auditRepositoryProvider).getAuditTrailDetail(widget.logId);
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetWrapper(
      title: 'Detail Aktivitas',
      subtitle: 'Catatan #${widget.logId}',
      maxHeightFactor: .9,
      fixedHeader: true,
      child: FutureBuilder<AuditTrailItemModel>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(height: 100, child: AppLoadingView());
          }
          final log = snapshot.data;
          if (snapshot.hasError || log == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userErrorMessage(
                  snapshot.error,
                  action: 'memuat detail log audit',
                )),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(_loadDetail),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            );
          }
          return _ActivityDetail(key: ValueKey(log.id), log: log);
        },
      ),
    );
  }
}

class _ActivityDetail extends StatelessWidget {
  const _ActivityDetail({super.key, required this.log});
  final AuditTrailItemModel log;

  static final _sourceTimeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
  static final _displayTimeFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

  String get _displayTime {
    try {
      // Parse the displayed source clock directly, never convert its zone.
      return _displayTimeFormat.format(_sourceTimeFormat.parseStrict(log.waktu));
    } on FormatException {
      return log.waktu;
    }
  }

  @override
  Widget build(BuildContext context) {
    final changes = AuditPresentation.changes(log.dataSebelum, log.dataSesudah);
    final noSnapshots = log.dataSebelum == null && log.dataSesudah == null;
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AuditPresentation.entity(log.referensiJenis)} #${log.referensiId}',
                style: theme.titleSmall),
            const SizedBox(height: 6),
            // Informational badge only; this is not an action.
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('Aktivitas: ${AuditPresentation.action(log.aksi)}',
                    style: theme.labelMedium),
              ),
            ),
            const SizedBox(height: 6),
            Text(log.penggunaNama, style: theme.bodyMedium),
            Text(AuditPresentation.role(log.peran), style: theme.bodySmall),
            const SizedBox(height: 4),
            Text('Waktu: $_displayTime', style: theme.bodySmall),
          ],
        ),
        const SizedBox(height: 16),
        Text('Perubahan Data', style: theme.titleSmall),
        if (log.aksi == 'TAMBAH' || log.aksi == 'HAPUS') ...[
          const SizedBox(height: 4),
          Text(log.aksi == 'TAMBAH'
              ? 'Aktivitas penambahan data. Nilai yang tercatat ditampilkan di bawah.'
              : 'Aktivitas penghapusan data. Nilai yang tercatat ditampilkan di bawah.',
              style: theme.bodySmall),
        ],
        const SizedBox(height: 8),
        if (changes.isEmpty)
          Text(noSnapshots
              ? 'Rincian perubahan tidak tersedia'
              : 'Tidak ada perbedaan pada data yang tercatat')
        else
          for (final change in changes)
            _ChangeCard(change: change, entity: log.referensiJenis),
        const SizedBox(height: 12),
        Material(
          type: MaterialType.transparency,
          child: ExpansionTile(
            key: ValueKey('audit-technical-information-${log.id}'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: const Text('Informasi teknis'),
            children: [
              _TechnicalInformation(log: log),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChangeCard extends StatelessWidget {
  const _ChangeCard({required this.change, required this.entity});
  final AuditFieldChange change;
  final String entity;

  @override
  Widget build(BuildContext context) {
    final fields = change.path.whereType<String>();
    final field = fields.where((part) => !AuditPresentation.knownField(part)).firstOrNull ?? fields.lastOrNull;
    final label = change.path.isEmpty ? 'Data' : change.path.map((part) =>
        part is int ? 'Item ${part + 1}' : AuditPresentation.field(part as String)).join(' › ');
    final before = _RecordedValue(
      label: 'Sebelumnya', value: change.before, entity: entity, field: field,
    );
    final after = DefaultTextStyle.merge(
      style: const TextStyle(fontWeight: FontWeight.w600),
      child: _RecordedValue(
        label: 'Sesudahnya', value: change.after, entity: entity, field: field,
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            final columnWidth = (constraints.maxWidth - 16) / 2;
            final textTheme = Theme.of(context).textTheme;
            bool fits(AuditRecordedValue value, String heading, {bool emphasized = false}) {
              if (value.value is Map || value.value is List) return false;
              final text = !value.present
                  ? 'Tidak tercatat'
                  : AuditPresentation.value(value.value, entity: entity, field: field);
              final valueStyle = DefaultTextStyle.of(context).style.merge(
                emphasized ? const TextStyle(fontWeight: FontWeight.w600) : null,
              );
              for (final (content, style) in [
                (heading, textTheme.labelMedium),
                (text, valueStyle),
              ]) {
                final painter = TextPainter(
                  text: TextSpan(text: content, style: style),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  maxLines: 1,
                )..layout(maxWidth: columnWidth);
                final overflow = painter.didExceedMaxLines;
                painter.dispose();
                if (overflow) return false;
              }
              return true;
            }
            if (change.path.length > 1 ||
                MediaQuery.textScalerOf(context).scale(14) > 18 ||
                !fits(change.before, 'Sebelumnya') ||
                !fits(change.after, 'Sesudahnya', emphasized: true)) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [before, const SizedBox(height: 10), after],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: before), const SizedBox(width: 16), Expanded(child: after)],
            );
          }),
        ],
      ),
    );
  }
}

class _RecordedValue extends StatelessWidget {
  const _RecordedValue({
    required this.label,
    required this.value,
    this.entity,
    this.field,
    this.technical = false,
  });
  final String label;
  final AuditRecordedValue value;
  final String? entity;
  final String? field;
  final bool technical;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 2),
      if (!value.present)
        const Text('Tidak tercatat')
      else
        _StructuredValue(value: value.value, entity: entity, field: field, technical: technical),
    ],
  );
}

/// Maps and lists are rendered as labelled rows, including in technical details.
/// No object/string serialization is used to present a snapshot.
class _StructuredValue extends StatelessWidget {
  const _StructuredValue({this.value, this.entity, this.field, this.technical = false});
  final Object? value;
  final String? entity;
  final String? field;
  final bool technical;

  @override
  Widget build(BuildContext context) {
    final data = value;
    if (!technical && field != null && !AuditPresentation.knownField(field!)) {
      return const Text('Nilai tersedia di informasi teknis');
    }
    if (data is Map && data.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in data.entries)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: _RecordedValue(
                label: technical ? entry.key.toString() : AuditPresentation.field(entry.key as String),
                value: AuditRecordedValue(true, entry.value),
                entity: entity,
                field: entry.key as String,
                technical: technical,
              ),
            ),
        ],
      );
    }
    if (data is List && data.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < data.length; index++)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: _RecordedValue(
                label: 'Item ${index + 1}',
                value: AuditRecordedValue(true, data[index]),
                entity: entity,
                field: field,
                technical: technical,
              ),
            ),
        ],
      );
    }
    final text = AuditPresentation.value(data, entity: entity, field: field, technical: technical);
    return technical ? SelectableText(text) : Text(text);
  }
}

class _TechnicalInformation extends StatelessWidget {
  const _TechnicalInformation({required this.log});
  final AuditTrailItemModel log;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final entry in <String, Object?>{
        'Jenis entitas asli': log.referensiJenis,
        'Peran asli': log.peran,
        'Aksi asli': log.aksi,
        'Nomor referensi': log.referensiId,
        'IP': log.ipAddress,
        'Perangkat': log.device,
      }.entries) ...[
        _RecordedValue(label: entry.key, value: AuditRecordedValue(true, entry.value), technical: true),
        const Divider(height: 16),
      ],
      _RecordedValue(
        label: 'Data sebelum (asli)',
        value: AuditRecordedValue(log.dataSebelum != null, log.dataSebelum),
        technical: true,
      ),
      const SizedBox(height: 8),
      _RecordedValue(
        label: 'Data sesudah (asli)',
        value: AuditRecordedValue(log.dataSesudah != null, log.dataSesudah),
        technical: true,
      ),
    ],
  );
}
