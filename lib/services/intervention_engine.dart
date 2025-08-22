// =============================================================
// BehaviorFirst — lib/services/intervention_engine.dart (Annotated)
// -------------------------------------------------------------
// Purpose: Deterministic, auditable intervention recommendations that
// pair with BehaviorInsights (no AI yet). This produces a structured
// InterventionPlan you can render in the UI and also pass into the
// AI step to elaborate into a BIP.
//
// Inputs: ReportDataset + BehaviorInsights
// Outputs: InterventionPlan with categories:
//   - Antecedent/Prevention
//   - Teaching/Skill Building
//   - Consequence/Response
//   - Reinforcement/Environment
//
// Scoring logic (transparent weights you can tune):
//   - Base weights by inferred function (Escape, Attention, Tangible, Sensory)
//   - Bonuses from salient antecedents (e.g., Transition, Demand placed)
//   - Severity tilt: severe → add safety/de-escalation; mild → teaching focus
//   - Behavior-type nudges (e.g., Aggression, Elopement)
//
// NOTE: This is educational guidance, not medical advice. Always review
// with your team and follow district policy and safety protocols.
// =============================================================

import 'report_dataset.dart';
import 'behavior_insights.dart';

class InterventionCategory {
  static const antecedent = 'Antecedent / Prevention';
  static const teaching = 'Teaching / Skill Building';
  static const consequence = 'Consequence / Response';
  static const reinforcement = 'Reinforcement / Environment';
}

class InterventionRec {
  final String title;        // short label that can appear in a checklist
  final String rationale;    // why this is here (data-linked)
  final String category;     // one of InterventionCategory.*
  final double weight;       // for ranking (0..∞)

  const InterventionRec({
    required this.title,
    required this.rationale,
    required this.category,
    required this.weight,
  });
}

class InterventionPlan {
  final List<InterventionRec> antecedent;
  final List<InterventionRec> teaching;
  final List<InterventionRec> consequence;
  final List<InterventionRec> reinforcement;

  const InterventionPlan({
    required this.antecedent,
    required this.teaching,
    required this.consequence,
    required this.reinforcement,
  });
}

class InterventionEngine {
  InterventionPlan recommend({required ReportDataset ds, required BehaviorInsights insights}) {
    final recs = <InterventionRec>[];

    // Helpers
    double sev(String k) => insights.severityShare[k] ?? 0.0; // share 0..1
    bool hasAnte(String key) => insights.antecedentCounts.keys.any((k) => k.toLowerCase().contains(key));
    int typeCount(String key) => insights.typeCounts.entries
        .where((e) => e.key.toLowerCase().contains(key))
        .fold(0, (a, e) => a + e.value);

    // Base function weights (from insights)
    double fnWeight(String fn) {
      final f = insights.rankedFunctions.firstWhere(
            (x) => x.name == fn,
        orElse: () => const FunctionScore(name: '', score: 0, share: 0),
      );
      return f.share; // 0..1
    }

    // ---------- 1) Function-aligned foundations ----------
    final wEscape   = fnWeight(BehaviorFunctionName.escapeAvoid);
    final wAttn     = fnWeight(BehaviorFunctionName.attention);
    final wAccess   = fnWeight(BehaviorFunctionName.tangibleAccess);
    final wSensory  = fnWeight(BehaviorFunctionName.sensoryAutomatic);

    void add(String title, String why, String cat, double w) {
      if (w <= 0) return;
      recs.add(InterventionRec(title: title, rationale: why, category: cat, weight: w));
    }

    // Escape/Avoid
    add('Modify task demands (chunking, shorten, scaffold)',
        'High Escape/Avoid signal; reduce response effort to increase compliance.',
        InterventionCategory.antecedent, 1.5 * wEscape + (hasAnte('demand') ? 0.5 : 0));
    add('Offer choice of task order / materials',
        'Choice reduces avoidance by increasing control and predictability.',
        InterventionCategory.antecedent, 1.0 * wEscape);
    add('Teach functional break request (FCR: "I need a break")',
        'Replacement behavior for Escape/Avoid; prompt and reinforce appropriate break requests.',
        InterventionCategory.teaching, 1.8 * wEscape + (hasAnte('demand') ? 0.4 : 0));
    add('Visual schedule + transition warnings',
        'If transitions trigger behavior, previewing steps lowers anxiety and escape responding.',
        InterventionCategory.antecedent, 1.2 * wEscape + (hasAnte('transition') ? 0.6 : 0));

    // Attention
    add('Noncontingent attention schedule (NCR)',
        'Provide attention on a timer so attention-seeking is less efficient via problem behavior.',
        InterventionCategory.reinforcement, 1.6 * wAttn + (hasAnte('attention') ? 0.4 : 0));
    add('Teach attention request (tap card / script)',
        'Replacement behavior to appropriately request attention; reinforce immediately.',
        InterventionCategory.teaching, 1.7 * wAttn);
    add('Planned ignoring for minor attention-maintained behaviors',
        'Reduce reinforcement for problem behavior while reinforcing alternatives (DRA).',
        InterventionCategory.consequence, 1.2 * wAttn * (sev('Severe') < 0.3 ? 1 : 0));

    // Tangible / Access
    add('First–Then with clear access rules',
        'Clarifies contingencies for item/activity access to reduce access-maintained behavior.',
        InterventionCategory.antecedent, 1.5 * wAccess + (hasAnte('denied') ? 0.5 : 0));
    add('Teach functional communication to request items/turns (FCR)',
        'Replacement for grabbing/arguing; reinforce requests promptly and consistently.',
        InterventionCategory.teaching, 1.8 * wAccess);
    add('Token economy or differential reinforcement (DRA)',
        'Reinforce alternative behaviors that earn access; withhold for problem behavior.',
        InterventionCategory.reinforcement, 1.4 * wAccess);

    // Sensory / Automatic
    add('Sensory alternatives / movement breaks (scheduled)',
        'If behavior is automatically reinforced, competing stimulation can reduce problem behavior.',
        InterventionCategory.antecedent, 1.6 * wSensory + (hasAnte('unstructured') ? 0.4 : 0));
    add('Teach self-regulation (breathing, count-5, break space)',
        'Skills to manage arousal when sensory triggers are present.',
        InterventionCategory.teaching, 1.3 * wSensory);

    // ---------- 2) Severity tilt ----------
    final severeBias = sev('Severe');
    if (severeBias >= 0.4) {
      add('Crisis response protocol / de-escalation steps',
          'High Severe share; ensure safety procedures are standardized and trained.',
          InterventionCategory.consequence, 1.5 + severeBias);
      add('Environment scan: reduce triggers (noise, crowding, proximity)',
          'Mitigate high-arousal contexts linked to severe episodes.',
          InterventionCategory.antecedent, 1.0 + 0.5 * severeBias);
    }

    // ---------- 3) Behavior-type nudges ----------
    final aggr = typeCount('aggression');
    final elop = typeCount('elopement');

    if (aggr > 0) {
      add('Safety plan: blocking, room arrangement, staff roles',
          'Aggression present; define safe responses and staff positioning.',
          InterventionCategory.consequence, 1.2 + 0.1 * aggr);
      add('Teach replacement for protest/refusal (e.g., "No thanks" + option)',
          'Gives a safe, teachable alternative to aggressive protest.',
          InterventionCategory.teaching, 1.0 + 0.05 * aggr);
    }

    if (elop > 0) {
      add('Elopement prevention: visual boundaries, proximity, check-in routine',
          'Documented elopement; set physical/visual cues and proximity supports.',
          InterventionCategory.antecedent, 1.3 + 0.1 * elop);
      add('Teach ask-to-walk/break and return routine',
          'Functional alternative to leaving area; practice with reinforcement.',
          InterventionCategory.teaching, 1.1 + 0.05 * elop);
    }

    // ---------- 4) Sort, dedupe, and bucket ----------
    recs.sort((a, b) => b.weight.compareTo(a.weight));

    List<InterventionRec> pick(String cat, {int max = 6}) {
      final seen = <String>{};
      final out = <InterventionRec>[];
      for (final r in recs.where((r) => r.category == cat)) {
        final key = r.title.toLowerCase();
        if (seen.add(key)) out.add(r);
        if (out.length >= max) break;
      }
      return out;
    }

    return InterventionPlan(
      antecedent: pick(InterventionCategory.antecedent),
      teaching: pick(InterventionCategory.teaching),
      consequence: pick(InterventionCategory.consequence),
      reinforcement: pick(InterventionCategory.reinforcement),
    );
  }
}
