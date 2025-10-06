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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No students found.'));
        }

        final students = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
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
      },
    );
  }
}
