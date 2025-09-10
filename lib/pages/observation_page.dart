// lib/pages/observation_page.dart
import 'dart:async';
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

  // Notes & smart hint
  final TextEditingController _notes = TextEditingController();
  bool _showHint = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _notes.addListener(_onNotesChanged);
  }

  @override
  void dispose() {
    _notes.removeListener(_onNotesChanged);
    _debounce?.cancel();
    _notes.dispose();
    super.dispose();
  }

  void _onNotesChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final t = _notes.text.trim().toLowerCase();
      final looksBehavior = RegExp(
        r'(calling out|noncompliance|aggression|elopement|disrupt|transition)',
        caseSensitive: false,
      ).hasMatch(t);
      setState(() => _showHint = looksBehavior && t.length > 12);
    });
  }

  // STEP 5: Ask teacher for mode + prompt before generation
  Future<Map<String, String>?> _askForFbaBip() async {
    String mode = 'BIP';
    final c = TextEditingController();
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate FBA/BIP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: mode,
              items: const [
                DropdownMenuItem(value: 'FBA', child: Text('FBA (analysis-focused)')),
                DropdownMenuItem(value: 'BIP', child: Text('BIP (plan-focused)')),
              ],
              onChanged: (v) => mode = v ?? 'BIP',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: c,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Briefly describe the need (optional)…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {'mode': mode, 'prompt': c.text.trim()}),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  // Wrapper to show dialog, then call the generator
  Future<void> _onGeneratePressed(String source) async {
    final opts = await _askForFbaBip();
    if (opts == null) return;
    await _invokeGenerateDraft(source: source, mode: opts['mode'], prompt: opts['prompt']);
  }

  // STEP 3/5: Generate draft (now accepts optional mode/prompt)
  Future<void> _invokeGenerateDraft({
    required String source,
    String? mode,       // 'FBA' | 'BIP'
    String? prompt,     // teacher free text
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _lastStatus = 'Calling generateFbaBipDraft… ($source)';
    });

    final callId = DateTime.now().microsecondsSinceEpoch.toString();

    try {
      // 1) Aggregate recent events (aggregator auto-picks student)
      final stats = await EventAggregator.fetchAndAggregate();

      // 2) Compute severity shares (0–1) from counts
      final severityTotal = stats.bySeverity.values.fold<int>(0, (a, b) => a + b);
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
        hypothesis: '—', // deterministic hypothesis can be swapped in later
        rankedFunctions: const [],
        severityShare: severityShare,
        antecedentCounts: stats.antecedentCounts,
        consequenceCounts: stats.consequenceCounts,
      );

      final planDto = FbaPlanDTO(
        antecedent: const [],
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

      // NEW: pass teacher options if provided
      if (mode != null && mode.isNotEmpty) envelope['mode'] = mode;
      if (prompt != null && prompt.isNotEmpty) envelope['prompt'] = prompt;

      debugPrint('[AI][$callId][$source] → envelope keys: ${envelope.keys.toList()}');

      // 4) Call Functions (typed), then render PDF
      final DraftResponse resp =
      await AiClient.instance.generateFbaBipDraftTyped(payload: envelope);

      debugPrint('[AI][$callId][$source] ← engine=${resp.draft.meta.engine}, student=${resp.draft.student.name}, events=${resp.draft.summary.totalEvents}');

      final bytes = await buildFbaBipPdf(resp.draft);
      await Printing.layoutPdf(onLayout: (_) async => bytes);

      if (!mounted) return;
      setState(() => _lastStatus = 'PDF ready ($source).');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Draft generated → PDF preview')));
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

  // STEP 3/4: Intervention KB — bottom sheet
  Future<void> _openInterventionRequest() async {
    final controller = TextEditingController(text: _lastBehaviorPhraseFromNotes() ?? '');
    List<Map<String, dynamic>> results = [];
    bool busy = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSt) {
            Future<void> run() async {
              setSt(() => busy = true);
              try {
                results = await AiClient.instance.recommendInterventions(
                  query: controller.text.trim(),
                  topK: 5,
                );
              } finally {
                setSt(() => busy = false);
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Describe the behavior or context'),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g., calling out during whole-group instruction',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => run(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(
                      onPressed: busy ? null : run,
                      child: const Text('Find Interventions'),
                    ),
                    if (busy)
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (results.isNotEmpty)
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final it = results[i];
                        final steps = ((it['steps'] as List?) ?? const []).join('\n• ');
                        return Card(
                          child: ListTile(
                            title: Text(it['title'] ?? ''),
                            subtitle: Text([
                              if ((it['rationale'] ?? '').toString().isNotEmpty)
                                'Rationale: ${it['rationale']}',
                              if (steps.isNotEmpty) 'Steps:\n• $steps',
                            ].join('\n')),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Pull last sentence-ish from notes to seed the query
  String? _lastBehaviorPhraseFromNotes() {
    final t = _notes.text.trim();
    if (t.isEmpty) return null;
    final parts = t.split(RegExp(r'[.!?]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.last : t;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Observation'),
        actions: [
          // STEP 3: Intervention request button
          IconButton(
            tooltip: 'Intervention request',
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _busy ? null : _openInterventionRequest,
          ),
          // STEP 5: Generate (opens mode/prompt dialog, then calls)
          IconButton(
            tooltip: 'Generate FBA/BIP draft',
            icon: const Icon(Icons.science_outlined),
            onPressed: _busy ? null : () => _onGeneratePressed('appbar'),
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
                    'Use the lightbulb to request interventions. '
                        'Use the beaker to generate an FBA/BIP draft from recent observations.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // STEP 4: Notes field with smart hint
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextField(
                        controller: _notes,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Type observations… (e.g., calling out during whole-group)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_showHint)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: _busy ? null : _openInterventionRequest,
                            child: const Icon(Icons.lightbulb, color: Colors.amber),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _onGeneratePressed('body'),
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
