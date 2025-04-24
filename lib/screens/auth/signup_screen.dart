import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart' as app_user; // Alias needed, UserRole is here
import '../../providers/auth_provider.dart';
import '../../providers/auth_status.dart'; // Import status
import '../../widgets/custom_text_field.dart'; // Use reusable widget
import '../../widgets/loading_overlay.dart'; // Use overlay
import 'login_screen.dart'; // For back navigation
import 'package:go_router/go_router.dart';

// Local enum removed - Use app_user.UserRole from models/user.dart

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  static const String routeName = '/signup';

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // For confirmation
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _companyNameController = TextEditingController(); // Added

  app_user.UserRole _selectedRole = app_user.UserRole.traveler; // Default to traveler
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _signupAttempted = false; // To show success message
  bool _signupSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    _companyNameController.dispose(); // Added
    super.dispose();
  }

  Future<void> _submitSignup() async {
    setState(() {
      _signupAttempted = true; // Mark attempt
      _signupSuccess = false; // Reset success status
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      role: _selectedRole,
      phone: _phoneController.text.trim(),
        fullName: _fullNameController.text.trim(),
      // Only pass companyName if role is transporteur
      companyName: _selectedRole == app_user.UserRole.transporteur
          ? _companyNameController.text.trim()
          : null,
      );

      if (mounted) {
      setState(() {
         _signupSuccess = success;
         if (success) {
           // Clear form on success?
           // _formKey.currentState?.reset(); 
         }
       });
      }
     // Error message will be displayed via the watched authProvider.errorMessage
     // Success message is handled by _signupSuccess state
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.status == AuthStatus.authenticating;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
         leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Navigate back to Login using go_router
          onPressed: () {
            // Check if we can pop, otherwise go to login
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(LoginScreen.routeName);
            }
            // Navigator.of(context).canPop()
            //                 ? Navigator.of(context).pop()
            //                 : Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
          },
        ),
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    'Create your account',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                  // Role Selection
                  Text('I am a:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<app_user.UserRole>(
                  segments: const <ButtonSegment<app_user.UserRole>>[
                    ButtonSegment<app_user.UserRole>(
                      value: app_user.UserRole.traveler,
                        label: Text('Traveler'),
                        icon: Icon(Icons.person_outline),
                    ),
                    ButtonSegment<app_user.UserRole>(
                        value: app_user.UserRole.transporteur, // Updated value
                        label: Text('Transporteur'), // Updated label
                        icon: Icon(Icons.directions_bus),
                    ),
                  ],
                  selected: <app_user.UserRole>{_selectedRole},
                  onSelectionChanged: (Set<app_user.UserRole> newSelection) {
                    setState(() {
                      _selectedRole = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                      // Simple styling for selected state
                      backgroundColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                        return states.contains(MaterialState.selected) ? Theme.of(context).colorScheme.primary : null;
                      }),
                    foregroundColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                         return states.contains(MaterialState.selected) ? Theme.of(context).colorScheme.onPrimary : null;
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // --- Input Fields ---
                  CustomTextField(
                    controller: _fullNameController,
                    labelText: 'Full Name',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Conditionally show Company Name
                  if (_selectedRole == app_user.UserRole.transporteur) ...[ // Updated check
                     CustomTextField(
                      controller: _companyNameController,
                      labelText: 'Company Name',
                      prefixIcon: Icons.business_center_outlined,
                      validator: (value) {
                         if (_selectedRole == app_user.UserRole.transporteur && (value == null || value.trim().isEmpty)) { // Updated check
                           return 'Please enter your company name';
                      }
                         return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || !RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    labelText: 'Phone Number',
                     prefixIcon: Icons.phone_outlined,
                    // hintText: 'e.g., 771234567',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty || value.length < 9) { // Basic check
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: !_isPasswordVisible,
                     suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                         return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                   const SizedBox(height: 16),
                   CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: !_isConfirmPasswordVisible,
                     suffixIcon: IconButton(
                        icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)),
                    validator: (value) {
                       if (value == null || value.isEmpty) {
                         return 'Please confirm your password';
                       }
                       if (value != _passwordController.text) {
                         return 'Passwords do not match';
                       }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // --- Feedback Area ---
                  if (_signupAttempted && _signupSuccess)
                     const Padding(
                       padding: EdgeInsets.only(bottom: 16.0),
                       child: Text(
                         'Signup successful! Check email/SMS for verification.',
                         style: TextStyle(color: Colors.green),
                         textAlign: TextAlign.center,
                  ),
                ),
                  if (authProvider.status == AuthStatus.error && authProvider.errorMessage != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                        authProvider.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // --- Submit Button ---
                  ElevatedButton(
                    onPressed: isLoading ? null : _submitSignup,
                        style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    child: const Text('Sign Up'),
                  ),
                  const SizedBox(height: 16),
                  // --- Back to Login ---
                   Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                TextButton(
                        onPressed: isLoading ? null : () {
                          // Use go_router to navigate
                           if (context.canPop()) {
                             context.pop();
                           } else {
                             context.go(LoginScreen.routeName);
                           }
                          // if (Navigator.canPop(context)) {
                          //   Navigator.pop(context);
                          // } else {
                          //   Navigator.pushReplacementNamed(context, LoginScreen.routeName);
                          // }
                        },
                        child: const Text('Login'),
                ),
              ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
