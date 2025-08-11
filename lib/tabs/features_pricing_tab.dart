import 'package:flutter/material.dart';
import '../widgets/hero_banner.dart';

class FeaturesPricingTab extends StatelessWidget {
  const FeaturesPricingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: const [
          HeroBanner(),
          SizedBox(height: 16),
          _PlaceholderCard(title: 'Features & Pricing — placeholder', body: 'We\'ll link the plan matrix and checkout later.'),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final String title;
  final String body;
  const _PlaceholderCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}