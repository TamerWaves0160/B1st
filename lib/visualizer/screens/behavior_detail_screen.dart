import 'package:flutter/material.dart';
import '../models/student.dart';
import '../widgets/behavior_chart.dart';

class BehaviorDetailScreen extends StatelessWidget {
  final Student student;

  const BehaviorDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${student.name} Behaviors')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BehaviorChart(behaviors: student.behaviors),
      ),
    );
  }
}