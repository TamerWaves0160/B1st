import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import '../models/student.dart';
import 'behavior_detail_screen.dart';

class StudentListScreen extends StatelessWidget {
  final List<Student> students;

  const StudentListScreen({super.key, required this.students});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(student.name),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BehaviorDetailScreen(student: student),
                ),
              );
            },
          );
        },
      ),
    );
  }
}