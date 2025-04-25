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
  bool _signupAttempted = false; // To show success/error message
  bool _signupSuccess = false; // To show success message specifically

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
       setState(() => _signupAttempted = false); // Reset if form invalid immediately
      return;
    }

    final authProvider = context.read<AuthProvider>();
    // Prepare optional data based on input
    final String? phone = _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null;
    final String? fullName = _fullNameController.text.trim().isNotEmpty ? _fullNameController.text.trim() : null;
    final String? companyName = _selectedRole == app_user.UserRole.transporteur && _companyNameController.text.trim().isNotEmpty
          ? _companyNameController.text.trim()
          : null;

    final success = await authProvider.signUp(
        email: _emailController.text.trim(), // Primary identifier
        password: _passwordController.text,
        role: _selectedRole,
        // Pass other details as optional parameters
        phone: phone,
        fullName: fullName,
        companyName: companyName,
      );

      if (mounted) {
        // Update success state *after* the async call completes
        setState(() {
         _signupSuccess = success;
         // We keep _signupAttempted = true regardless of success/failure here
       });
      }
     // Error/Success message display is handled in the build method based on state
     // Navigation on success is handled by router listening to AuthProvider state changes
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    // isLoading should ideally reflect AuthProvider status directly
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
                    // Use Key for testing if needed
                    // key: const Key('signup_role_selector'),
                    segments: const <ButtonSegment<app_user.UserRole>>[
                      ButtonSegment<app_user.UserRole>(
                        value: app_user.UserRole.traveler,
                        label: const Text('Traveler'),
                        icon: const Icon(Icons.person_outline),
                      ),
                      ButtonSegment<app_user.UserRole>(
                        value: app_user.UserRole.transporteur, // Updated value
                        label: const Text('Transporteur'), // Updated label
                        icon: const Icon(Icons.directions_bus),
                      ),
                    ],
                    selected: <app_user.UserRole>{_selectedRole},
                    onSelectionChanged: (Set<app_user.UserRole> newSelection) {
                      setState(() {
                        _selectedRole = newSelection.first;
                        // Clear company name if switching away from transporteur? Optional.
                        if (_selectedRole != app_user.UserRole.transporteur) {
                          _companyNameController.clear();
                        }
                      });
                    },
                    // Style for better visual feedback
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                        return states.contains(MaterialState.selected) ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : null;
                      }),
                      side: MaterialStateProperty.resolveWith<BorderSide?>((Set<MaterialState> states) {
                        return BorderSide(color: states.contains(MaterialState.selected) ? Theme.of(context).colorScheme.primary : Colors.grey);
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // --- Input Fields ---
                  CustomTextField(
                    key: const Key('signup_fullname'),
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
                  if (_selectedRole == app_user.UserRole.transporteur) ...[
                     CustomTextField(
                      key: const Key('signup_company_name'),
                      controller: _companyNameController,
                      labelText: 'Company Name',
                      prefixIcon: Icons.business_center_outlined,
                      validator: (value) {
                         // Only validate if transporteur is selected
                         if (_selectedRole == app_user.UserRole.transporteur && (value == null || value.trim().isEmpty)) { // Updated check
                           return 'Please enter your company name';
                      }
                         return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustomTextField(
                    key: const Key('signup_email'),
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
                    key: const Key('signup_phone'),
                    controller: _phoneController,
                    labelText: 'Phone Number',
                     prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      // Basic validation - consider more robust checks
                      if (value == null || value.trim().isEmpty || !RegExp(r'^\+?[0-9]{7,}$').hasMatch(value.trim())) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    key: const Key('signup_password'),
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
                    key: const Key('signup_confirm_password'),
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

                  // --- Feedback Area (Original Version) ---
                  if (_signupAttempted && !isLoading && authProvider.status == AuthStatus.error && authProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        authProvider.errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_signupAttempted && _signupSuccess)
                     Padding(
                       padding: const EdgeInsets.only(bottom: 16.0),
                       child: Text(
                         'Signup successful! Check email/SMS for verification if required.',
                         style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                         textAlign: TextAlign.center,
                       ),
                     ),

                  // Sign Up Button
                  ElevatedButton(
                    key: const Key('signup_button'),
                    onPressed: isLoading ? null : _submitSignup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0), // Adjust radius as needed
                      ),
                    ),
                    child: const Text('Sign Up', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  // Link to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        // Use Key for testing if needed
                        // key: const Key('signup_login_link'),
                        onPressed: isLoading ? null : () {
                          if (context.canPop()) {
                             context.pop();
                           } else {
                             context.go(LoginScreen.routeName);
                           }
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],   // Closes Column children
              ),     // Closes Column
            ),       // Closes Form
          ),         // Closes SingleChildScrollView
        ),           // Closes SafeArea
      ),             // Closes LoadingOverlay
    );               // Closes Scaffold
  }
}
