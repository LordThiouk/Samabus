import 'package:flutter/material.dart';

// No need for provider or other screen imports here, router handles navigation

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  // Define route name if needed for direct navigation (though typically router starts here)
  static const String routeName = '/';

  @override
  Widget build(BuildContext context) {
    // The GoRouter's redirect logic (listening to AuthProvider) will handle
    // navigating away from this screen once authentication state is determined.
    // We just need to show a loading indicator or branding.
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_rounded,
              size: 100,
              // Consider using Theme.of(context).colorScheme.primary
              color: Color(0xFF0057E7), // Use primary color directly
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'SamaBus',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
