import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase SDK
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBpaMnwNPv6WGofjEHFyDuysVcMjmlA2r4',
        authDomain: 'behaviorfirst-515f1.firebaseapp.com',
        projectId: 'behaviorfirst-515f1',
        storageBucket: 'behaviorfirst-515f1.firebasestorage.app',
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
    );
  }
}