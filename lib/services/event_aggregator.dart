// lib/services/event_aggregator.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AggregatedStats {
  final String uid;
  final String studentId;
  final String studentName;
  final DateTime from;
  final DateTime to;

  final int totalEvents;
  final int totalDurationSeconds;
  final Map<String, int> byType;
  final Map<String, int> bySeverity;
  final Map<String, int> antecedentCounts;
  final Map<String, int> consequenceCounts;

  AggregatedStats({
    required this.uid,
    required this.studentId,
    required this.studentName,
    required this.from,
    required this.to,
    required this.totalEvents,
    required this.totalDurationSeconds,
    required this.byType,
    required this.bySeverity,
    required this.antecedentCounts,
    required this.consequenceCounts,
  });
}

class EventAggregator {
  /// Pulls recent events from Firestore and aggregates them for ONE student.
  /// If [studentId] is null, auto-selects the student with the most events in range.
  static Future<AggregatedStats> fetchAndAggregate({
    String? studentId,
    String? studentName,
    Duration window = const Duration(days: 7),
    int maxDocs = 2000, // dev-friendly limit to avoid huge reads
  }) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in; cannot aggregate events.');
    }
    final uid = user.uid;

    final now = DateTime.now();
    final from = now.subtract(window);

    final fs = FirebaseFirestore.instance;
    final col = fs.collection('behavior_events');

    // Base query by uid + createdAt window; you have indexes for these.
    final baseQuery = col
        .where('uid', isEqualTo: uid)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('createdAt', descending: true)
        .limit(maxDocs);

    // First pass: fetch events in window (all students for this uid)
    final snap = await baseQuery.get();
    final docs = snap.docs;

    if (docs.isEmpty) {
      // No data → return empty placeholder
      return AggregatedStats(
        uid: uid,
        studentId: studentId ?? 'unknown-student',
        studentName: studentName ?? 'Unknown Student',
        from: from,
        to: now,
        totalEvents: 0,
        totalDurationSeconds: 0,
        byType: const {},
        bySeverity: const {},
        antecedentCounts: const {},
        consequenceCounts: const {},
      );
    }

    // If no studentId provided, pick the studentId with most events
    String chosenStudentId = studentId ?? _pickTopStudentId(docs);
    String chosenStudentName =
        studentName ?? _pickAnyStudentNameFor(chosenStudentId, docs) ?? 'Unknown Student';

    // Second pass: filter to that student's events (in-memory)
    final events = docs.where((d) => (d.data()['studentId'] ?? '') == chosenStudentId).toList();

    // Aggregate
    int totalEvents = 0;
    int totalDurationSeconds = 0;
    final byType = <String, int>{};
    final bySeverity = <String, int>{};
    final antecedentCounts = <String, int>{};
    final consequenceCounts = <String, int>{};

    for (final d in events) {
      final data = d.data();

      totalEvents += 1;

      // durationSeconds may be int/num/string; coerce carefully
      final dsRaw = data['durationSeconds'];
      final ds = _asInt(dsRaw);
      totalDurationSeconds += ds;

      final type = (data['behaviorType'] ?? '').toString().trim();
      if (type.isNotEmpty) {
        byType[type] = (byType[type] ?? 0) + 1;
      }

      final sev = (data['severity'] ?? '').toString().trim();
      if (sev.isNotEmpty) {
        bySeverity[sev] = (bySeverity[sev] ?? 0) + 1;
      }

      final ant = (data['antecedent'] ?? '').toString().trim();
      if (ant.isNotEmpty) {
        antecedentCounts[ant] = (antecedentCounts[ant] ?? 0) + 1;
      }

      final cons = (data['consequence'] ?? '').toString().trim();
      if (cons.isNotEmpty) {
        consequenceCounts[cons] = (consequenceCounts[cons] ?? 0) + 1;
      }
    }

    return AggregatedStats(
      uid: uid,
      studentId: chosenStudentId,
      studentName: chosenStudentName,
      from: from,
      to: now,
      totalEvents: totalEvents,
      totalDurationSeconds: totalDurationSeconds,
      byType: byType,
      bySeverity: bySeverity,
      antecedentCounts: antecedentCounts,
      consequenceCounts: consequenceCounts,
    );
  }

  static String _pickTopStudentId(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final counts = <String, int>{};
    for (final d in docs) {
      final sid = (d.data()['studentId'] ?? '').toString();
      if (sid.isEmpty) continue;
      counts[sid] = (counts[sid] ?? 0) + 1;
    }
    // pick the studentId with max count; if tie, any
    String? top;
    int best = -1;
    counts.forEach((sid, c) {
      if (c > best) {
        best = c;
        top = sid;
      }
    });
    return top ?? 'unknown-student';
  }

  static String? _pickAnyStudentNameFor(
      String studentId,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    for (final d in docs) {
      final data = d.data();
      if ((data['studentId'] ?? '') == studentId) {
        final nm = data['studentName'];
        if (nm is String && nm.trim().isNotEmpty) return nm.trim();
      }
    }
    return null;
  }

  static int _asInt(dynamic x) {
    if (x is int) return x;
    if (x is num) return x.toInt();
    if (x is String) return int.tryParse(x) ?? 0;
    return 0;
  }
}
