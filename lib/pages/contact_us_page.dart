import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const Center(
              child: Icon(Icons.support_agent, size: 80, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Get in Touch',
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
                'We\'re here to help with your behavioral data needs',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // Contact Information Cards
            _buildContactCard(
              context: context,
              icon: Icons.email_outlined,
              title: 'Email Us',
              subtitle: 'behaviorfirst@outlook.com',
              description:
                  'Send us an email for support, questions, or feedback',
              onTap: () => _copyToClipboard(
                context,
                'behaviorfirst@outlook.com',
                'Email address',
              ),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              context: context,
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: '361-438-4885',
              description: 'Speak directly with our support team',
              onTap: () =>
                  _copyToClipboard(context, '361-438-4885', 'Phone number'),
            ),
            const SizedBox(height: 32),

            // Support Information
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Support Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSupportItem(
                      'Technical Support',
                      'Get help with app features, data export, or troubleshooting issues',
                    ),
                    const SizedBox(height: 12),
                    _buildSupportItem(
                      'Data Questions',
                      'Assistance with behavior tracking, report generation, or data interpretation',
                    ),
                    const SizedBox(height: 12),
                    _buildSupportItem(
                      'Account Management',
                      'Help with account setup, billing, or subscription management',
                    ),
                    const SizedBox(height: 12),
                    _buildSupportItem(
                      'Feature Requests',
                      'Share your ideas for new features or improvements',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Response Time
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Column(
                children: [
                  Icon(Icons.schedule, color: Colors.blue, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Response Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'We typically respond within 24 hours during business days',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue[800], size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.content_copy, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
