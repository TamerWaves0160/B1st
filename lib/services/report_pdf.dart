// lib/reports/report_pdf.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:behaviorfirst/models/fba_bip_draft.dart';

String fmtPercent(num x) => '${(x * 100).round()}%';

String fmtDate(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return iso;
  return DateFormat('MMM d, y h:mm a').format(dt);
}

List<MapEntry<String, num>> sortMapDesc(Map<String, num> m) {
  final entries = m.entries.toList();
  entries.sort((a, b) => b.value.compareTo(a.value));
  return entries;
}

pw.Widget kv(String k, String v) => pw.Row(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Container(width: 170, child: pw.Text(k, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
    pw.Expanded(child: pw.Text(v)),
  ],
);

pw.Widget bullets(String title, List<String> items) => pw.Column(
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

  String bySeverityStr = draft.summary.bySeverity.isEmpty
      ? '—'
      : sortMapDesc(draft.summary.bySeverity)
      .map((e) => '${e.key}: ${e.value}')
      .join(' • ');

  String severityShareStr = draft.insights.severityShare.isEmpty
      ? '—'
      : sortMapDesc(draft.insights.severityShare)
      .map((e) => '${e.key}: ${fmtPercent(e.value)}')
      .join(' • ');

  String antecedentsStr = draft.insights.antecedents.isEmpty
      ? '—'
      : sortMapDesc(draft.insights.antecedents)
      .map((e) => '${e.key}: ${e.value}')
      .join(' • ');

  String consequencesStr = draft.insights.consequences.isEmpty
      ? '—'
      : sortMapDesc(draft.insights.consequences)
      .map((e) => '${e.key}: ${e.value}')
      .join(' • ');

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
              pw.Text('Generated: ${fmtDate(draft.meta.generatedAt)}    •    Engine: ${draft.meta.engine}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.SizedBox(height: 4),

        // Student
        pw.Text('Student', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        kv('Name', draft.student.name),
        kv('Student ID', draft.student.id),
        kv('Window', '${fmtDate(draft.student.window.from)} → ${fmtDate(draft.student.window.to)}'),
        pw.SizedBox(height: 16),

        // Summary
        pw.Text('Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        kv('Total events', '${draft.summary.totalEvents}'),
        kv('Total duration (sec)', '${draft.summary.totalDurationSeconds}'),
        kv('By severity', bySeverityStr),
        kv('Top behavior types', topTypesStr),
        pw.SizedBox(height: 16),

        // Insights
        pw.Text('Insights', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        kv('Hypothesis', draft.insights.hypothesis.isEmpty ? '—' : draft.insights.hypothesis),
        kv('Function est.', fnEst),
        kv('Severity share', severityShareStr),
        kv('Antecedents', antecedentsStr),
        kv('Consequences', consequencesStr),
        pw.SizedBox(height: 16),

        // Recommendations
        pw.Text('Recommendations', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        bullets('Antecedent strategies',
            draft.recommendations.antecedent.map((r) => '${r.title} — ${r.rationale}').toList()),
        pw.SizedBox(height: 8),
        bullets('Teaching strategies',
            draft.recommendations.teaching.map((r) => '${r.title} — ${r.rationale}').toList()),
        pw.SizedBox(height: 8),
        bullets('Consequence strategies',
            draft.recommendations.consequence.map((r) => '${r.title} — ${r.rationale}').toList()),
        pw.SizedBox(height: 8),
        bullets('Reinforcement',
            draft.recommendations.reinforcement.map((r) => '${r.title} — ${r.rationale}').toList()),
        pw.SizedBox(height: 16),

        // Narrative
        pw.Text('Narrative', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        kv('FBA summary', draft.narrative.fbaSummary.isEmpty ? '—' : draft.narrative.fbaSummary),
        kv('BIP plan', draft.narrative.bipPlan.isEmpty ? '—' : draft.narrative.bipPlan),
        kv('Rationales', draft.narrative.interventionRationales.isEmpty ? '—' : draft.narrative.interventionRationales),
        pw.SizedBox(height: 16),

        pw.Text(draft.narrative.disclaimer, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      ],
    ),
  );

  return doc.save();
}
