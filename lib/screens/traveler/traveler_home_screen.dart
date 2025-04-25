import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class TravelerHomeScreen extends StatelessWidget {
  const TravelerHomeScreen({super.key});

  static const String routeName = '/traveler';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traveler Home'),
        actions: [
          IconButton(
            key: const Key('logout_button'),
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.signOut();
              // Router redirect logic will handle navigation
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Text('Welcome, Traveler!'),
             const SizedBox(height: 10),
             Text('User ID: ${authProvider.user?.id}'),
             Text('Role: ${authProvider.user?.role.toString().split('.').last}'),
             // TODO: Add Traveler specific UI (Search bar, recent bookings, etc.)
          ],
        ),
      ),
    );
  }
}
