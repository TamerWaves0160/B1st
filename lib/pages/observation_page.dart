// =============================================================
// BehaviorFirst — lib/pages/observation_page.dart (Annotated, v4)
// -------------------------------------------------------------
// Requested changes implemented:
//  • Tab spacing fix handled in home_shell.dart (see chat snippet)
//  • Behavior Type is now a DROPDOWN (not chips)
//  • Context (Antecedent & Consequence) is REQUIRED and appears BEFORE intensity
//  • Intensity now uses three levels: Mild / Moderate / Severe
//      - Stored as `severity` (string)
//      - Also writes numeric `intensity` (1,3,5) for compatibility with rules
//  • After any successful record, the form clears BUT keeps the same student
//  • Recent Events list shows Severity
// =============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ObservationPage extends StatefulWidget {
  const ObservationPage({super.key});

  @override
  State<ObservationPage> createState() => _ObservationPageState();
}

class _ObservationPageState extends State<ObservationPage> {
  // ---------- STATE ----------
  String? _selectedStudentId;
  String? _selectedStudentName;

  final List<String> _behaviorTypes = const [
    'Noncompliance',
    'Disruption',
    'Aggression',
    'Elopement',
    'Off-task',
    'Other'
  ];
  String? _selectedBehaviorType;

  // Severity (replaces old free slider)
  final List<String> _severityLevels = const ['Mild', 'Moderate', 'Severe'];
  String _severity = 'Mild';

  final List<String> _antecedents = const [
    'Demand placed',
    'Transition',
    'Attention diverted',
    'Unstructured time',
    'Denied access',
    'Other'
  ];
  final List<String> _consequences = const [
    'Redirection',
    'Removal of item',
    'Planned ignoring',
    'Break given',
    'Call home',
    'Other'
  ];
  String? _antecedent; // REQUIRED
  String? _consequence; // REQUIRED

  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  Timer? _timer;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;

  bool get _isTiming => _timer != null;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  int _intensityFromSeverity(String s) {
    switch (s) {
      case 'Mild':
        return 1;
      case 'Severe':
        return 5;
      default:
        return 3; // Moderate
    }
  }

  String get _elapsedLabel {
    final total = _elapsed.inSeconds;
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  // ---------- STUDENTS ----------
  Stream<QuerySnapshot<Map<String, dynamic>>> _studentsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('students')
        .where('ownerUid', isEqualTo: uid)
        .orderBy('name')
        .snapshots();
  }

  Future<void> _showAddStudentDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    if (user == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Sign in to add students.')));
      return;
    }

    final nameCtrl = TextEditingController();
    final enteredName = await showDialog<String>(
      context: context,
      builder: (dialogCtx) =>
          AlertDialog(
            title: const Text('Add Student'),
            content: TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Student name',
                hintText: 'e.g., Alex R.',
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogCtx).pop(nameCtrl.text.trim()),
                child: const Text('Add'),
              ),
            ],
          ),
    );

    if (enteredName == null || enteredName.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('students').add({
        'ownerUid': user.uid,
        'name': enteredName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _selectedStudentId = doc.id;
        _selectedStudentName = enteredName;
      });
      messenger.showSnackBar(
          SnackBar(content: Text('Student added: $enteredName')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Failed to add student: $e')));
    }
  }

  // ---------- VALIDATION + WRITE ----------
  bool _validateCore() {
    if (_selectedStudentId == null ||
        (_selectedStudentName == null || _selectedStudentName!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select or add a student.')),
      );
      return false;
    }
    if (_selectedBehaviorType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a behavior type.')),
      );
      return false;
    }
    if (_antecedent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Antecedent is required.')),
      );
      return false;
    }
    if (_consequence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consequence is required.')),
      );
      return false;
    }
    return true;
  }

  Future<bool> _writeEvent({DateTime? startedAt, DateTime? endedAt}) async {
    final user = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);

    if (user == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('You must be signed in.')));
      return false;
    }

    int? duration;
    if (startedAt != null && endedAt != null) {
      duration = endedAt
          .difference(startedAt)
          .inSeconds;
    }

    final data = <String, dynamic>{
      'uid': user.uid,
      'studentId': _selectedStudentId,
      'studentName': _selectedStudentName,
      'behaviorType': _selectedBehaviorType,
      'severity': _severity,
      // new string field
      'intensity': _intensityFromSeverity(_severity),
      // keep numeric for rules/analytics
      'antecedent': _antecedent?.trim(),
      'consequence': _consequence?.trim(),
      'location': _locationCtrl.text
          .trim()
          .isEmpty ? null : _locationCtrl.text.trim(),
      'notes': _notesCtrl.text
          .trim()
          .isEmpty ? null : _notesCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt),
      if (endedAt != null) 'endedAt': Timestamp.fromDate(endedAt),
      if (duration != null) 'durationSeconds': duration,
    };

    try {
      await FirebaseFirestore.instance.collection('behavior_events').add(data);
      messenger.showSnackBar(const SnackBar(content: Text('Event recorded.')));
      return true;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to record: $e')));
      return false;
    }
  }

  void _resetFormKeepStudent() {
    setState(() {
      // keep student id/name
      _selectedBehaviorType = null;
      _severity = 'Mild';
      _antecedent = null;
      _consequence = null;
      _locationCtrl.clear();
      _notesCtrl.clear();
      _elapsed = Duration.zero;
      _startedAt = null;
      _timer?.cancel();
      _timer = null;
    });
  }

  Future<void> _quickLog() async {
    if (!_validateCore()) return;
    final ok = await _writeEvent();
    if (ok) _resetFormKeepStudent();
  }

  void _toggleTimer() async {
    if (_isTiming) {
      _timer?.cancel();
      _timer = null;
      final ended = DateTime.now();
      final started = _startedAt!;
      setState(() => _startedAt = null);

      if (!_validateCore()) return;
      final ok = await _writeEvent(startedAt: started, endedAt: ended);
      if (ok && mounted) _resetFormKeepStudent();
    } else {
      setState(() {
        _startedAt = DateTime.now();
        _elapsed = Duration.zero;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _startedAt == null) return;
        setState(() {
          _elapsed = DateTime.now().difference(_startedAt!);
        });
      });
    }
  }

  // ---------- UI HELPERS ----------
  String _formatWhen(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Begin Observation')),
      body: user == null
          ? const Center(child: Text('Please sign in to record observations.'))
          : SafeArea(
        child: CustomScrollView(
          // one primary scroll surface for the entire page
          primary: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // Use a SliverPadding so our bottom space grows when keyboard shows
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 +
                    MediaQuery
                        .of(context)
                        .viewPadding
                        .bottom +
                    MediaQuery
                        .of(context)
                        .viewInsets
                        .bottom,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  // === paste your Cards here in the SAME order as before ===

                  // ---------- STUDENT PICKER ----------
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Student', style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                              OutlinedButton.icon(
                                onPressed: _showAddStudentDialog,
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text('Add Student'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _studentsStream(user.uid),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const LinearProgressIndicator(
                                    minHeight: 2);
                              }
                              if (snap.hasError) {
                                // Force-wrap the error text so a long URL can't break layout
                                return SelectableText(
                                  'Error loading students: ${snap.error}',
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .bodyMedium,
                                );
                              }
                              final docs = snap.data?.docs ?? const [];
                              if (docs.isEmpty) {
                                return const Text(
                                    'No students yet. Add one to start logging.');
                              }

                              final validIds = docs.map((d) => d.id).toSet();
                              final current = validIds.contains(
                                  _selectedStudentId)
                                  ? _selectedStudentId
                                  : null;

                              final entries = docs.map((d) {
                                final name = d.data()['name'] as String? ??
                                    '(Unnamed)';
                                return DropdownMenuEntry<String>(
                                    value: d.id, label: name);
                              }).toList();

                              return DropdownMenu<String>(
                                initialSelection: current,
                                dropdownMenuEntries: entries,
                                leadingIcon: const Icon(Icons.person_outline),
                                hintText: 'Select a student',
                                onSelected: (id) {
                                  if (id == null) return;
                                  setState(() {
                                    _selectedStudentId = id;
                                    final d = docs.firstWhere((e) =>
                                    e.id == id);
                                    _selectedStudentName =
                                        (d.data()['name'] as String?) ?? '';
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ---------- BEHAVIOR TYPE (Dropdown) ----------
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Behavior Type',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownMenu<String>(
                            initialSelection: _selectedBehaviorType,
                            dropdownMenuEntries: _behaviorTypes
                                .map((t) =>
                                DropdownMenuEntry<String>(value: t, label: t))
                                .toList(),
                            leadingIcon: const Icon(Icons.category_outlined),
                            hintText: 'Select behavior type',
                            onSelected: (v) =>
                                setState(() => _selectedBehaviorType = v),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ---------- CONTEXT (REQUIRED) ----------
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Context (Required)',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownMenu<String>(
                            initialSelection: _antecedent,
                            dropdownMenuEntries: _antecedents
                                .map((a) =>
                                DropdownMenuEntry<String>(value: a, label: a))
                                .toList(),
                            leadingIcon: const Icon(Icons.history_toggle_off),
                            hintText: 'Antecedent',
                            onSelected: (v) => setState(() => _antecedent = v),
                          ),
                          const SizedBox(height: 12),
                          DropdownMenu<String>(
                            initialSelection: _consequence,
                            dropdownMenuEntries: _consequences
                                .map((c) =>
                                DropdownMenuEntry<String>(value: c, label: c))
                                .toList(),
                            leadingIcon: const Icon(Icons.outbond_outlined),
                            hintText: 'Consequence',
                            onSelected: (v) => setState(() => _consequence = v),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ---------- SEVERITY ----------
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Severity',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: _severityLevels
                                .map((s) =>
                                ButtonSegment<String>(value: s, label: Text(s)))
                                .toList(),
                            selected: {_severity},
                            onSelectionChanged: (set) =>
                                setState(() => _severity = set.first),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ---------- DETAILS ----------
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Details (Optional)',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _locationCtrl,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Location (e.g., Classroom A, Cafeteria)',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional narrative)',
                              prefixIcon: Icon(Icons.notes_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ---------- ACTIONS ----------
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Record', style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                              if (_isTiming) Text('Timing: $_elapsedLabel'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _quickLog,
                                icon: const Icon(Icons.add_task),
                                label: const Text('Quick Log'),
                              ),
                              FilledButton.icon(
                                onPressed: _toggleTimer,
                                icon: Icon(_isTiming
                                    ? Icons.stop_circle_outlined
                                    : Icons.play_circle_outline),
                                label: Text(_isTiming
                                    ? 'Stop Timer & Save'
                                    : 'Start Timer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ---------- RECENT EVENTS ----------
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recent Events',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('behavior_events')
                                .where('uid', isEqualTo: user.uid)
                                .orderBy('createdAt', descending: true)
                                .limit(25)
                                .snapshots(),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const LinearProgressIndicator(
                                    minHeight: 2);
                              }
                              if (snap.hasError) {
                                return SelectableText(
                                  'Error: ${snap.error}',
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .bodyMedium,
                                );
                              }
                              final docs = snap.data?.docs ?? const [];
                              if (docs.isEmpty) {
                                return const Text(
                                    'No events yet. Your logs will appear here.');
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                separatorBuilder: (context,
                                    index) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final d = docs[i];
                                  final m = d.data();
                                  final student = (m['studentName'] as String?) ??
                                      '(Unknown)';
                                  final type = (m['behaviorType'] as String?) ??
                                      '';
                                  final severity = (m['severity'] as String?) ??
                                      (() {
                                        final x = m['intensity'] as int?;
                                        if (x == null) return '';
                                        if (x <= 1) return 'Mild';
                                        if (x >= 5) return 'Severe';
                                        return 'Moderate';
                                      })();
                                  final createdAt = m['createdAt'] as Timestamp?;
                                  final duration = (m['durationSeconds'] as int?);
                                  final subtitle = duration == null
                                      ? 'Severity $severity • ${_formatWhen(
                                      createdAt)}'
                                      : 'Severity $severity • ${_formatWhen(
                                      createdAt)} • ${duration}s';

                                  return Dismissible(
                                    key: ValueKey(d.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: const Icon(Icons.delete_outline),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await showDialog<bool>(
                                        context: context,
                                        builder: (dialogCtx) =>
                                            AlertDialog(
                                              title: const Text(
                                                  'Delete event?'),
                                              content: const Text(
                                                  'This action cannot be undone.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator
                                                          .of(dialogCtx)
                                                          .pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                FilledButton(
                                                  onPressed: () =>
                                                      Navigator
                                                          .of(dialogCtx)
                                                          .pop(true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                      ) ??
                                          false;
                                    },
                                    onDismissed: (direction) async {
                                      final messenger = ScaffoldMessenger.of(
                                          context);
                                      try {
                                        await d.reference.delete();
                                        messenger.showSnackBar(const SnackBar(
                                            content: Text('Event deleted.')));
                                      } catch (e) {
                                        messenger.showSnackBar(SnackBar(
                                            content: Text(
                                                'Failed to delete: $e')));
                                      }
                                    },
                                    child: ListTile(
                                      leading: const Icon(
                                          Icons.event_note_outlined),
                                      title: Text(student),
                                      subtitle: Text(subtitle),
                                      trailing: Text(type),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}