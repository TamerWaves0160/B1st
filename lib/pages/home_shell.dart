import 'package:flutter/material.dart';
import '../tabs/login_new_user_tab.dart';
import '../tabs/features_pricing_tab.dart';
import '../tabs/renni_reports_tab.dart';
import '../widgets/user_status_badge.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
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

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what — coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BehaviorFirst'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // ← helps on smaller screens / large text scaling
          tabs: const [
            Tab(text: 'Login / New User'),
            Tab(text: 'Features & Pricing'),
            Tab(text: 'Renni — AI Reports'),
          ],
        ),
        actions: const [UserStatusBadge(), SizedBox(width: 12)],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          LoginNewUserTab(),
          FeaturesPricingTab(),
          RenniReportsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) {
          setState(() => _bottomIndex = i);
          if (i == 0) _comingSoon('Request Data (Student Data)');
          if (i == 1) _comingSoon('Intervention Recommendations (Renni)');
          if (i == 2) _comingSoon('Contact Us');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dataset), label: 'Request Data'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Intervention Recs'),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: 'Contact Us'),
        ],
      ),
    );
  }
}
