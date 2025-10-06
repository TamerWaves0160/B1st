import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:behaviorfirst/data/mock_student_data.dart';

class FirestorePopulationService {
  static Future<void> populateFirestore() async {
    final firestore = FirebaseFirestore.instance;
    final studentsCollection = firestore.collection('students');

    debugPrint('Starting Firestore population process...');

    // Clear existing documents to ensure a fresh start.
    final existingDocs = await studentsCollection.get();
    for (var doc in existingDocs.docs) {
      await doc.reference.delete();
    }
    debugPrint('Cleared existing data from "students" collection.');

    debugPrint('Populating Firestore "students" collection with new data...');

    // Loop through mock data and add to Firestore
    final mockStudentProfiles = MockStudentData.getStudentProfiles();
    for (var student in mockStudentProfiles) {
      await studentsCollection.doc(student.id).set(student.toJson());
    }
    debugPrint('Firestore "students" collection population complete.');
  }
}
