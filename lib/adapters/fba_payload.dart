class FbaDatasetDTO {
  final String studentName;
  final String studentId;
  final DateTime from;
  final DateTime to;
  final int totalEvents;
  final int totalDurationSeconds;
  final Map<String, int> bySeverity;
  final Map<String, int> byType;

  FbaDatasetDTO({
    required this.studentName,
    required this.studentId,
    required this.from,
    required this.to,
    required this.totalEvents,
    required this.totalDurationSeconds,
    required this.bySeverity,
    required this.byType,
  });

  Map<String, dynamic> toJson() => {
    'studentName': studentName,
    'studentId': studentId,
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
    'totalEvents': totalEvents,
    'totalDurationSeconds': totalDurationSeconds,
    'bySeverity': bySeverity,
    'byType': byType,
  };
}

class FbaInsightsDTO {
  final String hypothesis;
  final List<Map<String, dynamic>> rankedFunctions;
  final Map<String, num> severityShare;
  final Map<String, int> antecedentCounts;
  final Map<String, int> consequenceCounts;

  FbaInsightsDTO({
    required this.hypothesis,
    required this.rankedFunctions,
    required this.severityShare,
    required this.antecedentCounts,
    required this.consequenceCounts,
  });

  Map<String, dynamic> toJson() => {
    'hypothesis': hypothesis,
    'rankedFunctions': rankedFunctions,
    'severityShare': severityShare,
    'antecedentCounts': antecedentCounts,
    'consequenceCounts': consequenceCounts,
  };
}

class FbaPlanDTO {
  final List<Map<String, String>> antecedent;
  final List<Map<String, String>> teaching;
  final List<Map<String, String>> consequence;
  final List<Map<String, String>> reinforcement;

  FbaPlanDTO({
    required this.antecedent,
    required this.teaching,
    required this.consequence,
    required this.reinforcement,
  });

  Map<String, dynamic> toJson() => {
    'antecedent': antecedent,
    'teaching': teaching,
    'consequence': consequence,
    'reinforcement': reinforcement,
  };
}

Map<String, dynamic> buildFbaEnvelope({
  required Map<String, dynamic> meta,
  required FbaDatasetDTO dataset,
  required FbaInsightsDTO insights,
  required FbaPlanDTO plan,
}) {
  return {
    '_meta': meta,
    'dataset': dataset.toJson(),
    'insights': insights.toJson(),
    'plan': plan.toJson(),
  };
}
