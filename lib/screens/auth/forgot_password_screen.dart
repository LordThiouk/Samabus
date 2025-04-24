import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'; // Import go_router
import '../../providers/auth_provider.dart';
import '../../providers/auth_status.dart';
import '../../widgets/custom_text_field.dart'; // Assuming a reusable text field
import '../../widgets/loading_overlay.dart'; // Assuming a loading overlay widget

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const String routeName = '/forgot-password'; // For navigation

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _resetEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendPasswordResetEmail(
      email: _emailController.text.trim(),
    );

    if (success && mounted) {
      setState(() {
        _resetEmailSent = true;
      });
    } 
    // Error message will be displayed via the watched authProvider.errorMessage
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.status == AuthStatus.authenticating; // Consider a specific state?

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reset Your Password',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
      ),
                  const SizedBox(height: 16.0),
                  if (!_resetEmailSent)
                    const Text(
                      'Enter your email address below and we\'ll send you a link to reset your password.',
                      textAlign: TextAlign.center,
                    ),
                  if (_resetEmailSent)
                    Text(
                      'Password reset link sent successfully to ${_emailController.text}. Check your email (including spam folder).',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.green),
                    ),
                  const SizedBox(height: 24.0),
                  if (!_resetEmailSent) ...[
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        // Basic email validation
                        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                           return 'Please enter a valid email address';
                        }
                        return null;
                      },
                      prefixIcon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 24.0),
                     // Display error message if any
                     if (authProvider.status == AuthStatus.error && authProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          authProvider.errorMessage!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text('Send Reset Link'),
                    ),
                    const SizedBox(height: 16.0),
                    TextButton(
                      onPressed: isLoading ? null : () => context.pop(),
                      child: const Text('Back to Login'),
                    ),
                  ] else ...[
                     const SizedBox(height: 16.0),
                     TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Back to Login'),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 