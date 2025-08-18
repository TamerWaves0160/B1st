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
  // ---------- FORM STATE ----------
  final _formKey = GlobalKey<FormState>();

  // Student is a free-text field for now; later I will replace with a
  // dropdown fed by a Students collection.
  final TextEditingController _studentCtrl = TextEditingController();

  // Behavior type — more to be added later.
  final List<String> _behaviorTypes = const [
    'Noncompliance', 'Disruption', 'Aggression', 'Elopement', 'Off-task', 'Other'
  ];
  String? _selectedBehaviorType;

  // Intensity from 1 to 5.
  double _intensity = 3;

  // (Antecedent/Consequence)
  final List<String> _antecedents = const [
    'Demand placed', 'Transition', 'Attention diverted', 'Unstructured time', 'Denied access', 'Other'
  ];
  final List<String> _consequences = const [
    'Redirection', 'Removal of item', 'Planned ignoring', 'Break given', 'Call home', 'Other'
  ];
  String? _antecedent;
  String? _consequence;

  // Location and notes — optional free text.
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  // ---------- TIMER STATE ----------
  Timer? _timer;
  DateTime? _startedAt; // when timing began
  Duration _elapsed = Duration.zero; // live-updated while timing in progress

  bool get _isTiming => _timer != null;

  @override
  void dispose() {
    _studentCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Elapsed timer display.
  String get _elapsedLabel {
    final total = _elapsed.inSeconds;
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  // Validate core required fields before writing to Firestore.
  bool _validateCore() {
    if ((_studentCtrl.text.trim()).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student is required.')),
      );
      return false;
    }
    if (_selectedBehaviorType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a behavior type.')),
      );
      return false;
    }
    return true;
  }

  // Core Firestore write. All entries get date/time stamps. Duration is only
  // for timed events.
  Future<void> _writeEvent({DateTime? startedAt, DateTime? endedAt}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to record events.')),
      );
      return;
    }

    final ref = FirebaseFirestore.instance.collection('behavior_events');

    int? duration;
    if (startedAt != null && endedAt != null) {
      duration = endedAt.difference(startedAt).inSeconds;
    }

    final data = <String, dynamic>{
      'uid': user.uid,
      'student': _studentCtrl.text.trim(),
      'behaviorType': _selectedBehaviorType,
      'intensity': _intensity.round(),
      'antecedent': _antecedent?.trim(),
      'consequence': _consequence?.trim(),
      'location': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt),
      if (endedAt != null) 'endedAt': Timestamp.fromDate(endedAt),
      if (duration != null) 'durationSeconds': duration,
    };

    await ref.add(data);
  }

  // Quick Log: creates an instantaneous event with no duration.
  Future<void> _quickLog() async {
    if (!_validateCore()) return;

    // Grab a reference BEFORE any await so we don't need context later.
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _writeEvent();
      messenger.showSnackBar(
        const SnackBar(content: Text('Event recorded.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to record: $e')),
      );
    }
  }

  // Start/Stop timer for duration-based behaviors.
  void _toggleTimer() async {
    if (_isTiming) {
      // Stopping: finalize duration and write the event.
      _timer?.cancel();
      _timer = null;
      final ended = DateTime.now();
      final started = _startedAt!;
      setState(() {
        _startedAt = null;
      });

      if (!_validateCore()) return;

      // Capture messenger BEFORE await
      final messenger = ScaffoldMessenger.of(context);

      try {
        await _writeEvent(startedAt: started, endedAt: ended);
        messenger.showSnackBar(
          SnackBar(content: Text('Duration recorded: $_elapsedLabel')),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to record: $e')),
        );
      } finally {
        if (mounted) setState(() => _elapsed = Duration.zero);
      }
    } else {
      // Starting timer (no async gap here)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Begin Observation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------- Student ----------
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Student', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _studentCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Enter student name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ---------- Behavior Type ----------
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Behavior Type', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _behaviorTypes.map((t) {
                          final selected = _selectedBehaviorType == t;
                          return ChoiceChip(
                            label: Text(t),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedBehaviorType = t),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ---------- Intensity ----------
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
                          const Text('Intensity', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_intensity.round().toString()),
                        ],
                      ),
                      Slider(
                        value: _intensity,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _intensity.round().toString(),
                        onChanged: (v) => setState(() => _intensity = v),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ---------- ABC Context (optional) ----------
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Context (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _antecedent,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Antecedent',
                          prefixIcon: Icon(Icons.history_toggle_off),
                        ),
                        items: _antecedents
                            .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                            .toList(),
                        onChanged: (v) => setState(() => _antecedent = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _consequence,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Consequence',
                          prefixIcon: Icon(Icons.outbond_outlined),
                        ),
                        items: _consequences
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _consequence = v),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ---------- Location & Notes (optional) ----------
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Details (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _locationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Location (e.g., Classroom A, Cafeteria)',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
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

              // ---------- Actions: Quick Log or Timer ----------
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
                          const Text('Record', style: TextStyle(fontWeight: FontWeight.bold)),
                          if (_isTiming)
                            Text('Timing: $_elapsedLabel', style: const TextStyle(fontFeatures: [])),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          // Quick Log creates an instantaneous event (no duration)
                          ElevatedButton.icon(
                            onPressed: _quickLog,
                            icon: const Icon(Icons.add_task),
                            label: const Text('Quick Log'),
                          ),
                          // Timer toggles between Start and Stop
                          FilledButton.icon(
                            onPressed: _toggleTimer,
                            icon: Icon(_isTiming ? Icons.stop_circle_outlined : Icons.play_circle_outline),
                            label: Text(_isTiming ? 'Stop Timer & Save' : 'Start Timer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
