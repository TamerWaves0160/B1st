// lib/models/fba_bip_draft.dart
class DraftResponse {
  final Map<String, dynamic> meta; // e.g., {serverReceivedAt: "..."}
  final FbaBipDraft draft;

  DraftResponse({required this.meta, required this.draft});

  factory DraftResponse.fromMap(Map<String, dynamic> m) {
    final meta = _asMap(m['meta']);
    final draft = FbaBipDraft.fromMap(_asMap(m['draft']));
    return DraftResponse(meta: meta, draft: draft);
  }

  factory DraftResponse.fromJson(Map<String, dynamic> json) =>
      DraftResponse.fromMap(json);
}

class FbaBipDraft {
  final Student student;
  final Summary summary;
  final Insights insights;
  final Recommendations recommendations;
  final Narrative narrative;
  final DraftMeta meta;

  FbaBipDraft({
    required this.student,
    required this.summary,
    required this.insights,
    required this.recommendations,
    required this.narrative,
    required this.meta,
  });

  factory FbaBipDraft.fromMap(Map<String, dynamic> m) {
    return FbaBipDraft(
      student: Student.fromMap(_asMap(m['student'])),
      summary: Summary.fromMap(_asMap(m['summary'])),
      insights: Insights.fromMap(_asMap(m['insights'])),
      recommendations: Recommendations.fromMap(_asMap(m['recommendations'])),
      narrative: Narrative.fromMap(_asMap(m['narrative'])),
      meta: DraftMeta.fromMap(_asMap(m['meta'])),
    );
  }
}

class Student {
  final String id;
  final String name;
  final Window window;

  Student({required this.id, required this.name, required this.window});

  factory Student.fromMap(Map<String, dynamic> m) {
    return Student(
      id: _asString(m['id']),
      name: _asString(m['name']),
      window: Window.fromMap(_asMap(m['window'])),
    );
  }
}

class Window {
  final String from; // ISO
  final String to;   // ISO
  Window({required this.from, required this.to});

  factory Window.fromMap(Map<String, dynamic> m) {
    return Window(from: _asString(m['from']), to: _asString(m['to']));
  }
}

class Summary {
  final int totalEvents;
  final int totalDurationSeconds;
  final Map<String, num> bySeverity;
  final List<TypeCount> byTypeTop;

  Summary({
    required this.totalEvents,
    required this.totalDurationSeconds,
    required this.bySeverity,
    required this.byTypeTop,
  });

  factory Summary.fromMap(Map<String, dynamic> m) {
    final list = (m['byTypeTop'] as List? ?? const [])
        .map((e) => TypeCount.fromMap(_asMap(e)))
        .toList();
    return Summary(
      totalEvents: _asInt(m['totalEvents']),
      totalDurationSeconds: _asInt(m['totalDurationSeconds']),
      bySeverity: _asStringNumMap(m['bySeverity']),
      byTypeTop: list,
    );
  }
}

class TypeCount {
  final String type;
  final num count;
  TypeCount({required this.type, required this.count});

  factory TypeCount.fromMap(Map<String, dynamic> m) {
    return TypeCount(type: _asString(m['type']), count: _asNum(m['count']));
  }
}

class Insights {
  final String hypothesis;
  final List<InsightFn> topFunctions;
  final Map<String, num> severityShare;
  final Map<String, num> antecedents;
  final Map<String, num> consequences;

  Insights({
    required this.hypothesis,
    required this.topFunctions,
    required this.severityShare,
    required this.antecedents,
    required this.consequences,
  });

  factory Insights.fromMap(Map<String, dynamic> m) {
    final fns = (m['topFunctions'] as List? ?? const [])
        .map((e) => InsightFn.fromMap(_asMap(e)))
        .toList();
    return Insights(
      hypothesis: _asString(m['hypothesis']),
      topFunctions: fns,
      severityShare: _asStringNumMap(m['severityShare']),
      antecedents: _asStringNumMap(m['anteents'] ?? m['antecedents']), // tolerate typo
      consequences: _asStringNumMap(m['consequences']),
    );
  }
}

class InsightFn {
  final String name;
  final num share;
  InsightFn({required this.name, required this.share});

  factory InsightFn.fromMap(Map<String, dynamic> m) {
    return InsightFn(name: _asString(m['name']), share: _asNum(m['share']));
  }
}

class Recommendations {
  final List<Rec> antecedent;
  final List<Rec> teaching;
  final List<Rec> consequence;
  final List<Rec> reinforcement;

  Recommendations({
    required this.antecedent,
    required this.teaching,
    required this.consequence,
    required this.reinforcement,
  });

  factory Recommendations.fromMap(Map<String, dynamic> m) {
    List<Rec> list(dynamic x) =>
        (x as List? ?? const []).map((e) => Rec.fromMap(_asMap(e))).toList();

    return Recommendations(
      antecedent: list(m['antecedent']),
      teaching: list(m['teaching']),
      consequence: list(m['consequence']),
      reinforcement: list(m['reinforcement']),
    );
  }
}

class Rec {
  final String title;
  final String rationale;
  Rec({required this.title, required this.rationale});

  factory Rec.fromMap(Map<String, dynamic> m) {
    return Rec(title: _asString(m['title']), rationale: _asString(m['rationale']));
  }
}

class Narrative {
  final String fbaSummary;
  final String bipPlan;
  final String interventionRationales;
  final String disclaimer;

  Narrative({
    required this.fbaSummary,
    required this.bipPlan,
    required this.interventionRationales,
    required this.disclaimer,
  });

  factory Narrative.fromMap(Map<String, dynamic> m) {
    return Narrative(
      fbaSummary: _asString(m['fbaSummary']),
      bipPlan: _asString(m['bipPlan']),
      interventionRationales: _asString(m['interventionRationales']),
      disclaimer: _asString(m['disclaimer']),
    );
  }
}

class DraftMeta {
  final String generatedAt;
  final String engine;
  DraftMeta({required this.generatedAt, required this.engine});

  factory DraftMeta.fromMap(Map<String, dynamic> m) {
    return DraftMeta(
      generatedAt: _asString(m['generatedAt']),
      engine: _asString(m['engine']),
    );
  }
}

// ---------- helpers (defensive parsing) ----------
Map<String, dynamic> _asMap(dynamic x) =>
    (x is Map) ? x.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};

String _asString(dynamic x) => x == null ? '' : x.toString();

int _asInt(dynamic x) {
  if (x is int) return x;
  if (x is num) return x.toInt();
  if (x is String) return int.tryParse(x) ?? 0;
  return 0;
}

num _asNum(dynamic x) {
  if (x is num) return x;
  if (x is String) return num.tryParse(x) ?? 0;
  return 0;
}

Map<String, num> _asStringNumMap(dynamic x) {
  final m = _asMap(x);
  final out = <String, num>{};
  for (final entry in m.entries) {
    out[entry.key] = _asNum(entry.value);
  }
  return out;
}
