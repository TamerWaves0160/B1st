// lib/reports/report_pdf.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:behaviorfirst/models/fba_bip_draft.dart';

Future<Uint8List> buildFbaBipPdf(FbaBipDraft draft) async {
  final doc = pw.Document();

  pw.Widget kv(String k, String v) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(width: 140, child: pw.Text(k, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
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

  String fmtByMap(Map<String, num> m) =>
      m.entries.map((e) => '${e.key}: ${e.value}').join(' • ');

  String fmtTypeTop(List<TypeCount> xs) =>
      xs.map((e) => '${e.type} (${e.count})').join(' • ');

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
              pw.Text('Generated: ${draft.meta.generatedAt}  •  Engine: ${draft.meta.engine}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Student', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        kv('Name', draft.student.name),
        kv('Student ID', draft.student.id),
        kv('Window', '${draft.student.window.from} → ${draft.student.window.to}'),
        pw.SizedBox(height: 16),

        pw.Text('Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        kv('Total events', '${draft.summary.totalEvents}'),
        kv('Total duration (sec)', '${draft.summary.totalDurationSeconds}'),
        kv('By severity', fmtByMap(draft.summary.bySeverity)),
        kv('Top behavior types', fmtTypeTop(draft.summary.byTypeTop)),
        pw.SizedBox(height: 16),

        pw.Text('Insights', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        kv('Hypothesis', draft.insights.hypothesis),
        kv('Function est.', draft.insights.topFunctions.map((f) => '${f.name} (${f.share})').join(' • ')),
        kv('Severity share', fmtByMap(draft.insights.severityShare)),
        kv('Antecedents', fmtByMap(draft.insights.antecedents)),
        kv('Consequences', fmtByMap(draft.insights.consequences)),
        pw.SizedBox(height: 16),

        pw.Text('Recommendations', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        bullets('Antecedent strategies', draft.recommendations.antecedent.map((r) => '${r.title} — ${r.rationale}').toList()),
        pw.SizedBox(height: 8),
        bullets('Teaching strategies', draft.recommendations.teaching.map((r) => '${r.title} — ${r.rationale}').toList()),
        pw.SizedBox(height: 8),
        bullets('Consequence strategies', draft.recommendations.consequence.map((r) => '${r.title} — ${r.rationale}').toList()),
        pw.SizedBox(height: 8),
        bullets('Reinforcement', draft.recommendations.reinforcement.map((r) => '${r.title} — ${r.rationale}').toList()),
        pw.SizedBox(height: 16),

        pw.Text('Narrative', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        kv('FBA summary', draft.narrative.fbaSummary),
        kv('BIP plan', draft.narrative.bipPlan),
        kv('Rationales', draft.narrative.interventionRationales),
        pw.SizedBox(height: 16),

        pw.Text(draft.narrative.disclaimer, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      ],
    ),
  );

  return doc.save();
}
