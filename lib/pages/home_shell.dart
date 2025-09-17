import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../tabs/landing_tab.dart';
import '../tabs/dashboard_tab.dart';
import '../tabs/features_pricing_tab.dart';
import '../tabs/renni_reports_tab.dart';
import '../widgets/user_status_badge.dart';
import 'contact_us_page.dart';
import 'request_data_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _bottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isLoggedIn = user != null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('BehaviorFirst'),
            bottom: TabBar(
              isScrollable: false,
              controller: _tabController,
              labelPadding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: isLoggedIn ? 'Dashboard' : 'Home'),
                const Tab(text: 'Features & Pricing'),
                Tab(
                  text: 'Renni — AI Reports',
                  icon: isLoggedIn ? null : const Icon(Icons.lock, size: 16),
                ),
              ],
            ),
            actions: [const UserStatusBadge(), const SizedBox(width: 12)],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              isLoggedIn ? const DashboardTab() : const LandingTab(),
              const FeaturesPricingTab(),
              isLoggedIn
                  ? const RenniReportsTab()
                  : _buildLoginRequired('AI Reports'),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _bottomIndex,
            onTap: (i) {
              setState(() => _bottomIndex = i);
              if (i == 0) {
                if (!isLoggedIn) {
                  _showLoginRequired('Request Data');
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RequestDataPage(),
                  ),
                );
              }
              if (i == 1) {
                if (!isLoggedIn) {
                  _showLoginRequired('Intervention Recommendations');
                  return;
                }
                // Navigate to Renni Reports tab and auto-open intervention request
                _tabController.animateTo(2); // Renni Reports is tab index 2
                // TODO: Add method to auto-expand intervention section
              }
              if (i == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactUsPage(),
                  ),
                );
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: isLoggedIn
                    ? const Icon(Icons.dataset)
                    : const Icon(Icons.lock),
                label: 'Request Data',
              ),
              BottomNavigationBarItem(
                icon: isLoggedIn
                    ? const Icon(Icons.lightbulb)
                    : const Icon(Icons.lock),
                label: 'Intervention Recs',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.mail_outline),
                label: 'Contact Us',
              ),
            ],
          ),
        );
      },
    );
  }

  // Authentication guard methods
  Widget _buildLoginRequired(String featureName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'Sign In Required',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'You need to sign in to access $featureName',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Switch to the first tab which contains login
                _tabController.animateTo(0);
              },
              icon: const Icon(Icons.login),
              label: const Text('Go to Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginRequired(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock),
        title: const Text('Sign In Required'),
        content: Text('You need to sign in to access $featureName.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Switch to the first tab which contains login
              _tabController.animateTo(0);
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
