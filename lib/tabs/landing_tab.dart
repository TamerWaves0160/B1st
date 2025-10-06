import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LandingTab extends StatefulWidget {
  const LandingTab({super.key});

  @override
  State<LandingTab> createState() => _LandingTabState();
}

class _LandingTabState extends State<LandingTab> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showLogin = false;
  bool _isLogin = true; // true for login, false for create account
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);

    try {
      final email = _email.text.trim();
      final password = _password.text;

      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Signed in successfully!')),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = _isLogin ? 'Login failed' : 'Account creation failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with that email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with that email';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome to BehaviorFirst',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'The First Cross-Platform Application Encompassing ALL Your Data Collection and Interpretation Needs.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your comprehensive solution for behavior data collection and analysis.',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (!_showLogin) ...[
                        ElevatedButton(
                          onPressed: () => setState(() => _showLogin = true),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Text('Sign In to Get Started'),
                          ),
                        ),
                      ] else ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _email,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Email required';
                                  if (!value.contains('@'))
                                    return 'Invalid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                obscureText: _obscure,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Password required';
                                  if (!_isLogin && value.length < 6)
                                    return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              // TOGGLE BUTTONS - Moved to bottom location
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF2E7D32),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _busy
                                            ? null
                                            : () async {
                                                setState(() => _isLogin = true);
                                                if (_email.text
                                                        .trim()
                                                        .isNotEmpty &&
                                                    _password.text.isNotEmpty) {
                                                  await _submit();
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _isLogin
                                              ? const Color(0xFF2E7D32)
                                              : Colors.white,
                                          foregroundColor: _isLogin
                                              ? Colors.white
                                              : const Color(0xFF2E7D32),
                                          elevation: _isLogin ? 4 : 0,
                                        ),
                                        child: const Text(
                                          'SIGN IN',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _busy
                                            ? null
                                            : () async {
                                                setState(
                                                  () => _isLogin = false,
                                                );
                                                if (_email.text
                                                        .trim()
                                                        .isNotEmpty &&
                                                    _password.text.isNotEmpty) {
                                                  await _submit();
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: !_isLogin
                                              ? const Color(0xFF2E7D32)
                                              : Colors.white,
                                          foregroundColor: !_isLogin
                                              ? Colors.white
                                              : const Color(0xFF2E7D32),
                                          elevation: !_isLogin ? 4 : 0,
                                        ),
                                        child: const Text(
                                          'CREATE ACCOUNT',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_busy) ...[
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextButton(
                                onPressed: () =>
                                    setState(() => _showLogin = false),
                                child: const Text('Back to Home'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
