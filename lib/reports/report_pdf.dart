import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:behaviorfirst/models/fba_bip_draft.dart';

String _fmtPercent(num x) => '${(x * 100).round()}%';
String _fmtDate(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return iso;
  return DateFormat('MMM d, y h:mm a').format(dt);
}
List<MapEntry<String, num>> _sortDesc(Map<String, num> m) {
  final entries = m.entries.toList();
  entries.sort((a, b) => b.value.compareTo(a.value));
  return entries;
}

pw.Widget _kv(String k, String v) => pw.Row(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Container(width: 170, child: pw.Text(k, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
    pw.Expanded(child: pw.Text(v)),
  ],
);
pw.Widget _bullets(String title, List<String> items) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    pw.SizedBox(height: 6),
    if (items.isEmpty) pw.Text('—'),
    if (items.isNotEmpty)
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items.map((e) => pw.Bullet(text: e)).toList(),
      ),
  ],
);

Future<Uint8List> buildFbaBipPdf(FbaBipDraft draft) async {
  final doc = pw.Document();

  final bySeverityStr = draft.summary.bySeverity.isEmpty
      ? '—'
      : _sortDesc(draft.summary.bySeverity).map((e) => '${e.key}: ${e.value}').join(' • ');
  final severityShareStr = draft.insights.severityShare.isEmpty
      ? '—'
      : _sortDesc(draft.insights.severityShare).map((e) => '${e.key}: ${_fmtPercent(e.value)}').join(' • ');
  final antecedentsStr = draft.insights.antecedents.isEmpty
      ? '—'
      : _sortDesc(draft.insights.antecedents).map((e) => '${e.key}: ${e.value}').join(' • ');
  final consequencesStr = draft.insights.consequences.isEmpty
      ? '—'
      : _sortDesc(draft.insights.consequences).map((e) => '${e.key}: ${e.value}').join(' • ');
  final topTypesStr = draft.summary.byTypeTop.isEmpty
      ? '—'
      : draft.summary.byTypeTop.map((e) => '${e.type} (${e.count})').join(' • ');
  final fnEst = draft.insights.topFunctions.isEmpty
      ? '—'
      : draft.insights.topFunctions.map((f) => '${f.name} (${f.share})').join(' • ');

  doc.addPage(
    pw.MultiPage(
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 10)),
      ),
      build: (ctx) => [
        pw.Header(
          level: 0,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('FBA/BIP Draft', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Generated: ${_fmtDate(draft.meta.generatedAt)}    •    Engine: ${draft.meta.engine}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),

        pw.Text('Student', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _kv('Name', draft.student.name),
        _kv('Student ID', draft.student.id),
        _kv('Window', '${_fmtDate(draft.student.window.from)} → ${_fmtDate(draft.student.window.to)}'),
        pw.SizedBox(height: 16),

        pw.Text('Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _kv('Total events', '${draft.summary.totalEvents}'),
        _kv('Total duration (sec)', '${draft.summary.totalDurationSeconds}'),
        _kv('By severity', bySeverityStr),
        _kv('Top behavior types', topTypesStr),
        pw.SizedBox(height: 16),

        pw.Text('Insights', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _kv('Hypothesis', draft.insights.hypothesis.isEmpty ? '—' : draft.insights.hypothesis),
        _kv('Function est.', fnEst),
        _kv('Severity share', severityShareStr),
        _kv('Antecedents', antecedentsStr),
        _kv('Consequences', consequencesStr),
        pw.SizedBox(height: 16),

        pw.Text('Recommendations', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _bullets('Antecedent strategies',
            draft.recommendations.antecedent.map((r) => '${r.title} — ${r.rationale}').toList()),
        pw.SizedBox(height: 8),
        _bullets('Teaching strategies',
            draft.recommendations.teaching.map((r) => '${r.title} — ${r.rationale}').toList()),
        pw.SizedBox(height: 8),
        _bullets('Consequence strategies',
            draft.recommendations.consequence.map((r) => '${r.title} — ${r.rationale}').toList()),
        pw.SizedBox(height: 8),
        _bullets('Reinforcement',
            draft.recommendations.reinforcement.map((r) => '${r.title} — ${r.rationale}').toList()),
        pw.SizedBox(height: 16),

        pw.Text('Narrative', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _kv('FBA summary', draft.narrative.fbaSummary.isEmpty ? '—' : draft.narrative.fbaSummary),
        _kv('BIP plan', draft.narrative.bipPlan.isEmpty ? '—' : draft.narrative.bipPlan),
        _kv('Rationales', draft.narrative.interventionRationales.isEmpty ? '—' : draft.narrative.interventionRationales),
        pw.SizedBox(height: 16),

        pw.Text(draft.narrative.disclaimer, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      ],
    ),
  );

  return doc.save();
}