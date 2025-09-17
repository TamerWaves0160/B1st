import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/hero_banner.dart';
import '../utils/form_validators.dart';

class LoginNewUserTab extends StatefulWidget {
  const LoginNewUserTab({super.key});

  @override
  State<LoginNewUserTab> createState() => _LoginNewUserTabState();
}

class _LoginNewUserTabState extends State<LoginNewUserTab> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isLogin = true;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'There is already an account with that email.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'That password is too weak. Try something stronger.';
      case 'user-not-found':
        return 'No user found with that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context); // capture BEFORE await
    setState(() => _busy = true);

    try {
      final email = _email.text.trim();
      final pass = _password.text;

      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
        messenger.showSnackBar(const SnackBar(content: Text('Signed in.')));
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Account created.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_friendlyAuthError(e))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    final messenger = ScaffoldMessenger.of(context); // capture BEFORE await

    if (email.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter your email first.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      messenger.showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_friendlyAuthError(e))));
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
              const HeroBanner(),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // VISIBLE MODE TOGGLE - Very prominent for testing
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      setState(() => _isLogin = true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isLogin
                                        ? Colors.blue
                                        : Colors.white,
                                    foregroundColor: _isLogin
                                        ? Colors.white
                                        : Colors.blue,
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
                                  onPressed: () =>
                                      setState(() => _isLogin = false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: !_isLogin
                                        ? Colors.blue
                                        : Colors.white,
                                    foregroundColor: !_isLogin
                                        ? Colors.white
                                        : Colors.blue,
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _email,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          autofillHints: const [AutofillHints.password],
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: Validators.password,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _busy ? null : _resetPassword,
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: _busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(_isLogin ? 'Sign In' : 'Create Account'),
                          ),
                        ),
                      ],
                    ),
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
