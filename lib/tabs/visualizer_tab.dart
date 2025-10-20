import 'package:behaviorfirst/data/mock_student_data.dart';
import 'package:behaviorfirst/visualizer/models/student.dart';
import 'package:behaviorfirst/visualizer/models/behavior.dart';
import 'package:behaviorfirst/visualizer/screens/student_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Helper function to categorize behavior based on description
String categorizeBehavior(String behaviorDescription) {
  final description = behaviorDescription.toLowerCase();

  // On-task behaviors (positive, engaged, working)
  if (description.contains('completed') ||
      description.contains('working') ||
      description.contains('focused') ||
      description.contains('engaged') ||
      description.contains('participated') ||
      description.contains('answered correctly') ||
      description.contains('followed directions') ||
      description.contains('on task')) {
    return 'On-task';
  }

  // Participating behaviors (active engagement)
  if (description.contains('raised hand') ||
      description.contains('asked question') ||
      description.contains('helped') ||
      description.contains('shared') ||
      description.contains('contributed') ||
      description.contains('volunteered')) {
    return 'Participating';
  }

  // Disruptive behaviors (aggressive, loud, interfering)
  if (description.contains('hit') ||
      description.contains('threw') ||
      description.contains('yelled') ||
      description.contains('screamed') ||
      description.contains('destroyed') ||
      description.contains('kicked') ||
      description.contains('pushed') ||
      description.contains('fought') ||
      description.contains('aggressive') ||
      description.contains('tantrum') ||
      description.contains('profanity') ||
      description.contains('cursed') ||
      description.contains('swore')) {
    return 'Disruptive';
  }

  // Off-task behaviors (distracted, not following, wandering)
  if (description.contains('out of seat') ||
      description.contains('wandered') ||
      description.contains('distracted') ||
      description.contains('talking') ||
      description.contains('blurting') ||
      description.contains('called out') ||
      description.contains('not following') ||
      description.contains('refused') ||
      description.contains('argued') ||
      description.contains('off task') ||
      description.contains('didn\'t complete') ||
      description.contains('avoided') ||
      description.contains('walked around')) {
    return 'Off-task';
  }

  // Unresponsive behaviors (withdrawn, passive, non-participating)
  if (description.contains('silent') ||
      description.contains('head down') ||
      description.contains('sleeping') ||
      description.contains('ignored') ||
      description.contains('no response') ||
      description.contains('withdrawn') ||
      description.contains('isolated') ||
      description.contains('cried') ||
      description.contains('shut down')) {
    return 'Unresponsive';
  }

  // Default to Off-task if no clear category
  return 'Off-task';
}

class VisualizerTab extends StatelessWidget {
  const VisualizerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, snapshot) {
        // Debug: Print connection state
        debugPrint(
          '📊 Visualizer: ConnectionState = ${snapshot.connectionState}',
        );
        debugPrint('📊 Visualizer: Has data = ${snapshot.hasData}');
        debugPrint('📊 Visualizer: Has error = ${snapshot.hasError}');
        if (snapshot.hasData) {
          debugPrint(
            '📊 Visualizer: Document count = ${snapshot.data!.docs.length}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading data: ${snapshot.error}'),
                const SizedBox(height: 8),
                Text(
                  'Stack trace: ${snapshot.stackTrace}',
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off, size: 48),
                const SizedBox(height: 16),
                const Text('No students found in Firestore.'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('students')
                          .doc('test')
                          .set({
                            'name': 'Test Student',
                            'age': 10,
                            'grade': '5th',
                            'behaviorHistory': [],
                          });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test student created!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Test Student'),
                ),
              ],
            ),
          );
        }

        try {
          final students = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            // Add doc ID if missing
            if (!data.containsKey('id')) {
              data['id'] = doc.id;
            }

            // Provide defaults for missing fields
            data['age'] = data['age'] ?? 0;
            data['grade'] = data['grade'] ?? 'Unknown';
            data['behaviorHistory'] = data['behaviorHistory'] ?? [];

            final studentProfile = StudentProfile.fromJson(data);
            return Student(
              id: studentProfile.id,
              name: studentProfile.name,
              behaviors: studentProfile.behaviorHistory.map((incident) {
                return Behavior(
                  date: incident.date.toIso8601String().split('T').first,
                  type: categorizeBehavior(incident.behavior),
                  duration: incident.duration ?? 0,
                );
              }).toList(),
            );
          }).toList();

          return StudentListScreen(students: students);
        } catch (e, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text('Error parsing student data:'),
                const SizedBox(height: 8),
                Text('$e', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  'Stack: $stackTrace',
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
