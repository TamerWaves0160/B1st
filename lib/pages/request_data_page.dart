import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class RequestDataPage extends StatefulWidget {
  const RequestDataPage({super.key});

  @override
  State<RequestDataPage> createState() => _RequestDataPageState();
}

class _RequestDataPageState extends State<RequestDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _requestTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedFormat = 'CSV';
  String _selectedTimeframe = 'Last 30 days';
  bool _isSubmitting = false;

  final List<String> _dataFormats = ['CSV', 'Excel', 'JSON', 'PDF Report'];
  final List<String> _timeframes = [
    'Last 7 days',
    'Last 30 days',
    'Last 3 months',
    'Last 6 months',
    'Last year',
    'All data',
    'Custom date range',
  ];

  void _copyEmailTemplate() {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'your-email@example.com';

    final template =
        '''
Subject: Data Export Request - BehaviorFirst

Dear BehaviorFirst Support Team,

I would like to request an export of my behavioral data from the BehaviorFirst app.

Request Details:
- Account Email: $userEmail
- Data Format: $_selectedFormat
- Time Period: $_selectedTimeframe
- Request Type: ${_requestTypeController.text.isEmpty ? 'Student behavioral data' : _requestTypeController.text}
- Additional Details: ${_descriptionController.text.isEmpty ? 'Please export all available data for analysis.' : _descriptionController.text}

Please send the exported data to this email address. If you need any additional information or have questions about this request, please let me know.

Thank you for your assistance.

Best regards,
[Your Name]
''';

    Clipboard.setData(ClipboardData(text: template));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email template copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await FirebaseFirestore.instance.collection('data_requests').add({
        'userId': user.uid,
        'userEmail': user.email,
        'requestType': _requestTypeController.text.isEmpty
            ? 'Student behavioral data'
            : _requestTypeController.text,
        'dataFormat': _selectedFormat,
        'timeframe': _selectedTimeframe,
        'description': _descriptionController.text,
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
      });

      // Send notification to admin
      try {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'notifyDataRequest',
        );
        await callable.call({
          'userEmail': user.email,
          'requestType': _requestTypeController.text.isEmpty
              ? 'Student behavioral data'
              : _requestTypeController.text,
          'dataFormat': _selectedFormat,
          'timeframe': _selectedTimeframe,
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to send notification: $e');
        }
        // Don't fail the whole request if notification fails
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Data request submitted successfully! We will process your request within 24-48 hours.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Data Export'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              const Center(
                child: Icon(
                  Icons.download_rounded,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Export Your Data',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Request a complete export of your behavioral tracking data',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Information Card
              Card(
                elevation: 2,
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[800]),
                          const SizedBox(width: 8),
                          Text(
                            'What data can be exported?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDataItem('• All behavior observation records'),
                      _buildDataItem('• Student information and profiles'),
                      _buildDataItem('• Generated FBA and BIP reports'),
                      _buildDataItem('• Time-stamped behavior tracking data'),
                      _buildDataItem('• Intervention strategies and outcomes'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Request Form
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Request Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Request Type
                      TextFormField(
                        controller: _requestTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Request Type (Optional)',
                          hintText:
                              'e.g., Student behavioral data, Reports only, etc.',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Data Format
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFormat,
                        decoration: const InputDecoration(
                          labelText: 'Data Format',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.file_present),
                        ),
                        items: _dataFormats.map((format) {
                          return DropdownMenuItem(
                            value: format,
                            child: Text(format),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedFormat = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Timeframe
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTimeframe,
                        decoration: const InputDecoration(
                          labelText: 'Time Period',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.date_range),
                        ),
                        items: _timeframes.map((timeframe) {
                          return DropdownMenuItem(
                            value: timeframe,
                            child: Text(timeframe),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedTimeframe = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Additional Details (Optional)',
                          hintText:
                              'Any specific requirements or notes for your data export...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyEmailTemplate,
                      icon: const Icon(Icons.content_copy),
                      label: const Text('Copy Email Template'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitRequest,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isSubmitting ? 'Submitting...' : 'Submit Request',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Contact Information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.schedule, color: Colors.grey, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Processing Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Data export requests are processed within 24-48 hours',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Questions? Contact us:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text('behaviorfirst@outlook.com'),
                    const Text('361-438-4885'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  @override
  void dispose() {
    _requestTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
