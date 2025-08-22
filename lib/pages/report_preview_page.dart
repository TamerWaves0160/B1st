// =============================================================
// BehaviorFirst — lib/pages/report_preview_page.dart (Complete)
// -------------------------------------------------------------
// Shows a 14-day dataset preview for a student, on-screen charts, and
// actions to: Analyze (deterministic), Recommendations (deterministic),
// and Export PDF (server-validated draft → typed PDF preview + share).
// =============================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:cloud_functions/cloud_functions.dart'; // <-- needed for FirebaseFunctionsException

import '../services/report_dataset.dart';
import '../services/behavior_insights.dart';
import '../services/intervention_engine.dart';
import '../widgets/behavior_charts.dart'; // SeverityBarChart, TypeBarChart

// Newer pieces wired into this page:
import 'package:behaviorfirst/services/ai_client.dart';
import 'package:behaviorfirst/reports/report_pdf.dart'; // buildFbaBipPdf(FbaBipDraft)
import 'package:behaviorfirst/models/fba_bip_draft.dart'; // DraftResponse/FbaBipDraft
import 'package:behaviorfirst/adapters/fba_payload.dart'; // DTOs + buildFbaEnvelope
import 'package:behaviorfirst/services/event_aggregator.dart'; // Firestore aggregation

class ReportPreviewPage extends StatefulWidget {
  final String ownerUid;
  final String studentId;
  final String studentName;

  const ReportPreviewPage({
    super.key,
    required this.ownerUid,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ReportPreviewPage> createState() => _ReportPreviewPageState();
}

class _ReportPreviewPageState extends State<ReportPreviewPage> {
  late final ReportDataService _svc;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _svc = ReportDataService();
  }

  Future<void> _exportPdf() async {
    final messenger = ScaffoldMessenger.of(context); // snapshot before awaits
    if (_busy) return;
    setState(() => _busy = true);

    try {
      // 1) Load the same dataset you preview on screen (14-day default in your service)
      final ReportDataset ds = await _svc.fetch(
        ownerUid: widget.ownerUid,
        studentId: widget.studentId,
      );

      // 2) Deterministic analysis & plan (for hypothesis and seed recs)
      final insightsDet = BehaviorInsightsService().analyze(ds);
      final planDet = InterventionEngine().recommend(ds: ds, insights: insightsDet);

      // 3) Firestore aggregation for strict counts
      final stats = await EventAggregator.fetchAndAggregate(
        studentId: widget.studentId,
        studentName: widget.studentName,
        window: const Duration(days: 14),
      );

      // 4) Compute severity shares from counts (server expects 0..1)
      final sevTotal = stats.bySeverity.values.fold<int>(0, (a, b) => a + b);
      final severityShare = <String, num>{};
      if (sevTotal > 0) {
        stats.bySeverity.forEach((k, v) {
          severityShare[k] = v / sevTotal;
        });
      }

      // 5) Build the strict envelope for the callable (dataset + insights + plan)
      final datasetDto = FbaDatasetDTO(
        studentName: stats.studentName,
        studentId: stats.studentId,
        from: stats.from,
        to: stats.to,
        totalEvents: stats.totalEvents,
        totalDurationSeconds: stats.totalDurationSeconds,
        bySeverity: stats.bySeverity,
        byType: stats.byType,
      );

      final insightsDto = FbaInsightsDTO(
        hypothesis: insightsDet.hypothesis, // deterministic hypothesis
        rankedFunctions: const [], // optional
        severityShare: severityShare,
        antecedentCounts: stats.antecedentCounts,
        consequenceCounts: stats.consequenceCounts,
      );

      List<Map<String, String>> toRecList(List<InterventionRec> xs) =>
          xs.map((r) => {'title': r.title, 'rationale': r.rationale}).toList();

      final planDto = FbaPlanDTO(
        antecedent: toRecList(planDet.antecedent),
        teaching: toRecList(planDet.teaching),
        consequence: toRecList(planDet.consequence),
        reinforcement: toRecList(planDet.reinforcement),
      );

      final String callId = DateTime.now().microsecondsSinceEpoch.toString();
      final envelope = buildFbaEnvelope(
        meta: {
          'source': 'report_preview',
          'callId': callId,
          'clientTs': DateTime.now().toIso8601String(),
          'platform': 'flutter',
        },
        dataset: datasetDto,
        insights: insightsDto,
        plan: planDto,
      );

      // 6) Call the validated function and parse to the typed model
      final DraftResponse resp =
      await AiClient.instance.generateFbaBipDraftTyped(payload: envelope);

      // 7) Build the PDF from the typed draft and present + share
      final Uint8List bytes = await buildFbaBipPdf(resp.draft);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'BehaviorFirst_${stats.studentName}.pdf',
      );
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Callable error: ${e.code} • ${e.message ?? ''}')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _analyzeNoAI() async {
    final ds = await _svc.fetch(ownerUid: widget.ownerUid, studentId: widget.studentId);
    final insights = BehaviorInsightsService().analyze(ds);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insights (deterministic)'),
        content: SingleChildScrollView(
          child: Text(
            '${insights.hypothesis}\n\n'
                'Antecedents: ${insights.antecedentCounts}\n'
                'Consequences: ${insights.consequenceCounts}\n'
                'Severity share: ${insights.severityShare}',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _recommendNoAI() async {
    final ds = await _svc.fetch(ownerUid: widget.ownerUid, studentId: widget.studentId);
    final insights = BehaviorInsightsService().analyze(ds);
    final plan = InterventionEngine().recommend(ds: ds, insights: insights);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Intervention Recommendations'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Antecedent / Prevention', plan.antecedent),
              _section('Teaching / Skill Building', plan.teaching),
              _section('Consequence / Response', plan.consequence),
              _section('Reinforcement / Environment', plan.reinforcement),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      IconButton(
        tooltip: 'Analyze (no AI) — heuristics only',
        icon: const Icon(Icons.psychology_alt_outlined),
        onPressed: _busy ? null : _analyzeNoAI,
      ),
      IconButton(
        tooltip: 'Recommendations (no AI)',
        icon: const Icon(Icons.volunteer_activism_outlined),
        onPressed: _busy ? null : _recommendNoAI,
      ),
      IconButton(
        tooltip: 'Export PDF',
        onPressed: _busy ? null : _exportPdf,
        icon: _busy
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.picture_as_pdf_outlined),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Report Preview — ${widget.studentName}'),
        actions: actions,
      ),
      body: FutureBuilder<ReportDataset>(
        future: _svc.fetch(ownerUid: widget.ownerUid, studentId: widget.studentId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load dataset: ${snap.error}'));
          }
          final ds = snap.data!;
          if (ds.rows.isEmpty) {
            return const Center(child: Text('No events in the selected window.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${ds.totalEvents} events • ${ds.from.toLocal()} → ${ds.to.toLocal()}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // On-screen charts; these also make nice previews before export
              RepaintBoundary(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: SeverityBarChart(ds: ds),
                ),
              ),
              const SizedBox(height: 24),

              RepaintBoundary(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: TypeBarChart(ds: ds),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Widget _section(String title, List<InterventionRec> items) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        if (items.isEmpty)
          const Text('— none —')
        else
          ...items.map(
                (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• ${r.title} — ${r.rationale}'),
            ),
          ),
      ],
    ),
  );
}
