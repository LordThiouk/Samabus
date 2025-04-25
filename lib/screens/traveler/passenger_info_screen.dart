import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/passenger.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/localization.dart';
import 'payment_screen.dart';

class PassengerInfoScreen extends StatefulWidget {
  const PassengerInfoScreen({super.key});

  @override
  State<PassengerInfoScreen> createState() => _PassengerInfoScreenState();
}

class _PassengerInfoScreenState extends State<PassengerInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<PassengerForm> _passengers = [];
  int _passengerCount = 1;

  @override
  void initState() {
    super.initState();
    _passengers.add(PassengerForm(index: 0));
  }

  void _addPassenger() {
    if (_passengerCount < 5) {
      setState(() {
        _passengers.add(PassengerForm(index: _passengerCount));
        _passengerCount++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 passengers allowed per booking'),
        ),
      );
    }
  }

  void _removePassenger(int index) {
    if (_passengerCount > 1) {
      setState(() {
        _passengers.removeAt(index);
        _passengerCount--;
        
        // Update indices
        for (int i = 0; i < _passengers.length; i++) {
          _passengers[i].index = i;
        }
      });
    }
  }

  Future<void> _proceedToPayment() async {
    if (_formKey.currentState!.validate()) {
      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      if (tripProvider.selectedTrip == null || authProvider.user == null) {
        return;
      }
      
      final trip = tripProvider.selectedTrip!;
      
      List<Passenger> passengers = List.generate(_passengerCount, (index) {
        return Passenger(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}-$index',
          bookingId: 'temp-booking',
          fullName: _passengers[index].nameController.text.trim(),
          cni: _passengers[index].cniController.text.trim(),
        );
      }).toList();
      
      final String? userId = authProvider.user?.id;
      if (userId == null) {
        _showErrorDialog(context, 'User ID not found. Please log in again.');
        return;
      }
      
      final success = await bookingProvider.createBooking(
        userId: userId,
        tripId: trip.id!,
        passengers: passengers,
        farePerSeat: trip.pricePerSeat,
      );
      
      if (!mounted) return;
      
      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PaymentScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingProvider.errorMessage ?? 'Failed to create booking'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final tripProvider = Provider.of<TripProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    
    if (tripProvider.selectedTrip == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.get('passenger_info')),
        ),
        body: const Center(
          child: Text('No trip selected'),
        ),
      );
    }
    
    final trip = tripProvider.selectedTrip!;
    final currencyFormat = NumberFormat.currency(
      symbol: 'FCFA ',
      decimalDigits: 0,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.get('passenger_info')),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Trip summary
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.departureCity} → ${trip.destinationCity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEE, MMM d, yyyy HH:mm').format(trip.departureTimestamp),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormat.format(trip.pricePerSeat),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Passenger forms
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    localizations.get('passenger_info'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Passenger forms
                  ...List.generate(_passengers.length, (index) {
                    return _buildPassengerForm(
                      context,
                      _passengers[index],
                      index,
                      localizations,
                    );
                  }),
                  
                  // Add passenger button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: OutlinedButton.icon(
                      onPressed: _addPassenger,
                      icon: const Icon(Icons.person_add),
                      label: Text(localizations.get('add_passenger')),
                    ),
                  ),
                  
                  // Total price
                  Card(
                    margin: const EdgeInsets.only(top: 16, bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.get('price_summary'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${localizations.get('fare')} x $_passengerCount'),
                              Text(currencyFormat.format(trip.pricePerSeat * _passengerCount)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                localizations.get('total'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                currencyFormat.format(trip.pricePerSeat * _passengerCount),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: bookingProvider.isLoading ? null : _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: bookingProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          localizations.get('proceed_to_payment'),
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerForm(
    BuildContext context,
    PassengerForm passenger,
    int index,
    AppLocalizations localizations,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${localizations.get('passenger')} ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (index > 0)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => _removePassenger(index),
                    tooltip: localizations.get('remove_passenger'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Full name
            TextFormField(
              controller: passenger.nameController,
              decoration: InputDecoration(
                labelText: localizations.get('full_name'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter passenger name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // CNI number
            TextFormField(
              controller: passenger.cniController,
              decoration: InputDecoration(
                labelText: localizations.get('cni_number'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter ID card number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.get('error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.get('ok')),
          ),
        ],
      ),
    );
  }
}

class PassengerForm {
  int index;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cniController = TextEditingController();

  PassengerForm({required this.index});

  void dispose() {
    nameController.dispose();
    cniController.dispose();
  }
}
