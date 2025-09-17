import 'package:cloud_firestore/cloud_firestore.dart';

class FBABIPReport {
  final String id;
  final String studentId;
  final String studentName;
  final String reportType; // 'FBA' or 'BIP'
  final DateTime generatedDate;
  final String content;
  final String ownerUid;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> observationIds;
  final FBAAnalysis? fbaAnalysis;
  final BIPStrategies? bipStrategies;

  const FBABIPReport({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.reportType,
    required this.generatedDate,
    required this.content,
    required this.ownerUid,
    this.startDate,
    this.endDate,
    this.observationIds = const [],
    this.fbaAnalysis,
    this.bipStrategies,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'reportType': reportType,
      'generatedDate': generatedDate,
      'content': content,
      'ownerUid': ownerUid,
      'startDate': startDate,
      'endDate': endDate,
      'observationIds': observationIds,
      'fbaAnalysis': fbaAnalysis?.toMap(),
      'bipStrategies': bipStrategies?.toMap(),
    };
  }

  factory FBABIPReport.fromFirestore(String id, Map<String, dynamic> data) {
    return FBABIPReport(
      id: id,
      studentId: data['studentId'] as String,
      studentName: data['studentName'] as String,
      reportType: data['reportType'] as String,
      generatedDate: (data['generatedDate'] as Timestamp).toDate(),
      content: data['content'] as String,
      ownerUid: data['ownerUid'] as String,
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      observationIds: List<String>.from(data['observationIds'] ?? []),
      fbaAnalysis: data['fbaAnalysis'] != null
          ? FBAAnalysis.fromMap(data['fbaAnalysis'])
          : null,
      bipStrategies: data['bipStrategies'] != null
          ? BIPStrategies.fromMap(data['bipStrategies'])
          : null,
    );
  }
}

class FBAAnalysis {
  final String targetBehavior;
  final String operationalDefinition;
  final List<String> commonTriggers;
  final String primaryFunction; // Attention, Escape, Tangible, Sensory
  final Map<String, int> behaviorFrequency;
  final Map<String, double> intensityPatterns;
  final List<String> environmentalFactors;
  final String supportingEvidence;

  const FBAAnalysis({
    required this.targetBehavior,
    required this.operationalDefinition,
    required this.commonTriggers,
    required this.primaryFunction,
    required this.behaviorFrequency,
    required this.intensityPatterns,
    required this.environmentalFactors,
    required this.supportingEvidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'targetBehavior': targetBehavior,
      'operationalDefinition': operationalDefinition,
      'commonTriggers': commonTriggers,
      'primaryFunction': primaryFunction,
      'behaviorFrequency': behaviorFrequency,
      'intensityPatterns': intensityPatterns,
      'environmentalFactors': environmentalFactors,
      'supportingEvidence': supportingEvidence,
    };
  }

  factory FBAAnalysis.fromMap(Map<String, dynamic> map) {
    return FBAAnalysis(
      targetBehavior: map['targetBehavior'] as String,
      operationalDefinition: map['operationalDefinition'] as String,
      commonTriggers: List<String>.from(map['commonTriggers']),
      primaryFunction: map['primaryFunction'] as String,
      behaviorFrequency: Map<String, int>.from(map['behaviorFrequency']),
      intensityPatterns: Map<String, double>.from(map['intensityPatterns']),
      environmentalFactors: List<String>.from(map['environmentalFactors']),
      supportingEvidence: map['supportingEvidence'] as String,
    );
  }
}

class BIPStrategies {
  final List<PreventionStrategy> preventionStrategies;
  final List<ReplacementBehavior> replacementBehaviors;
  final List<ResponseStrategy> responseStrategies;
  final MonitoringPlan monitoringPlan;
  final List<TeamResponsibility> teamResponsibilities;
  final String? crisisPlan;

  const BIPStrategies({
    required this.preventionStrategies,
    required this.replacementBehaviors,
    required this.responseStrategies,
    required this.monitoringPlan,
    required this.teamResponsibilities,
    this.crisisPlan,
  });

  Map<String, dynamic> toMap() {
    return {
      'preventionStrategies': preventionStrategies
          .map((e) => e.toMap())
          .toList(),
      'replacementBehaviors': replacementBehaviors
          .map((e) => e.toMap())
          .toList(),
      'responseStrategies': responseStrategies.map((e) => e.toMap()).toList(),
      'monitoringPlan': monitoringPlan.toMap(),
      'teamResponsibilities': teamResponsibilities
          .map((e) => e.toMap())
          .toList(),
      'crisisPlan': crisisPlan,
    };
  }

  factory BIPStrategies.fromMap(Map<String, dynamic> map) {
    return BIPStrategies(
      preventionStrategies: List<PreventionStrategy>.from(
        map['preventionStrategies']?.map(
              (x) => PreventionStrategy.fromMap(x),
            ) ??
            [],
      ),
      replacementBehaviors: List<ReplacementBehavior>.from(
        map['replacementBehaviors']?.map(
              (x) => ReplacementBehavior.fromMap(x),
            ) ??
            [],
      ),
      responseStrategies: List<ResponseStrategy>.from(
        map['responseStrategies']?.map((x) => ResponseStrategy.fromMap(x)) ??
            [],
      ),
      monitoringPlan: MonitoringPlan.fromMap(map['monitoringPlan']),
      teamResponsibilities: List<TeamResponsibility>.from(
        map['teamResponsibilities']?.map(
              (x) => TeamResponsibility.fromMap(x),
            ) ??
            [],
      ),
      crisisPlan: map['crisisPlan'],
    );
  }
}

class PreventionStrategy {
  final String category; // Environmental, Instructional, Setting
  final String description;
  final String implementation;
  final int priority; // 1-5

  const PreventionStrategy({
    required this.category,
    required this.description,
    required this.implementation,
    required this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'description': description,
      'implementation': implementation,
      'priority': priority,
    };
  }

  factory PreventionStrategy.fromMap(Map<String, dynamic> map) {
    return PreventionStrategy(
      category: map['category'] as String,
      description: map['description'] as String,
      implementation: map['implementation'] as String,
      priority: map['priority'] as int,
    );
  }
}

class ReplacementBehavior {
  final String behavior;
  final String function;
  final String teachingMethod;
  final String reinforcement;

  const ReplacementBehavior({
    required this.behavior,
    required this.function,
    required this.teachingMethod,
    required this.reinforcement,
  });

  Map<String, dynamic> toMap() {
    return {
      'behavior': behavior,
      'function': function,
      'teachingMethod': teachingMethod,
      'reinforcement': reinforcement,
    };
  }

  factory ReplacementBehavior.fromMap(Map<String, dynamic> map) {
    return ReplacementBehavior(
      behavior: map['behavior'] as String,
      function: map['function'] as String,
      teachingMethod: map['teachingMethod'] as String,
      reinforcement: map['reinforcement'] as String,
    );
  }
}

class ResponseStrategy {
  final String trigger; // For target behavior or replacement behavior
  final String response;
  final String type; // Consequence, Redirection, De-escalation
  final String rationale;

  const ResponseStrategy({
    required this.trigger,
    required this.response,
    required this.type,
    required this.rationale,
  });

  Map<String, dynamic> toMap() {
    return {
      'trigger': trigger,
      'response': response,
      'type': type,
      'rationale': rationale,
    };
  }

  factory ResponseStrategy.fromMap(Map<String, dynamic> map) {
    return ResponseStrategy(
      trigger: map['trigger'] as String,
      response: map['response'] as String,
      type: map['type'] as String,
      rationale: map['rationale'] as String,
    );
  }
}

class MonitoringPlan {
  final String dataCollection;
  final String reviewSchedule;
  final List<String> successCriteria;
  final String reviewProcess;

  const MonitoringPlan({
    required this.dataCollection,
    required this.reviewSchedule,
    required this.successCriteria,
    required this.reviewProcess,
  });

  Map<String, dynamic> toMap() {
    return {
      'dataCollection': dataCollection,
      'reviewSchedule': reviewSchedule,
      'successCriteria': successCriteria,
      'reviewProcess': reviewProcess,
    };
  }

  factory MonitoringPlan.fromMap(Map<String, dynamic> map) {
    return MonitoringPlan(
      dataCollection: map['dataCollection'] as String,
      reviewSchedule: map['reviewSchedule'] as String,
      successCriteria: List<String>.from(map['successCriteria']),
      reviewProcess: map['reviewProcess'] as String,
    );
  }
}

class TeamResponsibility {
  final String role; // Teacher, Support Staff, Family, etc.
  final List<String> responsibilities;
  final String contactInfo;

  const TeamResponsibility({
    required this.role,
    required this.responsibilities,
    required this.contactInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'responsibilities': responsibilities,
      'contactInfo': contactInfo,
    };
  }

  factory TeamResponsibility.fromMap(Map<String, dynamic> map) {
    return TeamResponsibility(
      role: map['role'] as String,
      responsibilities: List<String>.from(map['responsibilities']),
      contactInfo: map['contactInfo'] as String,
    );
  }
}
