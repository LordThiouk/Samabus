import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart' as app_user;

class TransporteurHomeScreen extends StatelessWidget {
  const TransporteurHomeScreen({super.key});

  static const String routeName = '/transporteur';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>(); // Use watch if UI needs to rebuild on user changes
    final user = authProvider.user;
    final bool isApproved = user?.isApproved ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(isApproved ? 'Transporteur Dashboard' : 'Account Pending'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      // TODO: Add Drawer or Sidebar for transporteur navigation (only if approved?)
      body: isApproved
          ? _buildDashboard(context, user) // Show dashboard if approved
          : _buildPendingApproval(context), // Show pending message if not approved
    );
  }

  // Widget for the main dashboard content when approved
  Widget _buildDashboard(BuildContext context, app_user.User? user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Welcome, Transporteur!'),
          SizedBox(height: 10),
          Text('User ID: ${user?.id}'),
          Text('Company: ${user?.companyName ?? "N/A"}'),
          Text('Role: ${user?.role.toString().split('.').last}'),
          Text('Approved: ${user?.isApproved ?? false}'),
          // TODO: Add Transporteur specific UI (Fleet, Trips, Reservations, Scanner links)
        ],
      ),
    );
  }

  // Widget to show when account is pending approval
  Widget _buildPendingApproval(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 60, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Account Pending Approval',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Your account is currently under review by an administrator. You will be notified once it is approved. You can log out using the button in the top right.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 