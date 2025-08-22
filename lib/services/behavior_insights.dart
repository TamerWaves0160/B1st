// =============================================================
// BehaviorFirst — lib/services/behavior_insights.dart (Annotated)
// -------------------------------------------------------------
// Purpose
//   Deterministic analysis of a ReportDataset that extracts simple, auditable
//   signals BEFORE any AI is involved. We compute:
//     • counts by antecedent / consequence / type / severity
//     • a lightweight score for likely behavior functions:
//         - Escape / Avoid
//         - Attention
//         - Tangible / Access
//         - Sensory / Automatic
//     • a confidence value (0..1) and a short hypothesis string
//
// Why deterministic first?
//   - Auditable and reproducible: same input → same output
//   - Gives the AI a clean scaffold to elaborate (FBA, BIP, interventions)
//   - Lets you test the pipeline without any model calls
//
// Notes
//   - Heuristics below are intentionally conservative and transparent.
//   - You can tune the keyword → function weights as you collect data.
// =============================================================

import 'report_dataset.dart';

/// Canonical function names used throughout the app/AI.
class BehaviorFunctionName {
  static const escapeAvoid = 'Escape/Avoid';
  static const attention = 'Attention';
  static const tangibleAccess = 'Tangible/Access';
  static const sensoryAutomatic = 'Sensory/Automatic';
}

class FunctionScore {
  final String name;      // one of BehaviorFunctionName.*
  final double score;     // raw score before normalization
  final double share;     // score / sumScores (0..1), 0 if sum=0
  const FunctionScore({required this.name, required this.score, required this.share});
}

class BehaviorInsights {
  final Map<String, int> antecedentCounts;
  final Map<String, int> consequenceCounts;
  final Map<String, int> typeCounts;       // copy of ds.byType
  final Map<String, double> severityShare; // Mild/Moderate/Severe → 0..1

  final List<FunctionScore> rankedFunctions; // sorted desc by share
  final double confidence; // top.share (0..1)
  final String hypothesis; // one‑liner

  const BehaviorInsights({
    required this.antecedentCounts,
    required this.consequenceCounts,
    required this.typeCounts,
    required this.severityShare,
    required this.rankedFunctions,
    required this.confidence,
    required this.hypothesis,
  });

  FunctionScore get top => rankedFunctions.isNotEmpty
      ? rankedFunctions.first
      : const FunctionScore(name: BehaviorFunctionName.escapeAvoid, score: 0, share: 0);
}

class BehaviorInsightsService {
  BehaviorInsights analyze(ReportDataset ds) {
    // ---- 1) Basic tallies from rows ----
    final ac = <String, int>{};
    final cc = <String, int>{};

    for (final r in ds.rows) {
      final a = r.antecedent?.trim();
      if (a != null && a.isNotEmpty) {
        ac.update(a, (v) => v + 1, ifAbsent: () => 1);
      }
      final c = r.consequence?.trim();
      if (c != null && c.isNotEmpty) {
        cc.update(c, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    // ---- 2) Severity share (0..1) ----
    final mild = (ds.bySeverity['Mild'] ?? 0).toDouble();
    final mod  = (ds.bySeverity['Moderate'] ?? 0).toDouble();
    final sev  = (ds.bySeverity['Severe'] ?? 0).toDouble();
    final total = (mild + mod + sev);
    Map<String, double> sevShare;
    if (total <= 0) {
      sevShare = const {'Mild': 0, 'Moderate': 0, 'Severe': 0};
    } else {
      sevShare = {
        'Mild': mild / total,
        'Moderate': mod / total,
        'Severe': sev / total,
      };
    }

    // ---- 3) Heuristic scoring for behavior function ----
    // Weights are transparent and easy to adjust.
    final scores = <String, double>{
      BehaviorFunctionName.escapeAvoid: 0,
      BehaviorFunctionName.attention: 0,
      BehaviorFunctionName.tangibleAccess: 0,
      BehaviorFunctionName.sensoryAutomatic: 0,
    };

    void add(String fn, double w) => scores.update(fn, (v) => v + w, ifAbsent: () => w);

    // 3a) Antecedent keywords → function hints
    ac.forEach((k, n) {
      final key = k.toLowerCase();
      if (key.contains('demand') || key.contains('task') || key.contains('transition')) {
        add(BehaviorFunctionName.escapeAvoid, 2.0 * n);
      }
      if (key.contains('attention')) {
        add(BehaviorFunctionName.attention, 2.0 * n);
      }
      if (key.contains('denied') || key.contains('access')) {
        add(BehaviorFunctionName.tangibleAccess, 2.0 * n);
      }
      if (key.contains('unstructured') || key.contains('sensory')) {
        add(BehaviorFunctionName.sensoryAutomatic, 1.5 * n);
      }
    });

    // 3b) Consequence keywords → likely maintaining variable
    cc.forEach((k, n) {
      final key = k.toLowerCase();
      if (key.contains('break')) {
        add(BehaviorFunctionName.escapeAvoid, 2.5 * n);
      }
      if (key.contains('removal')) {
        add(BehaviorFunctionName.tangibleAccess, 2.0 * n);
      }
      if (key.contains('planned ignoring')) {
        add(BehaviorFunctionName.attention, 1.5 * n);
      }
      if (key.contains('redirection')) {
        add(BehaviorFunctionName.escapeAvoid, 0.5 * n); // weak signal
      }
      if (key.contains('call home')) {
        add(BehaviorFunctionName.attention, 1.0 * n); // adult attention involved
      }
    });

    // 3c) Duration bias: long average durations often pair with escape or sensory
    final avgDur = ds.totalEvents == 0 ? 0 : ds.totalDurationSeconds / ds.totalEvents;
    if (avgDur >= 60) {
      // If unstructured settings present, nudge Sensory; else Escape.
      final hasUnstructured = ac.keys.any((k) => k.toLowerCase().contains('unstructured'));
      if (hasUnstructured) {
        add(BehaviorFunctionName.sensoryAutomatic, 1.0);
      } else {
        add(BehaviorFunctionName.escapeAvoid, 1.0);
      }
    }

    // 3d) Severity minor bias: heavy Severe skew can co-occur with access or escape
    if (sevShare['Severe']! >= 0.4) {
      add(BehaviorFunctionName.tangibleAccess, 0.5);
      add(BehaviorFunctionName.escapeAvoid, 0.5);
    }

    // Normalize
    final sumScores = scores.values.fold<double>(0, (a, b) => a + b);
    final ranked = scores.entries
        .map((e) => FunctionScore(name: e.key, score: e.value, share: sumScores == 0 ? 0 : e.value / sumScores))
        .toList()
      ..sort((a, b) => b.share.compareTo(a.share));
    final conf = ranked.isEmpty ? 0.0 : ranked.first.share;

    // Hypothesis string
    String hyp;
    if (sumScores == 0) {
      hyp = 'Insufficient signals to infer a likely function. Collect more ABC data.';
    } else {
      final tops = ranked.take(2).where((f) => f.share > 0).map((f) => f.name).join(' / ');
      hyp = 'Most likely function: $tops (confidence ${(conf * 100).toStringAsFixed(0)}%).';
    }

    return BehaviorInsights(
      antecedentCounts: Map.unmodifiable(ac),
      consequenceCounts: Map.unmodifiable(cc),
      typeCounts: Map.unmodifiable(ds.byType),
      severityShare: Map.unmodifiable(sevShare),
      rankedFunctions: List.unmodifiable(ranked),
      confidence: conf,
      hypothesis: hyp,
    );
  }
}
