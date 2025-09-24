import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

class VertexAIService {
  static const String _projectId = 'behaviorfirst-515f1';
  static const String _location = 'us-central1';

  static AutoRefreshingAuthClient? _authClient;

  /// Initialize Vertex AI service with service account authentication
  static Future<void> initialize() async {
    try {
      // Load service account credentials
      final credentialsJson = await _loadCredentials();
      final credentials = ServiceAccountCredentials.fromJson(credentialsJson);

      // Create authenticated client with proper scopes
      final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
      _authClient = await clientViaServiceAccount(credentials, scopes);

      if (kDebugMode) {
        print('✅ Vertex AI service initialized successfully');
        print('📧 Service Account Email: ${credentials.email}');
        print('🔑 Project ID: $_projectId');
        print('📍 Location: $_location');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Vertex AI service: $e');
      }
      throw Exception('Failed to initialize Vertex AI: $e');
    }
  }

  /// Load service account credentials
  static Future<Map<String, dynamic>> _loadCredentials() async {
    try {
      // Always load from assets for consistency across platforms
      final String response = await rootBundle.loadString(
        'assets/credentials/behaviorfirst-515f1-87e4804bb9f1.json',
      );
      return json.decode(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load credentials from assets: $e');
      }
      throw Exception('Failed to load credentials: $e');
    }
  }

  /// Generate intervention recommendations using Vertex AI
  static Future<String> generateInterventionRecommendations(
    String behaviorDescription,
  ) async {
    if (_authClient == null) {
      await initialize();
    }

    try {
      // Use the updated Vertex AI Gemini model endpoint
      final url =
          'https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/google/models/gemini-1.5-flash:generateContent';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': _buildInterventionPrompt(behaviorDescription)},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2048,
          'topP': 0.9,
          'topK': 40,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ],
      };

      if (kDebugMode) {
        print('🚀 Calling Vertex AI Gemini 1.5 Flash...');
        print('URL: $url');
        print('Project: $_projectId, Location: $_location');
      }

      final response = await _authClient!.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        print('📡 Vertex AI Response Status: ${response.statusCode}');
        print('📄 Vertex AI Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final candidates = responseData['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final content =
              candidates[0]['content']?['parts']?[0]?['text'] as String?;

          if (content != null && content.isNotEmpty) {
            if (kDebugMode) {
              print('✅ Successfully generated interventions using Vertex AI!');
            }
            return content.trim();
          }
        }

        // If we get here, the response format was unexpected
        if (kDebugMode) {
          print('⚠️ Unexpected response format from Vertex AI');
          print('Response data: $responseData');
        }
      }

      // Detailed error logging
      if (kDebugMode) {
        print('❌ Vertex AI API Error:');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      throw Exception(
        'Vertex AI request failed: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error with Vertex AI: $e');
      }
      throw Exception('Failed to generate interventions: $e');
    }
  }

  /// Build a comprehensive prompt for intervention generation
  static String _buildInterventionPrompt(String behaviorDescription) {
    return '''
You are an expert behavioral analyst and intervention specialist with extensive experience in Applied Behavior Analysis (ABA) and positive behavior support. 

Based on the following behavior description, provide a comprehensive, evidence-based intervention plan:

**BEHAVIOR DESCRIPTION:**
$behaviorDescription

**PLEASE PROVIDE:**

**1. BEHAVIOR ANALYSIS:**
- Identify the likely function of the behavior (attention, escape, tangible, sensory)
- Note any environmental factors that may be contributing
- Assess the intensity and frequency indicators

**2. IMMEDIATE INTERVENTION STRATEGIES:**
- 3-5 specific, actionable strategies that can be implemented immediately
- Include both proactive and reactive approaches
- Ensure strategies are appropriate for the setting described

**3. TEACHING REPLACEMENT BEHAVIORS:**
- Identify appropriate replacement behaviors that serve the same function
- Provide specific steps for teaching these behaviors
- Include practice opportunities and reinforcement strategies

**4. ENVIRONMENTAL MODIFICATIONS:**
- Suggest changes to the physical or social environment
- Include antecedent strategies to prevent the behavior
- Recommend scheduling or routine adjustments if applicable

**5. DATA COLLECTION PLAN:**
- Specify what data should be collected
- Recommend frequency and duration of data collection
- Include success criteria for measuring progress

**6. IMPLEMENTATION TIMELINE:**
- Provide a realistic timeline for implementation
- Include review and adjustment schedules
- Set measurable goals for 1 week, 2 weeks, and 1 month

Format your response in clear, actionable sections with specific strategies that can be implemented by teachers, parents, or support staff. Focus on positive, evidence-based approaches that respect the individual's dignity and promote long-term success.
''';
  }

  /// Dispose of resources
  static void dispose() {
    _authClient?.close();
    _authClient = null;
  }
}
