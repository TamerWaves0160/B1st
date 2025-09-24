import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/ai_report_service.dart';

class RenniReportsTab extends StatefulWidget {
  const RenniReportsTab({super.key});

  @override
  State<RenniReportsTab> createState() => _RenniReportsTabState();
}

class _RenniReportsTabState extends State<RenniReportsTab> {
  String? _selectedStudentId;
  String _selectedReportType = 'FBA';
  DateTimeRange? _selectedDateRange;
  bool _isGenerating = false;
  String? _generatedReport;

  // Intervention Request fields
  final _interventionController = TextEditingController();
  bool _isAnalyzingIntervention = false;
  bool _showLightbulb = false;
  String? _suggestedIntervention;
  String? _confidence;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Quick Intervention Recommendations Section (Priority)
              _buildQuickInterventionSection(),

              const SizedBox(height: 32),

              // Formal FBA/BIP Reports Section
              _buildFormalReportsSection(),

              if (_generatedReport != null) ...[
                const SizedBox(height: 24),
                _buildGeneratedReport(),
              ],

              const SizedBox(height: 32),
              _buildSavedReports(),
            ],
          ),
        ),
      ),
    );
  }

  // Quick Intervention Recommendations Section
  Widget _buildQuickInterventionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Intervention Recommendations',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Get immediate AI-powered intervention suggestions for challenging behaviors. Perfect for in-the-moment classroom support.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Student Name Input (Quick Entry)
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Student Name (optional)',
                hintText: 'e.g., Alex, Jordan, etc.',
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: (value) {
                // Optional: store student name for context
              },
            ),
            const SizedBox(height: 16),

            // Behavior Description with Smart Lightbulb
            Stack(
              children: [
                TextField(
                  controller: _interventionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Describe the Challenging Behavior',
                    hintText:
                        'e.g., "Student is calling out answers without raising hand during math lessons, disrupting other students..."',
                    prefixIcon: Icon(Icons.description),
                  ),
                  onChanged: (value) {
                    setState(() {
                      // This will trigger a rebuild and enable/disable the button
                    });
                    _onInterventionTextChanged(value);
                  },
                ),

                // Smart Lightbulb Icon (appears when AI is confident)
                if (_showLightbulb)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _getInstantRecommendation,
                        icon: const Icon(Icons.lightbulb, color: Colors.white),
                        tooltip:
                            'Get instant recommendation (${_confidence}% confident)',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Generate Recommendations Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isAnalyzingIntervention ||
                        _interventionController.text.trim().isEmpty
                    ? null
                    : _generateQuickIntervention,
                icon: _isAnalyzingIntervention
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isAnalyzingIntervention
                      ? 'Generating Recommendations...'
                      : 'Get Intervention Recommendations',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // Quick Intervention Results
            if (_suggestedIntervention != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recommended Interventions',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _suggestedIntervention!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_confidence != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _confidence!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Formal FBA/BIP Reports Section
  Widget _buildFormalReportsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Formal FBA & BIP Reports',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generate comprehensive Functional Behavior Analysis (FBA) and Behavior Intervention Plans (BIP) using historical observation data.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Student Selection for Formal Reports
            _buildStudentSelector(),
            const SizedBox(height: 20),

            // Report Type Selection
            _buildReportTypeSelector(),
            const SizedBox(height: 20),

            // Date Range Selection
            _buildDateRangeSelector(),
            const SizedBox(height: 24),

            // Generate Formal Report Button
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  // Generate Quick Intervention Method
  Future<void> _generateQuickIntervention() async {
    if (_interventionController.text.trim().isEmpty) return;

    setState(() {
      _isAnalyzingIntervention = true;
      _suggestedIntervention = null;
      _confidence = null;
    });

    try {
      if (kDebugMode) {
        print(
          '🔍 Calling Firebase Function for: ${_interventionController.text.trim()}',
        );
      }

      // Use advanced AI system with embeddings + LLM
      final callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('generateComprehensiveAnalysis');

      final result = await callable.call({
        'behaviorDescription': _interventionController.text.trim(),
        'includeDetailedAnalysis': true,
        // Add context for better AI analysis
        'ageGroup': 'elementary', // TODO: Make this selectable in UI
        'setting': 'classroom', // TODO: Make this selectable in UI
      });

      final data = result.data as Map<String, dynamic>;

      // Extract the rich AI analysis
      final comprehensiveAnalysis =
          data['comprehensiveAnalysis'] as String? ?? '';
      final behaviorFunction = data['behaviorFunction'] as String? ?? '';
      final recommendedInterventions =
          data['recommendedInterventions'] as List? ?? [];
      final analysisMethod = data['analysisMethod'] as String? ?? 'AI Analysis';
      final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

      // Format the response for display
      String formattedResponse = '';

      if (behaviorFunction.isNotEmpty) {
        formattedResponse +=
            '**BEHAVIOR FUNCTION ANALYSIS:**\n$behaviorFunction\n\n';
      }

      if (comprehensiveAnalysis.isNotEmpty) {
        formattedResponse +=
            '**COMPREHENSIVE ANALYSIS:**\n$comprehensiveAnalysis\n\n';
      }

      if (recommendedInterventions.isNotEmpty) {
        formattedResponse += '**TOP RECOMMENDATIONS:**\n';
        for (int i = 0; i < recommendedInterventions.length; i++) {
          final intervention =
              recommendedInterventions[i] as Map<String, dynamic>;
          final name =
              intervention['name'] as String? ?? 'Intervention ${i + 1}';
          final description = intervention['description'] as String? ?? '';
          final similarity = intervention['similarity'] as double? ?? 0.0;

          formattedResponse +=
              '${i + 1}. **$name** (${(similarity * 100).round()}% match)\n';
          if (description.isNotEmpty) {
            formattedResponse += '   $description\n';
          }
          formattedResponse += '\n';
        }
      }

      final matchCount = metadata['semanticMatches'] as int? ?? 0;
      final totalChecked = metadata['totalInterventionsChecked'] as int? ?? 0;
      final confidenceText =
          'Generated using $analysisMethod - analyzed $totalChecked interventions, found $matchCount semantic matches';

      setState(() {
        _suggestedIntervention = formattedResponse.isNotEmpty
            ? formattedResponse
            : 'No specific recommendations generated.';
        _confidence = confidenceText;
        _isAnalyzingIntervention = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('💥 Advanced AI analysis failed with error: $e');
      }

      // Show error message instead of fallback
      setState(() {
        _suggestedIntervention = '''**AI Analysis Temporarily Unavailable**

We encountered an issue with the advanced AI analysis system. This could be due to:
• Authentication requirements (please sign in)
• Temporary service interruption
• Network connectivity issues

Please try again in a moment or contact support if the issue persists.

Error details: ${e.toString()}''';
        _confidence =
            'Advanced AI system temporarily unavailable - please try again';
        _isAnalyzingIntervention = false;
      });
    }
  }

  // Smart Lightbulb Functionality
  void _onInterventionTextChanged(String text) {
    // Make lightbulb appear much easier for immediate user feedback
    if (text.trim().length > 20) {
      setState(() {
        _isAnalyzingIntervention = true;
      });

      // Shorter delay for better UX
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _interventionController.text.trim().length > 20) {
          setState(() {
            _isAnalyzingIntervention = false;
            // More lenient conditions for lightbulb to show
            final hasKeywords =
                text.toLowerCase().contains('calls out') ||
                text.toLowerCase().contains('disrupt') ||
                text.toLowerCase().contains('out of seat') ||
                text.toLowerCase().contains('aggressive') ||
                text.toLowerCase().contains('refuses') ||
                text.toLowerCase().contains('math') ||
                text.toLowerCase().contains('reading') ||
                text.toLowerCase().contains('challenging') ||
                text.toLowerCase().contains('behavior') ||
                text.toLowerCase().contains('student') ||
                text.toLowerCase().contains('class') ||
                text.toLowerCase().contains('attention') ||
                text.toLowerCase().contains('focus') ||
                text.toLowerCase().contains('difficult');

            if (hasKeywords && text.length > 30) {
              _showLightbulb = true;
              _confidence = '85';
            } else if (text.length > 50) {
              _showLightbulb = true;
              _confidence = '72';
            } else if (text.length > 20) {
              _showLightbulb = true;
              _confidence = '65';
            } else {
              _showLightbulb = false;
            }
          });
        }
      });
    } else {
      setState(() {
        _showLightbulb = false;
        _isAnalyzingIntervention = false;
      });
    }
  }

  void _getInstantRecommendation() {
    // Use the same Vertex AI generation as the main button
    _generateQuickIntervention();
  }

  Widget _buildStudentSelector() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Student',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        // Temporarily simplified for testing - replace with StreamBuilder later
        DropdownButtonFormField<String>(
          value: _selectedStudentId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Choose a student for AI intervention testing',
          ),
          items: const [
            DropdownMenuItem(
              value: 'test-student-1',
              child: Text('Alex (Test Student)'),
            ),
            DropdownMenuItem(
              value: 'test-student-2',
              child: Text('Jordan (Demo Student)'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedStudentId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildReportTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Type',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('FBA'),
                subtitle: const Text('Functional Behavior Analysis'),
                value: 'FBA',
                groupValue: _selectedReportType,
                onChanged: (value) {
                  setState(() {
                    _selectedReportType = value!;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('BIP'),
                subtitle: const Text('Behavior Intervention Plan'),
                value: 'BIP',
                groupValue: _selectedReportType,
                onChanged: (value) {
                  setState(() {
                    _selectedReportType = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range (Optional)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final dateRange = await showDateRangePicker(
              context: context,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              initialDateRange: _selectedDateRange,
            );
            if (dateRange != null) {
              setState(() {
                _selectedDateRange = dateRange;
              });
            }
          },
          icon: const Icon(Icons.date_range),
          label: Text(
            _selectedDateRange == null
                ? 'Select date range (all data if not selected)'
                : '${_selectedDateRange!.start.month}/${_selectedDateRange!.start.day}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.month}/${_selectedDateRange!.end.day}/${_selectedDateRange!.end.year}',
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    final canGenerate = _selectedStudentId != null && !_isGenerating;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canGenerate ? _generateReport : null,
        icon: _isGenerating
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _isGenerating
              ? 'Generating Report...'
              : 'Generate $_selectedReportType Report',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGeneratedReport() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Generated $_selectedReportType Report',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // TODO: Export to PDF
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF export coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.download),
                  tooltip: 'Export to PDF',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _generatedReport!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport() async {
    if (_selectedStudentId == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get student name
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(_selectedStudentId!)
          .get();

      if (!studentDoc.exists) throw Exception('Student not found');

      final studentName = studentDoc.data()!['name'] as String;

      // Generate report using AI service
      final aiService = AIReportService();
      final report = await aiService.generateReport(
        studentId: _selectedStudentId!,
        studentName: studentName,
        reportType: _selectedReportType,
        ownerUid: userId,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      );

      setState(() {
        _generatedReport = report.content;
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSavedReports() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Previously Generated Reports',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Temporarily simplified for testing - replace with StreamBuilder later
            Container(
              padding: const EdgeInsets.all(32),
              child: const Center(
                child: Text(
                  'AI Reports History (temporarily disabled for testing)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
