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
                Expanded(
                  child: Text(
                    'Quick Intervention Recommendations',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                  ),
                  onChanged: _onInterventionTextChanged,
                ),
                if (_showLightbulb)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Tooltip(
                      message: 'Get an instant AI recommendation!',
                      child: InkWell(
                        onTap: _getInstantRecommendation,
                        child: Icon(
                          Icons.lightbulb,
                          color: Colors.amber,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzingIntervention ||
                        _interventionController.text.trim().isEmpty
                    ? null
                    : _generateQuickIntervention,
                icon: _isAnalyzingIntervention
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.psychology_alt),
                label: Text(
                  _isAnalyzingIntervention
                      ? 'Analyzing...'
                      : 'Get AI Recommendation',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_suggestedIntervention != null) ...[
              const SizedBox(height: 24),
              _buildInterventionResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInterventionResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Intervention',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Divider(height: 16),
          SelectableText(
            _suggestedIntervention!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
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
            _buildStudentSelector(),
            const SizedBox(height: 20),
            _buildReportTypeSelector(),
            const SizedBox(height: 20),
            _buildDateRangeSelector(),
            const SizedBox(height: 24),
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
    });

    try {
      // Ensure user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be signed in to use this feature.');
      }

      // Force token refresh to ensure it's valid
      await user.getIdToken(true);

      if (kDebugMode) {
        print(
          '🔍 Calling Firebase Function for: ${_interventionController.text.trim()}',
        );
        print('👤 User ID: ${user.uid}');
      }

      // Use the new RAG system
      final callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('getIntervention');

      final result = await callable.call({
        'situation': _interventionController.text.trim(),
      });

      final data = result.data as Map<String, dynamic>;
      final recommendation = data['recommendation'] as String? ?? 'No recommendation was generated.';

      // Save the report to Firestore for history
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null && recommendation.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('ai_reports')
            .add({
              'behaviorDescription': _interventionController.text.trim(),
              'reportContent': recommendation,
              'timestamp': FieldValue.serverTimestamp(),
              'analysisMethod': 'RAG', // Mark as a RAG-generated report
            });
      }

      setState(() {
        _suggestedIntervention = recommendation;
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
            } else if (text.length > 50) {
              _showLightbulb = true;
            } else if (text.length > 20) {
              _showLightbulb = true;
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

  Widget _buildSavedReports() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('Sign in to view saved reports.')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Previously Generated Reports',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('ai_reports')
                  .orderBy('timestamp', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No saved AI reports found.'),
                  );
                }

                final reports = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final reportData = report.data() as Map<String, dynamic>;
                    final timestamp = (reportData['timestamp'] as Timestamp?)
                        ?.toDate();
                    final behaviorDescription =
                        reportData['behaviorDescription'] as String?;

                    return ListTile(
                      leading: const Icon(Icons.article),
                      title: Text(
                        behaviorDescription ?? 'AI Generated Report',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        timestamp != null
                            ? '${timestamp.toLocal().month}/${timestamp.toLocal().day}/${timestamp.toLocal().year}'
                            : 'No date',
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Saved Report'),
                            content: Scrollbar(
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  reportData['reportContent'] as String? ??
                                      'No content.',
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
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
        // Load all students from Firestore
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('students').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error loading students: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final students = snapshot.data!.docs;

            if (students.isEmpty) {
              return const Text(
                'No students found. Create a student in the Observations tab first.',
                style: TextStyle(color: Colors.orange),
              );
            }

            // Check if current selected ID exists in the list
            final studentIds = students.map((doc) => doc.id).toList();
            final validSelectedId =
                _selectedStudentId != null &&
                    studentIds.contains(_selectedStudentId)
                ? _selectedStudentId
                : null;

            return DropdownButtonFormField<String>(
              initialValue: validSelectedId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose a student',
              ),
              items: students.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(data['name'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStudentId = value;
                });
              },
            );
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
}
