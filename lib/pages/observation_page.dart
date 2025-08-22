// lib/pages/observation_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:printing/printing.dart';

import 'package:behaviorfirst/services/ai_client.dart';
import 'package:behaviorfirst/models/fba_bip_draft.dart';
import 'package:behaviorfirst/reports/report_pdf.dart';
import 'package:behaviorfirst/adapters/fba_payload.dart';
import 'package:behaviorfirst/services/event_aggregator.dart';

class ObservationPage extends StatefulWidget {
  const ObservationPage({super.key});

  @override
  State<ObservationPage> createState() => _ObservationPageState();
}

class _ObservationPageState extends State<ObservationPage> {
  bool _busy = false;
  String? _lastStatus;

  Future<void> _invokeGenerateDraft({required String source}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _lastStatus = 'Calling generateFbaBipDraft… ($source)';
    });

    final callId = DateTime.now().microsecondsSinceEpoch.toString();

    try {
      // 1) Aggregate last 7 days for the current user; auto-picks student with most events
      final stats = await EventAggregator.fetchAndAggregate();

      // 2) Compute severity shares (0–1) from counts
      final severityTotal =
      stats.bySeverity.values.fold<int>(0, (a, b) => a + b);
      final severityShare = <String, num>{};
      if (severityTotal > 0) {
        stats.bySeverity.forEach((k, v) {
          severityShare[k] = v / severityTotal;
        });
      }

      // 3) Build DTOs for callable payload
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
        hypothesis: '—', // fill with your hypothesis generator later
        rankedFunctions: const [], // optional future inference
        severityShare: severityShare,
        antecedentCounts: stats.antecedentCounts,
        consequenceCounts: stats.consequenceCounts,
      );

      final planDto = FbaPlanDTO(
        antecedent: const [],   // leave empty; server can fill placeholders/AI text
        teaching: const [],
        consequence: const [],
        reinforcement: const [],
      );

      final envelope = buildFbaEnvelope(
        meta: {
          'source': source,
          'callId': callId,
          'clientTs': DateTime.now().toIso8601String(),
          'platform': 'flutter',
        },
        dataset: datasetDto,
        insights: insightsDto,
        plan: planDto,
      );

      debugPrint('[AI][$callId][$source] → envelope keys: ${envelope.keys.toList()}');

      // 4) Call Functions (typed), then render PDF
      final DraftResponse resp =
      await AiClient.instance.generateFbaBipDraftTyped(payload: envelope);

      debugPrint('[AI][$callId][$source] ← student=${resp.draft.student.name}, events=${resp.draft.summary.totalEvents}');

      final bytes = await buildFbaBipPdf(resp.draft);
      await Printing.layoutPdf(onLayout: (_) async => bytes);

      if (!mounted) return;
      setState(() => _lastStatus = 'PDF ready ($source).');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft generated → PDF preview')),
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('[AI][ERR][$callId][$source] code=${e.code}, msg=${e.message}, details=${e.details}');
      debugPrintStack(label: '[AI][ERR][$callId][$source]', stackTrace: st);
      if (!mounted) return;
      final msg = switch (e.code) {
        'not-found' => 'NOT_FOUND: name/region mismatch or not deployed.',
        'unauthenticated' => 'Unauthenticated: sign in first.',
        'permission-denied' => '403: App Check/IAM/Rules.',
        'invalid-argument' => 'Invalid argument: server expects dataset/insights/plan.',
        _ => 'Callable error: ${e.code}',
      };
      setState(() => _lastStatus = msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on StateError catch (e, st) {
      // e.g., not signed in for Firestore aggregation
      debugPrint('[AI][ERR][$callId][$source] $e');
      debugPrintStack(label: '[AI][ERR][$callId][$source]', stackTrace: st);
      if (!mounted) return;
      setState(() => _lastStatus = 'Not signed in. Please authenticate.');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Not signed in.')));
    } catch (e, st) {
      debugPrint('[AI][ERR][$callId][$source] $e');
      debugPrintStack(label: '[AI][ERR][$callId][$source]', stackTrace: st);
      if (mounted) {
        setState(() => _lastStatus = 'Unexpected error. See console.');
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Unexpected error.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Observation'),
        actions: [
          IconButton(
            tooltip: 'Generate FBA/BIP draft',
            icon: const Icon(Icons.science_outlined),
            onPressed: _busy ? null : () => _invokeGenerateDraft(source: 'appbar'),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tap the beaker in the AppBar or the button below to generate a draft PDF from recent observations.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _invokeGenerateDraft(source: 'body'),
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Generate FBA/BIP Draft'),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Working…'),
                  ],
                  if (_lastStatus != null) ...[
                    const SizedBox(height: 16),
                    Text(_lastStatus!, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
