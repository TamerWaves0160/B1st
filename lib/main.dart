import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/vertex_ai_service.dart';
import 'pages/home_shell.dart';
import 'pages/observation_page.dart';
import 'utils/firestore_test_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase SDK
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBpaMnwNPv6WGofjEHFyDuysVcMjmlA2r4',
        authDomain: 'behaviorfirst-515f1.firebaseapp.com',
        projectId: 'behaviorfirst-515f1',
        // IMPORTANT: storageBucket should be the bucket name, not firebasestorage.app
        storageBucket: 'behaviorfirst-515f1.appspot.com',
        messagingSenderId: '538557537127',
        appId: '1:538557537127:web:8fb975023b577abd9badc2',
        measurementId: 'G-4DGSVZPX30',
      ),
    );
    // Persist sessions across reloads for web.
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } else {
    await Firebase.initializeApp();
  }

  // Initialize Vertex AI service
  try {
    await VertexAIService.initialize();
  } catch (e) {
    if (kIsWeb) {
      if (kDebugMode) {
        debugPrint(
          'Vertex AI initialization failed (this is expected on first run): $e',
        );
      }
    }
  }

  // In debug mode, populate Firestore with intervention data if needed
  if (kDebugMode && kIsWeb) {
    try {
      debugPrint('🔄 Setting up Firestore data and embeddings...');

      // First, populate the basic data
      await FirestoreTestHelper.populateFirestore();

      // Then generate embeddings for semantic matching
      await FirestoreTestHelper.generateInterventionEmbeddings();

      // Check embeddings status to verify they were stored
      await FirestoreTestHelper.checkEmbeddingsStatus();

      // Test the complete AI system (Embeddings + LLM)
      debugPrint('🤖 Testing complete AI system...');
      await FirestoreTestHelper.testComprehensiveAnalysis();

      debugPrint(
        '🎉 Setup complete! Your AI system now uses semantic embeddings + LLM analysis.',
      );
    } catch (e) {
      debugPrint('ℹ️ Setup skipped or failed: $e');
    }
  }

  runApp(const BehaviorFirstApp());
}

class BehaviorFirstApp extends StatelessWidget {
  const BehaviorFirstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BehaviorFirst',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: const HomeShell(),
      routes: {'/observe': (context) => const ObservationPage()},
    );
  }
}
