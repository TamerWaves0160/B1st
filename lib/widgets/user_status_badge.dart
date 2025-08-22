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
              // capture messenger BEFORE any await
              final messenger = ScaffoldMessenger.of(context);

              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text('Do you want to sign out of your account?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
                messenger.showSnackBar(const SnackBar(content: Text('Signed out.')));
              }
            },
          ),
        );
      },
    );
  }
}