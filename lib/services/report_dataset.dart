// lib/services/report_dataset.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// One row in the event log used for reports/PDFs.
class BehaviorEventRow {
  final DateTime createdAt;
  final String behaviorType;
  final String severity;         // 'Mild' | 'Moderate' | 'Severe'
  final int? durationSeconds;
  final String? antecedent;
  final String? consequence;
  final String? location;

  BehaviorEventRow({
    required this.createdAt,
    required this.behaviorType,
    required this.severity,
    required this.durationSeconds,
    required this.antecedent,
    required this.consequence,
    required this.location,
  });

  factory BehaviorEventRow.fromMap(Map<String, dynamic> m) {
    // createdAt can be Timestamp or null
    final ts = m['createdAt'];
    final dt = ts is Timestamp
        ? ts.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);

    // severity may be missing if older events wrote only intensity
    String sev = (m['severity'] as String?) ?? '';
    if (sev.isEmpty) {
      final intensity = (m['intensity'] as num?)?.toInt();
      if (intensity != null) {
        if (intensity <= 1) {
          sev = 'Mild';
        } else if (intensity >= 5) {
          sev = 'Severe';
        } else {
          sev = 'Moderate';
        }
      } else {
        sev = 'Moderate';
      }
    }

    return BehaviorEventRow(
      createdAt: dt,
      behaviorType: (m['behaviorType'] as String?) ?? '',
      severity: sev,
      durationSeconds: (m['durationSeconds'] as num?)?.toInt(),
      antecedent: m['antecedent'] as String?,
      consequence: m['consequence'] as String?,
      location: m['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'createdAt': createdAt.toIso8601String(),
    'behaviorType': behaviorType,
    'severity': severity,
    'durationSeconds': durationSeconds,
    'antecedent': antecedent,
    'consequence': consequence,
    'location': location,
  };
}

/// Aggregated dataset for a time window (default last 14 days).
class ReportDataset {
  final String studentId;
  final String studentName;
  final DateTime from;
  final DateTime to;

  final int totalEvents;
  final int totalDurationSeconds;
  final Map<String, int> bySeverity; // e.g., {'Mild': 10, 'Moderate': 3, 'Severe': 1}
  final Map<String, int> byType;     // e.g., {'Disruption': 4, 'Elopement': 2}
  final List<BehaviorEventRow> rows;

  ReportDataset({
    required this.studentId,
    required this.studentName,
    required this.from,
    required this.to,
    required this.totalEvents,
    required this.totalDurationSeconds,
    required this.bySeverity,
    required this.byType,
    required this.rows,
  });

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
    'totalEvents': totalEvents,
    'totalDurationSeconds': totalDurationSeconds,
    'bySeverity': bySeverity,
    'byType': byType,
    // rows are optional for the AI function, but useful if you want full detail
    'rows': rows.map((r) => r.toJson()).toList(),
  };
}

/// Service that fetches/aggregates events from Firestore into a ReportDataset.
class ReportDataService {
  final FirebaseFirestore _db;
  ReportDataService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  /// Fetch a dataset for [studentId] belonging to [ownerUid] between [from] and [to].
  /// Defaults to the last 14 days ending "now" if the window is not provided.
  Future<ReportDataset> fetch({
    required String ownerUid,
    required String studentId,
    DateTime? from,
    DateTime? to,
  }) async {
    final DateTime end = to ?? DateTime.now();
    final DateTime start = from ?? end.subtract(const Duration(days: 14));

    // Try to get the student name from the students doc; fall back to events if needed.
    String studentName = '';
    try {
      final s = await _db.collection('students').doc(studentId).get();
      final data = s.data();
      if (data != null) {
        studentName = (data['name'] as String?) ?? '';
      }
    } catch (_) {
      // ignore and derive from events below if possible
    }

    // Query events: owner, student, window on createdAt, ordered by createdAt asc.
    // NOTE: Firestore may prompt you to create a composite index:
    //   (uid asc, studentId asc, createdAt asc)
    final snap = await _db
        .collection('behavior_events')
        .where('uid', isEqualTo: ownerUid)
        .where('studentId', isEqualTo: studentId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: false)
        .get();

    final docs = snap.docs;
    final rows = <BehaviorEventRow>[];
    final bySeverity = <String, int>{'Mild': 0, 'Moderate': 0, 'Severe': 0};
    final byType = <String, int>{};
    int totalDuration = 0;

    for (final d in docs) {
      final data = d.data();
      // Derive studentName from the first row if missing
      if (studentName.isEmpty) {
        final candidate = (data['studentName'] as String?) ?? '';
        if (candidate.isNotEmpty) studentName = candidate;
      }

      final row = BehaviorEventRow.fromMap(data);
      rows.add(row);

      // Tally severity / type / duration
      bySeverity[row.severity] = (bySeverity[row.severity] ?? 0) + 1;
      final t = row.behaviorType.isEmpty ? '(Unspecified)' : row.behaviorType;
      byType[t] = (byType[t] ?? 0) + 1;
      totalDuration += row.durationSeconds ?? 0;
    }

    return ReportDataset(
      studentId: studentId,
      studentName: studentName,
      from: start,
      to: end,
      totalEvents: rows.length,
      totalDurationSeconds: totalDuration,
      bySeverity: bySeverity,
      byType: byType,
      rows: rows,
    );
  }
}
