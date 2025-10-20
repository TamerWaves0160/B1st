import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_report_models.dart';

class AIReportService {
  /// Generate AI-powered FBA/BIP reports from observation data
  Future<FBABIPReport> generateReport({
    required String studentId,
    required String studentName,
    required String reportType, // 'FBA' or 'BIP'
    required String ownerUid,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final observationData = await _gatherObservationData(
        studentId: studentId,
        ownerUid: ownerUid,
        startDate: startDate,
        endDate: endDate,
      );

      final context = _prepareRAGContext(observationData);
      final prompt = _buildPrompt(
        reportType: reportType,
        studentName: studentName,
        context: context,
      );

      final aiResponse = await _generateReportContent(prompt, context);
      final report = FBABIPReport(
        id: '',
        studentId: studentId,
        studentName: studentName,
        reportType: reportType,
        generatedDate: DateTime.now(),
        content: aiResponse,
        ownerUid: ownerUid,
        startDate: startDate,
        endDate: endDate,
        observationIds:
            [], // Not tracking individual observation IDs since they're in an array
        fbaAnalysis: null,
        bipStrategies: null,
      );

      await _saveReportToFirestore(report);
      return report;
    } catch (e) {
      throw Exception('Failed to generate $reportType report: $e');
    }
  }

  /// Gather observation data from Firestore
  Future<List<Map<String, dynamic>>> _gatherObservationData({
    required String studentId,
    required String ownerUid,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get the student document
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();

      if (!studentDoc.exists) {
        return [];
      }

      final data = studentDoc.data() as Map<String, dynamic>;
      final behaviorHistory = data['behaviorHistory'] as List<dynamic>? ?? [];

      // Convert to list of maps and filter by date range if provided
      final observations = behaviorHistory.cast<Map<String, dynamic>>().where((
        incident,
      ) {
        if (startDate == null && endDate == null) return true;

        final dateValue = incident['date'];
        DateTime incidentDate;

        if (dateValue is String) {
          incidentDate = DateTime.parse(dateValue);
        } else if (dateValue is Timestamp) {
          incidentDate = dateValue.toDate();
        } else {
          return false;
        }

        if (startDate != null && incidentDate.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && incidentDate.isAfter(endDate)) {
          return false;
        }

        return true;
      }).toList();

      return observations;
    } catch (e) {
      rethrow;
    }
  }

  /// Prepare RAG context from observation data
  Map<String, dynamic> _prepareRAGContext(
    List<Map<String, dynamic>> observations,
  ) {
    if (observations.isEmpty) {
      return {
        'summary': 'No observation data available',
        'behaviorPatterns': [],
        'triggers': [],
        'frequencies': {},
      };
    }

    // Analyze behavior patterns
    final behaviorFrequency = <String, int>{};
    final triggers = <String>[];
    final settingPatterns = <String, int>{};
    final timePatterns = <String, int>{};

    for (final data in observations) {
      // Count behavior types
      final behavior = data['behavior'] as String? ?? 'Unknown';
      behaviorFrequency[behavior] = (behaviorFrequency[behavior] ?? 0) + 1;

      // Collect antecedents/triggers
      final antecedent = data['antecedent'] as String?;
      if (antecedent != null && antecedent.isNotEmpty) {
        triggers.add(antecedent);
      }

      // Analyze setting patterns
      final setting = data['setting'] as String? ?? 'Unknown';
      settingPatterns[setting] = (settingPatterns[setting] ?? 0) + 1;

      // Time-based patterns (if date exists)
      final dateValue = data['date'];
      if (dateValue != null) {
        DateTime incidentDate;
        if (dateValue is String) {
          incidentDate = DateTime.parse(dateValue);
        } else if (dateValue is Timestamp) {
          incidentDate = dateValue.toDate();
        } else {
          continue;
        }

        final hour = incidentDate.hour;
        final timeOfDay = _getTimeOfDay(hour);
        timePatterns[timeOfDay] = (timePatterns[timeOfDay] ?? 0) + 1;
      }
    }

    return {
      'totalObservations': observations.length,
      'dateRange': _getDateRangeFromMaps(observations),
      'behaviorFrequency': behaviorFrequency,
      'commonTriggers': _extractCommonTriggers(triggers),
      'settingPatterns': settingPatterns,
      'timePatterns': timePatterns,
      'rawObservations': observations.map((data) {
        final dateValue = data['date'];
        String? dateString;
        if (dateValue is String) {
          dateString = DateTime.parse(dateValue).toIso8601String();
        } else if (dateValue is Timestamp) {
          dateString = dateValue.toDate().toIso8601String();
        }

        return {
          'date': dateString,
          'behavior': data['behavior'],
          'setting': data['setting'],
          'duration': data['duration'],
          'antecedent': data['antecedent'],
          'consequence': data['consequence'],
        };
      }).toList(),
    };
  }

  /// Build appropriate prompt for FBA or BIP
  String _buildPrompt({
    required String reportType,
    required String studentName,
    required Map<String, dynamic> context,
  }) {
    final basePrompt =
        '''
You are an expert behavioral analyst specializing in educational settings. 
Student: $studentName
Report Type: $reportType

Observation Data Summary:
- Total Observations: ${context['totalObservations']}
- Date Range: ${context['dateRange']}
- Behavior Frequency: ${context['behaviorFrequency']}
- Common Triggers: ${context['commonTriggers']}
- Severity Patterns: ${context['severityPatterns']}
- Time Patterns: ${context['timePatterns']}

Raw Observation Data:
${json.encode(context['rawObservations'])}

''';

    if (reportType == 'FBA') {
      return '''${basePrompt}Generate a comprehensive Functional Behavior Analysis (FBA) report with the following sections:

1. BEHAVIOR IDENTIFICATION
   - Target behavior with operational definition
   - Frequency and duration patterns from data

2. DATA SUMMARY
   - Observation period and frequency
   - Intensity level analysis
   - Environmental context

3. ANTECEDENT ANALYSIS
   - Common triggers identified from data
   - Environmental factors
   - Time-based patterns

4. FUNCTION HYPOTHESIS
   - Primary function (Attention/Escape/Tangible/Sensory)
   - Supporting evidence from observation patterns

5. RECOMMENDATIONS
   - Preventive strategies
   - Data collection recommendations
   - Next steps

Format as a professional clinical report. Base all conclusions on the provided observation data.
''';
    } else {
      return '''${basePrompt}Generate a comprehensive Behavior Intervention Plan (BIP) report with the following sections:

1. BEHAVIOR OVERVIEW
   - Target behavior from analysis
   - Hypothesized function

2. PREVENTION STRATEGIES
   - Environmental modifications based on triggers
   - Instructional strategies
   - Schedule/setting modifications

3. REPLACEMENT BEHAVIORS
   - Functionally equivalent appropriate behaviors
   - Teaching methods and reinforcement plans

4. RESPONSE STRATEGIES
   - For target behavior (consequences)
   - For replacement behavior (reinforcement)
   - De-escalation techniques

5. MONITORING PLAN
   - Data collection methods
   - Review schedule and criteria
   - Success metrics

6. TEAM RESPONSIBILITIES
   - Staff responsibilities
   - Training needs
   - Implementation timeline

Format as a professional intervention plan. Base all strategies on the behavioral patterns identified in the data.
''';
    }
  }

  /// Generate AI report content from prompt and context
  Future<String> _generateReportContent(
    String prompt,
    Map<String, dynamic> context,
  ) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing

    final reportType = prompt.contains('FBA') ? 'FBA' : 'BIP';
    return reportType == 'FBA'
        ? _generateStructuredFBA(context)
        : _generateStructuredBIP(context);
  }

  /// Save report to Firestore
  Future<void> _saveReportToFirestore(FBABIPReport report) async {
    await FirebaseFirestore.instance
        .collection('ai_reports')
        .add(report.toFirestore());
  }

  // Helper methods
  String _getTimeOfDay(int hour) {
    if (hour < 6) return 'Early Morning';
    if (hour < 12) return 'Morning';
    if (hour < 18) return 'Afternoon';
    return 'Evening';
  }

  String _getDateRangeFromMaps(List<Map<String, dynamic>> observations) {
    if (observations.isEmpty) return 'No data';

    final dates = observations
        .map((data) {
          final dateValue = data['date'];
          if (dateValue is String) {
            return DateTime.parse(dateValue);
          } else if (dateValue is Timestamp) {
            return dateValue.toDate();
          }
          return null;
        })
        .where((date) => date != null)
        .cast<DateTime>()
        .toList();

    if (dates.isEmpty) return 'No timestamps';

    dates.sort();
    final start = dates.first;
    final end = dates.last;

    return '${start.month}/${start.day}/${start.year} - ${end.month}/${end.day}/${end.year}';
  }

  List<String> _extractCommonTriggers(List<String> triggers) {
    final frequency = <String, int>{};

    for (final trigger in triggers) {
      final words = trigger.toLowerCase().split(' ');
      for (final word in words) {
        if (word.length > 3) {
          // Skip short words
          frequency[word] = (frequency[word] ?? 0) + 1;
        }
      }
    }

    // Return top 5 most common trigger words
    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => e.key).toList();
  }

  /// Generate structured FBA based on observation data
  String _generateStructuredFBA(Map<String, dynamic> context) {
    final mostCommonBehavior = _getMostFrequentBehavior(context);
    final primaryTriggers =
        context['commonTriggers'] as List<String>? ?? <String>[];
    final settingPattern = _analyzeSettingPattern(context);

    return '''FUNCTIONAL BEHAVIOR ANALYSIS (FBA)

SECTION 1: BEHAVIOR IDENTIFICATION
Target Behavior: $mostCommonBehavior
Operational Definition: Based on ${context['totalObservations']} observations, this behavior is characterized by the patterns observed in the data.

SECTION 2: DATA SUMMARY
Observation Period: ${context['dateRange']}
Total Observations: ${context['totalObservations']}
Frequency Analysis: ${context['behaviorFrequency']}
Setting Patterns: $settingPattern

SECTION 3: ANTECEDENT ANALYSIS
Common Triggers Identified:
${primaryTriggers.map((trigger) => '• $trigger').join('\n')}

Time-based Patterns:
${_formatTimePatterns(context['timePatterns'])}

SECTION 4: FUNCTION HYPOTHESIS
Primary Function: ${_hypothesizeFunction(context)}
Supporting Evidence: Analysis of behavioral patterns, frequency, and environmental factors from observation data.

SECTION 5: RECOMMENDATIONS
• Implement prevention strategies targeting identified triggers
• Continue systematic data collection
• Consider environmental modifications based on time patterns
• Develop replacement behaviors that serve the same function

This FBA was generated using AI analysis of ${context['totalObservations']} behavioral observations. Please review and customize based on additional clinical knowledge.''';
  }

  /// Generate structured BIP based on observation data
  String _generateStructuredBIP(Map<String, dynamic> context) {
    final targetBehavior = _getMostFrequentBehavior(context);
    final triggers = context['commonTriggers'] as List<String>? ?? <String>[];

    return '''BEHAVIOR INTERVENTION PLAN (BIP)

SECTION 1: BEHAVIOR OVERVIEW
Target Behavior: $targetBehavior
Hypothesized Function: ${_hypothesizeFunction(context)}

SECTION 2: PREVENTION STRATEGIES
Environmental Modifications:
${triggers.map((trigger) => '• Address "$trigger" through environmental changes').join('\n')}

Instructional Strategies:
• Implement clear behavioral expectations
• Provide advance notice of transitions
• Use visual supports and schedules

SECTION 3: REPLACEMENT BEHAVIORS
Functionally Equivalent Behaviors:
• Teach appropriate ways to request attention/assistance
• Develop communication strategies
• Practice coping skills for difficult situations

Teaching Methods:
• Direct instruction with modeling
• Role-playing scenarios
• Positive practice opportunities

SECTION 4: RESPONSE STRATEGIES
For Target Behavior:
• Redirect to appropriate behavior
• Implement planned ignoring when safe
• Use natural consequences

For Replacement Behavior:
• Immediate positive reinforcement
• Social recognition
• Preferred activity access

SECTION 5: MONITORING PLAN
Data Collection: Continue current observation protocols
Review Schedule: Weekly team meetings for first month, then bi-weekly
Success Criteria: 50% reduction in target behavior frequency within 4 weeks

SECTION 6: TEAM RESPONSIBILITIES
• Teacher: Primary implementation of strategies
• Support Staff: Consistent response procedures
• Family: Home reinforcement of replacement behaviors

This BIP was generated using AI analysis of behavioral data. Please customize based on individual student needs and team expertise.''';
  }

  String _getMostFrequentBehavior(Map<String, dynamic> context) {
    final frequency = context['behaviorFrequency'] as Map<String, dynamic>?;
    if (frequency == null || frequency.isEmpty) return 'Unspecified behavior';

    String mostFrequent = frequency.keys.first;
    int maxCount = frequency[mostFrequent] ?? 0;

    frequency.forEach((behavior, count) {
      if ((count as int) > maxCount) {
        mostFrequent = behavior;
        maxCount = count;
      }
    });

    return mostFrequent;
  }

  String _analyzeSettingPattern(Map<String, dynamic> context) {
    final patterns = context['settingPatterns'] as Map<String, dynamic>?;
    if (patterns == null || patterns.isEmpty) {
      return 'No setting data available';
    }

    final total = patterns.values.fold(0, (sum, count) => sum + (count as int));
    final percentages = patterns.map(
      (setting, count) =>
          MapEntry(setting, ((count as int) / total * 100).round()),
    );

    return percentages.entries
        .map((entry) => '${entry.key}: ${entry.value}%')
        .join(', ');
  }

  String _formatTimePatterns(Map<String, dynamic>? timePatterns) {
    if (timePatterns == null || timePatterns.isEmpty) {
      return '• No time-based patterns identified';
    }

    return timePatterns.entries
        .map((entry) => '• ${entry.key}: ${entry.value} occurrences')
        .join('\n');
  }

  String _hypothesizeFunction(Map<String, dynamic> context) {
    final triggers = context['commonTriggers'] as List<String>?;
    if (triggers == null || triggers.isEmpty) {
      return 'Sensory/Self-regulation';
    }

    // Simple heuristic based on common patterns
    final triggerText = triggers.join(' ').toLowerCase();

    if (triggerText.contains('attention') || triggerText.contains('help')) {
      return 'Attention-seeking';
    } else if (triggerText.contains('work') || triggerText.contains('task')) {
      return 'Escape/Avoidance';
    } else if (triggerText.contains('item') || triggerText.contains('want')) {
      return 'Tangible/Access';
    } else {
      return 'Sensory/Self-regulation';
    }
  }
}
