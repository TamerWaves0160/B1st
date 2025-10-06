// lib/utils/firestore_test_helper.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class FirestoreTestHelper {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Call this function to populate Firestore with intervention database and mock student data
  static Future<void> populateFirestore() async {
    try {
      if (kDebugMode) {
        print('🚀 Calling populateFirestore function...');
      }

      final callable = _functions.httpsCallable('populateFirestore');
      final result = await callable.call();

      if (kDebugMode) {
        print('✅ Firestore populated successfully:');
        print('Interventions added: ${result.data['interventionsAdded']}');
        print('Students added: ${result.data['studentsAdded']}');
        print('Total operations: ${result.data['totalOperations']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error populating Firestore: $e');
      }
      rethrow;
    }
  }

  /// Generate embeddings for all interventions in Firestore
  static Future<void> generateInterventionEmbeddings() async {
    try {
      if (kDebugMode) {
        print('🧠 Generating embeddings for all interventions...');
      }

      final callable = _functions.httpsCallable(
        'generateInterventionEmbeddings',
      );
      final result = await callable.call();

      if (kDebugMode) {
        print('✅ Embeddings generated successfully:');
        print('Interventions processed: ${result.data['processedCount']}');
        print('Embeddings added: ${result.data['embeddingsGenerated']}');
        print('Total dimensions: ${result.data['dimensions']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating embeddings: $e');
      }
      rethrow;
    }
  }

  /// Check the status of embeddings in Firestore
  static Future<void> checkEmbeddingsStatus() async {
    try {
      if (kDebugMode) {
        print('🔍 Checking embeddings status in Firestore...');
      }

      final callable = _functions.httpsCallable('checkEmbeddingsStatus');
      final result = await callable.call();

      if (kDebugMode) {
        print('📊 Embeddings Status:');
        print('Total interventions: ${result.data['totalInterventions']}');
        print(
          'Interventions with embeddings: ${result.data['withEmbeddings']}',
        );
        print('Embedding dimensions: ${result.data['embeddingDimensions']}');
        print('Sample intervention: ${result.data['sampleIntervention']}');
        if (result.data['sampleEmbedding'] != null) {
          final sampleValues = result.data['sampleEmbedding'] as List;
          print(
            'Sample embedding (first 5 values): ${sampleValues.take(5).toList()}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking embeddings: $e');
      }
      rethrow;
    }
  }

  /// Test the generateInterventions function with sample data using embeddings
  static Future<void> testGenerateInterventions() async {
    try {
      if (kDebugMode) {
        print('🧪 Testing generateInterventions function with embeddings...');
      }

      final callable = _functions.httpsCallable('generateInterventions');
      final result = await callable.call({
        'behaviorDescription':
            'Student frequently gets out of seat during math lessons and calls out answers without raising hand',
        'ageGroup': 'elementary',
        'setting': 'classroom',
      });

      if (kDebugMode) {
        print('✅ Intervention generation successful:');
        print('Method: ${result.data['method']}');
        print('Confidence: ${result.data['confidence']}');
        print('Recommendations: ${result.data['recommendationCount']}');
        print('Analysis: ${result.data['behaviorAnalysis']}');
        print('\nInterventions:\n${result.data['interventions']}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating interventions: $e');
      }
      rethrow;
    }
  }

  /// Test embedding similarity with sample behavior descriptions
  static Future<void> testEmbeddingSimilarity() async {
    try {
      if (kDebugMode) {
        print('🔍 Testing embedding similarity...');
      }

      final callable = _functions.httpsCallable('testEmbeddingSimilarity');
      final result = await callable.call({
        'behaviorDescription':
            'Child leaves their seat frequently during instruction',
      });

      if (kDebugMode) {
        print('✅ Similarity test successful:');
        print('Top matches:');
        final matches = result.data['topMatches'] as List;
        for (int i = 0; i < matches.length; i++) {
          final match = matches[i];
          print(
            '${i + 1}. ${match['name']} (${(match['similarity'] * 100).toStringAsFixed(1)}% similar)',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error testing similarity: $e');
      }
      rethrow;
    }
  }

  /// Test the comprehensive AI analysis (Embeddings + LLM)
  static Future<void> testComprehensiveAnalysis({
    String? behaviorDescription,
    Map<String, dynamic>? studentInfo,
    String? ageGroup,
    String? setting,
  }) async {
    try {
      final testBehavior =
          behaviorDescription ??
          'Student frequently gets out of their seat during math lessons, walks around the classroom, and has difficulty staying focused on worksheets';

      final testStudent =
          studentInfo ??
          {
            'name': 'Alex',
            'age': 8,
            'grade': '3rd Grade',
          };

      if (kDebugMode) {
        print('🧠 Testing comprehensive AI analysis...');
        print('Behavior: ${testBehavior.substring(0, 50)}...');
      }

      final callable = _functions.httpsCallable(
        'generateComprehensiveAnalysis',
      );
      final result = await callable.call({
        'behaviorDescription': testBehavior,
        'studentInfo': testStudent,
        'ageGroup': ageGroup ?? 'elementary',
        'setting': setting ?? 'classroom',
        'includeDetailedAnalysis': true,
      });

      if (kDebugMode) {
        print('🎯 Comprehensive Analysis Results:');
        print('Behavior Function: ${result.data['behaviorFunction']}');
        print(
          'Top Recommendations: ${result.data['recommendedInterventions'].length}',
        );
        print('Analysis Method: ${result.data['analysisMethod']}');
        print('\n📊 Detailed Analysis:');
        print(result.data['comprehensiveAnalysis']);
        print('\n🔍 Semantic Matches:');
        for (var match in result.data['semanticMatches']) {
          print(
            '- ${match['name']}: ${(match['similarity'] * 100).toStringAsFixed(1)}% match',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error testing comprehensive analysis: $e');
      }
      rethrow;
    }
  }
}
