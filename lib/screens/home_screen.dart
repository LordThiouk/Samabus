import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home'; // Define route name

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    // TODO: Build different dashboards based on authProvider.user?.role
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home - Placeholder'),
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
      body: Center(
        child: Text('Welcome!\nUser ID: ${authProvider.user?.id}\nRole: ${authProvider.user?.role}\n(This is a placeholder)'),
      ),
    );
  }
} 