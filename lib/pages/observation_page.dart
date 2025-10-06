// lib/pages/observation_page.dart
import 'package:behaviorfirst/data/mock_student_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ObservationPage extends StatefulWidget {
  const ObservationPage({super.key});

  @override
  State<ObservationPage> createState() => _ObservationPageState();
}

class _ObservationPageState extends State<ObservationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _studentNameController = TextEditingController();
  final _studentAgeController = TextEditingController();
  final _studentGradeController = TextEditingController();
  final _antecedentsController = TextEditingController();
  final _notesController = TextEditingController();
  final _customBehaviorController = TextEditingController();
  final _customConsequenceController = TextEditingController();
  final _durationController = TextEditingController();
  final _settingController = TextEditingController();

  // Form state
  bool _isNewStudent = true;
  String? _selectedStudentId;
  String? _selectedBehavior;
  String _selectedIntensity = 'Mild';
  bool _showCustomBehavior = false;
  bool _showCustomConsequence = false;
  bool _isLoading = false;
  List<DocumentSnapshot> _existingStudents = [];

  // Predefined behaviors
  final List<String> _behaviors = [
    'Aggression',
    'Disruption',
    'Noncompliance',
    'Calling out',
    'Elopement',
    'Self-injury',
    'Verbal outburst',
    'Property destruction',
    'Inappropriate touching',
    'Repetitive behavior',
    'Other (specify)',
  ];

  // Intensity levels
  final List<String> _intensityLevels = ['Mild', 'Moderate', 'Severe'];

  // Consequences (both positive and negative)
  final List<String> _consequences = [
    'Verbal redirection',
    'Removal from activity',
    'Loss of privilege',
    'Time out',
    'Physical escort',
    'Office referral',
    'Positive reinforcement given',
    'Praise provided',
    'Preferred activity offered',
    'Break/sensory time',
    'Ignored/no response',
    'Natural consequence',
    'Other (specify)',
  ];

  String _selectedConsequence = 'Verbal redirection';

  @override
  void initState() {
    super.initState();
    _loadExistingStudents();
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentAgeController.dispose();
    _studentGradeController.dispose();
    _antecedentsController.dispose();
    _notesController.dispose();
    _customBehaviorController.dispose();
    _customConsequenceController.dispose();
    _durationController.dispose();
    _settingController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingStudents() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('students').get();

      setState(() {
        _existingStudents = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
    }
  }

  Future<void> _saveObservation() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Determine behavior and consequence first
      String finalBehavior = _selectedBehavior ?? '';
      if (_selectedBehavior == 'Other (specify)' && _showCustomBehavior) {
        finalBehavior = _customBehaviorController.text.trim();
      }

      String finalConsequence = _selectedConsequence;
      if (_selectedConsequence == 'Other (specify)' && _showCustomConsequence) {
        finalConsequence = _customConsequenceController.text.trim();
      }

      // Create the new incident object
      final newIncident = BehaviorIncident(
        date: DateTime.now(),
        behavior: finalBehavior,
        antecedent: _antecedentsController.text.trim(),
        consequence: finalConsequence,
        setting: _settingController.text.trim().isEmpty 
            ? 'Not specified' 
            : _settingController.text.trim(),
        duration: int.tryParse(_durationController.text) ?? 0,
      );

      if (_isNewStudent) {
        // Create a new student with the first observation already in their history
        final studentData = {
          'name': _studentNameController.text.trim(),
          'age': int.tryParse(_studentAgeController.text) ?? 0,
          'grade': _studentGradeController.text.trim(),
          'ownerUid': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'id': '',
          'behaviorHistory': [newIncident.toJson()], // Add first incident
        };
        final studentDocRef = await FirebaseFirestore.instance
            .collection('students')
            .add(studentData);
        await studentDocRef.update({'id': studentDocRef.id});
      } else {
        // Add the new incident to an existing student's history
        final studentDocRef = FirebaseFirestore.instance
            .collection('students')
            .doc(_selectedStudentId);
        await studentDocRef.update({
          'behaviorHistory': FieldValue.arrayUnion([newIncident.toJson()])
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Observation saved successfully!')),
      );

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving observation: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _studentNameController.clear();
    _studentAgeController.clear();
    _studentGradeController.clear();
    _antecedentsController.clear();
    _notesController.clear();
    _customBehaviorController.clear();
    _durationController.clear();
    setState(() {
      _isNewStudent = true;
      _selectedStudentId = null;
      _selectedBehavior = null;
      _selectedIntensity = 'Mild';
      _showCustomBehavior = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavior Observation'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Student Selection Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Student Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // New vs Existing Student Toggle
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('New Student'),
                              value: true,
                              groupValue: _isNewStudent,
                              onChanged: (value) {
                                setState(() => _isNewStudent = value!);
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Existing Student'),
                              value: false,
                              groupValue: _isNewStudent,
                              onChanged: (value) {
                                setState(() => _isNewStudent = value!);
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (_isNewStudent) ...[
                        // New Student Form
                        TextFormField(
                          controller: _studentNameController,
                          decoration: const InputDecoration(
                            labelText: 'Student Name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Student name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _studentAgeController,
                                decoration: const InputDecoration(
                                  labelText: 'Age',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _studentGradeController,
                                decoration: const InputDecoration(
                                  labelText: 'Grade',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Existing Student Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedStudentId,
                          decoration: const InputDecoration(
                            labelText: 'Select Student *',
                            border: OutlineInputBorder(),
                          ),
                          items: _existingStudents.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(
                                '${data['name']}',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedStudentId = value);
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a student';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Behavior Selection Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Behavior Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Behavior Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedBehavior,
                        decoration: const InputDecoration(
                          labelText: 'Select Behavior *',
                          border: OutlineInputBorder(),
                        ),
                        items: _behaviors.map((behavior) {
                          return DropdownMenuItem<String>(
                            value: behavior,
                            child: Text(behavior),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBehavior = value;
                            _showCustomBehavior = value == 'Other (specify)';
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a behavior';
                          }
                          return null;
                        },
                      ),

                      // Custom Behavior Field (if "Other" selected)
                      if (_showCustomBehavior) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customBehaviorController,
                          decoration: const InputDecoration(
                            labelText: 'Specify Behavior *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_showCustomBehavior &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please specify the behavior';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _settingController,
                        decoration: const InputDecoration(
                          labelText: 'Setting/Location',
                          hintText: 'e.g., Classroom - math lesson, Cafeteria, Playground',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 1,
                      ),

                      const SizedBox(height: 16),

                      // Intensity Selection
                      const Text(
                        'Behavior Intensity *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _intensityLevels.map((intensity) {
                          return Expanded(
                            child: RadioListTile<String>(
                              title: Text(intensity),
                              value: intensity,
                              groupValue: _selectedIntensity,
                              onChanged: (value) {
                                setState(() => _selectedIntensity = value!);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Antecedents Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Antecedents',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _antecedentsController,
                        decoration: const InputDecoration(
                          labelText: 'What happened before the behavior? *',
                          hintText:
                              'Describe the events, triggers, or circumstances that occurred before the behavior...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Antecedents are required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Consequences Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Consequences',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Consequence Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedConsequence,
                        decoration: const InputDecoration(
                          labelText: 'What happened after the behavior? *',
                          border: OutlineInputBorder(),
                        ),
                        items: _consequences.map((consequence) {
                          return DropdownMenuItem<String>(
                            value: consequence,
                            child: Text(consequence),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedConsequence = value!;
                            _showCustomConsequence = value == 'Other (specify)';
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a consequence';
                          }
                          return null;
                        },
                      ),

                      // Custom Consequence Field (if "Other" selected)
                      if (_showCustomConsequence) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customConsequenceController,
                          decoration: const InputDecoration(
                            labelText: 'Specify Consequence *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_showCustomConsequence &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please specify the consequence';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Notes Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '(Optional)',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText:
                              'Additional observations, context, or notes',
                          hintText:
                              'Any additional details you want to record...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveObservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Saving Observation...'),
                        ],
                      )
                    : const Text(
                        'Log Observation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
