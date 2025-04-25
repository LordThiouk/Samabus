import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const String routeName = '/admin';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.signOut();
              // Router redirect logic will handle navigation
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      // TODO: Add Navigation Panel for admin sections
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome, Admin!'),
             const SizedBox(height: 10),
            Text('User ID: ${authProvider.user?.id}'),
             Text('Role: ${authProvider.user?.role.toString().split('.').last}'),
            // TODO: Add Admin specific UI (User Mgmt, Transporter Mgmt, Bookings, Finance, etc.)
          ],
        ),
      ),
    );
  }
} 