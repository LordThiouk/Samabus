import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/localization.dart';
import 'search_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';

class TravelerHomeScreen extends StatefulWidget {
  const TravelerHomeScreen({Key? key}) : super(key: key);

  @override
  State<TravelerHomeScreen> createState() => _TravelerHomeScreenState();
}

class _TravelerHomeScreenState extends State<TravelerHomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const SearchScreen(),
    const BookingsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserBookings();
  }

  Future<void> _loadUserBookings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      await bookingProvider.getUserBookings(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: localizations.get('search'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.confirmation_number),
            label: localizations.get('my_bookings'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person),
            label: localizations.get('profile'),
          ),
        ],
      ),
    );
  }
}
