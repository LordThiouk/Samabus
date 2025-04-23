import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// import '../../providers/booking_provider.dart'; // Unused
import '../../providers/trip_provider.dart';
import '../../utils/localization.dart';
import 'trip_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _departureCityController = TextEditingController();
  final _arrivalCityController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _departureCityController.dispose();
    _arrivalCityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _search() async {
    if (_formKey.currentState!.validate()) {
      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      
      await tripProvider.searchTrips(
        departureCity: _departureCityController.text.trim(),
        arrivalCity: _arrivalCityController.text.trim(),
        date: _selectedDate,
      );
      
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TripListScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final tripProvider = Provider.of<TripProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.get('search')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Find your next trip',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        
                        // Departure City
                        TextFormField(
                          controller: _departureCityController,
                          decoration: InputDecoration(
                            labelText: localizations.get('departure'),
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter departure city';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Arrival City
                        TextFormField(
                          controller: _arrivalCityController,
                          decoration: InputDecoration(
                            labelText: localizations.get('arrival'),
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter arrival city';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Date Picker
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: localizations.get('date'),
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Search Button
                        ElevatedButton(
                          onPressed: tripProvider.isLoading ? null : _search,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: tripProvider.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  localizations.get('search'),
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Popular destinations
                Text(
                  'Popular Destinations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildDestinationCard(
                      context,
                      'Dakar',
                      'assets/images/dakar.jpg',
                      () {
                        _arrivalCityController.text = 'Dakar';
                      },
                    ),
                    _buildDestinationCard(
                      context,
                      'Saint-Louis',
                      'assets/images/saint_louis.jpg',
                      () {
                        _arrivalCityController.text = 'Saint-Louis';
                      },
                    ),
                    _buildDestinationCard(
                      context,
                      'Thiès',
                      'assets/images/thies.jpg',
                      () {
                        _arrivalCityController.text = 'Thiès';
                      },
                    ),
                    _buildDestinationCard(
                      context,
                      'Ziguinchor',
                      'assets/images/ziguinchor.jpg',
                      () {
                        _arrivalCityController.text = 'Ziguinchor';
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationCard(
    BuildContext context,
    String cityName,
    String imagePath,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Text(
                cityName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
