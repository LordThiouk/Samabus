import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart' as app_user; // Alias needed, UserRole is here
import '../../providers/auth_provider.dart';
// import '../../utils/localization.dart'; // Remove unused import
// import '../../widgets/custom_button.dart'; // File doesn't exist yet
// import '../../widgets/custom_text_field.dart'; // File doesn't exist yet
// import '../verify_phone_screen.dart'; // File doesn't exist yet

// REMOVE the local enum definition, it conflicts with models/user.dart
// enum UserRole { traveler, transporteur }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  // Use the imported UserRole
  app_user.UserRole _selectedRole = app_user.UserRole.traveler;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  // Correct the method signature and structure
  Future<void> _signUp() async { // Mark as async
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Define provider outside the try block
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final localizations = AppLocalizations.of(context); // TODO: Enable localization

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String formattedPhoneNumber = _phoneController.text.trim();
      // TODO: Add phone number formatting if needed (e.g., adding country code)

      // Await the async call
      await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: formattedPhoneNumber,
        role: _selectedRole, // Pass the correct enum type
        fullName: _fullNameController.text.trim(),
      );

      if (mounted) {
        // TODO: Handle navigation to VerifyPhoneScreen if necessary
        // For MVP, assume success and inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup Successful! Check your email/SMS.')) // Placeholder
          // SnackBar(content: Text(localizations?.get('signup_successful_check_email') ?? 'Signup Successful! Check your email/SMS.')),
        );
        // Optionally pop back to login or navigate to home
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString(); // Store error message
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: ${e.toString()}')) // Placeholder
          // SnackBar(content: Text('${localizations?.get('signup_failed')}: ${e.toString()}')),
        );
      }
    } finally {
      // Ensure isLoading is set to false even if errors occur
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // final localizations = AppLocalizations.of(context); // TODO: Enable localization

    return Scaffold(
      appBar: AppBar(
        // title: Text(localizations?.get('sign_up') ?? 'Sign Up'),
        title: const Text('Sign Up'), // Placeholder
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  // localizations?.get('create_account_title') ?? 'Create your account',
                  'Create your account', // Placeholder
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name', // Placeholder
                    // labelText: localizations?.get('full_name_label') ?? 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      // return localizations?.get('full_name_required') ?? 'Please enter your full name';
                      return 'Please enter your full name'; // Placeholder
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email', // Placeholder
                    // labelText: localizations?.get('email_label') ?? 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      // return localizations?.get('email_invalid') ?? 'Please enter a valid email';
                      return 'Please enter a valid email'; // Placeholder
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password', // Placeholder
                    // labelText: localizations?.get('password_label') ?? 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      // return localizations?.get('password_short') ?? 'Password must be at least 6 characters';
                       return 'Password must be at least 6 characters'; // Placeholder
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (e.g., 771234567)', // Placeholder with example
                    // labelText: localizations?.get('phone_label') ?? 'Phone Number',
                    // hintText: localizations?.get('phone_hint') ?? 'e.g., 771234567',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 9) { // Basic length check
                      // return localizations?.get('phone_invalid') ?? 'Please enter a valid phone number';
                      return 'Please enter a valid phone number'; // Placeholder
                    }
                    // TODO: Add more specific phone number regex validation if needed
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Use the correct UserRole from models
                Text('Select Role', style: Theme.of(context).textTheme.titleMedium), // Placeholder
                // Text(localizations?.get('select_role') ?? 'Select Role', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<app_user.UserRole>(
                  segments: const <ButtonSegment<app_user.UserRole>>[
                    ButtonSegment<app_user.UserRole>(
                      value: app_user.UserRole.traveler,
                      // label: Text(localizations?.get('traveler') ?? 'Traveler'),
                      label: Text('Traveler'), // Placeholder
                      icon: const Icon(Icons.person_outline),
                    ),
                    ButtonSegment<app_user.UserRole>(
                      value: app_user.UserRole.transporteur,
                      // label: Text(localizations?.get('transporteur') ?? 'Transporteur'),
                      label: Text('Transporteur'), // Placeholder
                      icon: const Icon(Icons.directions_bus),
                    ),
                  ],
                  selected: <app_user.UserRole>{_selectedRole},
                  onSelectionChanged: (Set<app_user.UserRole> newSelection) {
                    setState(() {
                      _selectedRole = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return Theme.of(context).colorScheme.onPrimary;
                      }
                      return null; // Use default foreground color for unselected
                    }),
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return Theme.of(context).colorScheme.primary;
                      }
                      return null; // Use default background color for unselected
                    }),
                    // Add other styling properties if needed, e.g.:
                    // side: MaterialStateProperty.all(BorderSide(color: Theme.of(context).colorScheme.primary)),
                    // shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    // minimumSize: MaterialStateProperty.all(Size.fromHeight(40)),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                           minimumSize: const Size.fromHeight(50), // Make button taller
                        ),
                        // child: Text(localizations?.get('sign_up') ?? 'Sign Up'),
                        child: const Text('Sign Up'), // Placeholder
                      ),
                TextButton(
                  onPressed: () => Navigator.pop(context), // Go back to login
                  // child: Text(localizations?.get('already_have_account') ?? 'Already have an account? Log In'),
                  child: const Text('Already have an account? Log In'), // Placeholder
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
