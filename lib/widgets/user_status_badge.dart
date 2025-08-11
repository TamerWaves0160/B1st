import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserStatusBadge extends StatelessWidget {
  const UserStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ActionChip(
            avatar: const Icon(Icons.account_circle_outlined),
            label: Text(user.email ?? 'Signed in'),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text('Do you want to sign out of your account?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out.')),
                );
              }
            },
          ),
        );
      },
    );
  }
}